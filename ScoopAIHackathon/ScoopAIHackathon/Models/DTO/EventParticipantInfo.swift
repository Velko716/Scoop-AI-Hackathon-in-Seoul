//
//  EventParticipantInfo.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - 참가자 및 비품 정보 (페이지 3)
/// 행사 대상, 인원, 비품 정보
struct EventParticipantInfo: Codable {
    var targetAudience: String      // 행사 대상
    var participantCount: String       // 행사 인원

    // MARK: - Initializer
    init(
        targetAudience: String = "",
        participantCount: String = ""
    ) {
        self.targetAudience = targetAudience
        self.participantCount = participantCount
    }

    // MARK: - Validation
    var isValid: Bool {
        !targetAudience.isEmpty && !participantCount.isEmpty
    }
}
