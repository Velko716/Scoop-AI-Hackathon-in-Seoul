//
//  EventPlanRequest.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - Event Plan Request (최종 전송 모델)
/// 페이지별로 수집된 데이터를 조합하여 최종 API 요청에 사용
struct EventPlanRequest: Codable {
    let basicInfo: EventBasicInfo           // 페이지 2: 기본 정보
    let participantInfo: EventParticipantInfo  // 페이지 3: 참가자/비품 정보
    let eventType: EventType                // 페이지 4: 행사 종류
    let detailInfo: EventDetailInfo         // 페이지 5: 행사 취지/내용

    // MARK: - Initializer
    init(
        basicInfo: EventBasicInfo,
        participantInfo: EventParticipantInfo,
        eventType: EventType,
        detailInfo: EventDetailInfo
    ) {
        self.basicInfo = basicInfo
        self.participantInfo = participantInfo
        self.eventType = eventType
        self.detailInfo = detailInfo
    }

    // MARK: - Convenience Accessors
    var eventName: String { basicInfo.eventName }
    var startDate: Date { basicInfo.startDate }
    var endDate: Date { basicInfo.endDate }
    var eventLocation: String { basicInfo.eventLocation }
    var budget: String? { basicInfo.budget }
    var targetAudience: String { participantInfo.targetAudience }
    var participantCount: String { participantInfo.participantCount }
    var eventOverview: String { detailInfo.eventOverview }
    var eventContent: String { detailInfo.eventContent }

    // MARK: - Validation
    var isValid: Bool {
        basicInfo.isValid && participantInfo.isValid && detailInfo.isValid
    }
}

// MARK: - Event Plan Form Data (UI 상태 관리용)
/// 5페이지 폼에서 사용하는 Observable 클래스
@Observable
final class EventPlanFormData {
    // 페이지 2: 기본 정보
    var basicInfo: EventBasicInfo = EventBasicInfo()

    // 페이지 3: 참가자/비품 정보
    var participantInfo: EventParticipantInfo = EventParticipantInfo()

    // 페이지 4: 행사 종류
    var eventType: EventType = .hackathon

    // 페이지 5: 행사 취지/내용
    var detailInfo: EventDetailInfo = EventDetailInfo()

    // MARK: - Validation
    var isBasicInfoValid: Bool { basicInfo.isValid }
    var isParticipantInfoValid: Bool { participantInfo.isValid }
    var isDetailInfoValid: Bool { detailInfo.isValid }
    var isComplete: Bool { isBasicInfoValid && isParticipantInfoValid && isDetailInfoValid }

    // MARK: - Build Request
    func buildRequest() -> EventPlanRequest {
        EventPlanRequest(
            basicInfo: basicInfo,
            participantInfo: participantInfo,
            eventType: eventType,
            detailInfo: detailInfo
        )
    }

    // MARK: - Reset
    func reset() {
        basicInfo = EventBasicInfo()
        participantInfo = EventParticipantInfo()
        eventType = .hackathon
        detailInfo = EventDetailInfo()
    }
}
