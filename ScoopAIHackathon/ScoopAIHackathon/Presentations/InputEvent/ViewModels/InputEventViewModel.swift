//
//  InputEventViewModel.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

@MainActor
@Observable
final class InputEventViewModel {

    // MARK: - Navigation State

    enum Step: Int, CaseIterable {
        case basicInfo = 1      // Step 1: 기본 정보
        case participantInfo    // Step 2: 참가자 정보
        case eventType          // Step 3: 행사 종류
        case detailInfo         // Step 4: 행사 상세
    }

    var currentStep: Step = .basicInfo

    // MARK: - Form Data

    var formData = EventPlanFormData()

    // MARK: - Convenience Accessors for Step 1 (Basic Info)

    var eventName: String {
        get { formData.basicInfo.eventName }
        set { formData.basicInfo.eventName = newValue }
    }

    var startDate: Date {
        get { formData.basicInfo.startDate }
        set { formData.basicInfo.startDate = newValue }
    }

    var endDate: Date {
        get { formData.basicInfo.endDate }
        set { formData.basicInfo.endDate = newValue }
    }

    var eventLocation: String {
        get { formData.basicInfo.eventLocation }
        set { formData.basicInfo.eventLocation = newValue }
    }

    var budget: String {
        get { formData.basicInfo.budget ?? "" }
        set { formData.basicInfo.budget = newValue.isEmpty ? nil : newValue }
    }

    // MARK: - State Properties

    var isLoading: Bool = false
    var errorMessage: String?
    var eventPlanResponse: EventPlanResponse?
    var showResult: Bool = false

    // MARK: - Dependencies

    private let service: SpoonAgentService
    private let dataStore: EventDataStore

    // MARK: - Initialization

    init(service: SpoonAgentService = .shared, dataStore: EventDataStore = .shared) {
        self.service = service
        self.dataStore = dataStore
    }

    // MARK: - Step Validation

    var isStep1Valid: Bool {
        formData.basicInfo.isValid
    }

    var isStep2Valid: Bool {
        !formData.participantInfo.targetAudience.isEmpty &&
        !formData.participantInfo.participantCount.isEmpty
    }

    var isStep3Valid: Bool {
        true // EventType always has a default value
    }

    var isStep4Valid: Bool {
        formData.detailInfo.isValid
    }

    var isCurrentStepValid: Bool {
        switch currentStep {
        case .basicInfo: return isStep1Valid
        case .participantInfo: return isStep2Valid
        case .eventType: return isStep3Valid
        case .detailInfo: return isStep4Valid
        }
    }

    /// 현재 스텝 유효성 (기존 호환)
    var isValidInput: Bool {
        isCurrentStepValid
    }

    /// 전체 유효성 검사
    var isFullyValid: Bool {
        isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid
    }

    /// 유효성 검사 실패 메시지
    var validationMessage: String? {
        switch currentStep {
        case .basicInfo:
            if eventName.isEmpty { return "행사명을 입력해주세요" }
            if eventLocation.isEmpty { return "행사장소를 입력해주세요" }
            if startDate > endDate { return "종료일은 시작일 이후여야 합니다" }
        case .participantInfo:
            if formData.participantInfo.targetAudience.isEmpty { return "행사 대상을 입력해주세요" }
            if formData.participantInfo.participantCount.isEmpty { return "행사 인원을 입력해주세요" }
        case .eventType:
            break
        case .detailInfo:
            if formData.detailInfo.eventOverview.isEmpty { return "행사 취지를 입력해주세요" }
            if formData.detailInfo.eventContent.isEmpty { return "행사 내용을 입력해주세요" }
        }
        return nil
    }

    // MARK: - Navigation Methods

    func nextStep() {
        guard isCurrentStepValid else {
            errorMessage = validationMessage
            return
        }

        switch currentStep {
        case .basicInfo:
            currentStep = .participantInfo
        case .participantInfo:
            currentStep = .eventType
        case .eventType:
            currentStep = .detailInfo
        case .detailInfo:
            // Last step - generate plan
            Task {
                await generateEventPlan()
            }
        }
    }

    func previousStep() {
        switch currentStep {
        case .basicInfo:
            break // Can't go back from first step
        case .participantInfo:
            currentStep = .basicInfo
        case .eventType:
            currentStep = .participantInfo
        case .detailInfo:
            currentStep = .eventType
        }
    }

    // MARK: - Public Methods

    /// 행사 계획 생성 요청
    func generateEventPlan() async {
        guard isFullyValid else {
            errorMessage = "모든 필수 항목을 입력해주세요"
            return
        }

        isLoading = true
        errorMessage = nil

        let request = formData.buildRequest()

        let result = await service.generateEventPlan(request: request)

        isLoading = false

        switch result {
        case .success(let response):
            eventPlanResponse = response
            dataStore.saveResponse(response)  // 스토어에 저장하여 캘린더에서 사용
            showResult = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// 입력 폼 초기화
    func resetForm() {
        formData.reset()
        currentStep = .basicInfo
        errorMessage = nil
        eventPlanResponse = nil
        showResult = false
    }
}
