//
//  EventDetailInfo.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - 행사 상세 정보 (페이지 5)
/// 행사 취지 및 내용 정보
struct EventDetailInfo: Codable {
    var eventOverview: String       // 행사 취지
    var eventContent: String        // 행사 내용

    // MARK: - Initializer
    init(
        eventOverview: String = "",
        eventContent: String = ""
    ) {
        self.eventOverview = eventOverview
        self.eventContent = eventContent
    }

    // MARK: - Validation
    var isValid: Bool {
        !eventOverview.isEmpty && !eventContent.isEmpty
    }
}
