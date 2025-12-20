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

    // MARK: - Input Properties (필수)

    var eventName: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date().addingTimeInterval(86400) // 기본값: 내일
    var targetAudience: String = ""
    var eventLocation: String = ""
    var staffCount: String = ""
    var participantCount: String = ""
    var eventOverview: String = ""
    var eventContent: String = ""

    // MARK: - Input Properties (선택)

    var budget: String = ""
    var requiredEquipment: String = ""

    // MARK: - State Properties

    var isLoading: Bool = false
    var errorMessage: String?
    var eventPlanResponse: EventPlanResponse?
    var showResult: Bool = false

    // MARK: - Dependencies

    private let service: SpoonAgentService

    // MARK: - Initialization

    init(service: SpoonAgentService = .shared) {
        self.service = service
    }

    // MARK: - Computed Properties

    /// 입력값 유효성 검사
    var isValidInput: Bool {
        !eventName.isEmpty &&
        !targetAudience.isEmpty &&
        !eventLocation.isEmpty &&
        !staffCount.isEmpty &&
        !participantCount.isEmpty &&
        !eventOverview.isEmpty &&
        !eventContent.isEmpty &&
        Int(staffCount) != nil &&
        Int(participantCount) != nil &&
        startDate <= endDate
    }

    /// 유효성 검사 실패 메시지
    var validationMessage: String? {
        if eventName.isEmpty { return "행사명을 입력해주세요" }
        if targetAudience.isEmpty { return "행사대상을 입력해주세요" }
        if eventLocation.isEmpty { return "행사장소를 입력해주세요" }
        if staffCount.isEmpty { return "스태프 인원을 입력해주세요" }
        if Int(staffCount) == nil { return "스태프 인원은 숫자로 입력해주세요" }
        if participantCount.isEmpty { return "참가 인원을 입력해주세요" }
        if Int(participantCount) == nil { return "참가 인원은 숫자로 입력해주세요" }
        if eventOverview.isEmpty { return "행사개요를 입력해주세요" }
        if eventContent.isEmpty { return "행사내용을 입력해주세요" }
        if startDate > endDate { return "종료일은 시작일 이후여야 합니다" }
        return nil
    }

    // MARK: - Public Methods

    /// 행사 계획 생성 요청
    func generateEventPlan() async {
        guard isValidInput else {
            errorMessage = validationMessage
            return
        }

        isLoading = true
        errorMessage = nil

        let request = createRequest()

        let result = await service.generateEventPlan(request: request)

        isLoading = false

        switch result {
        case .success(let response):
            eventPlanResponse = response
            showResult = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    /// 입력 폼 초기화
    func resetForm() {
        eventName = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(86400)
        targetAudience = ""
        eventLocation = ""
        staffCount = ""
        participantCount = ""
        budget = ""
        requiredEquipment = ""
        eventOverview = ""
        eventContent = ""
        errorMessage = nil
        eventPlanResponse = nil
        showResult = false
    }

    // MARK: - Private Methods

    private func createRequest() -> EventPlanRequest {
        EventPlanRequest(
            eventName: eventName,
            startDate: startDate,
            endDate: endDate,
            targetAudience: targetAudience,
            eventLocation: eventLocation,
            staffCount: Int(staffCount) ?? 0,
            participantCount: Int(participantCount) ?? 0,
            budget: Int(budget),
            requiredEquipment: requiredEquipment.isEmpty ? nil : requiredEquipment,
            eventOverview: eventOverview,
            eventContent: eventContent
        )
    }
}
