//
//  EventBasicInfo.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - 기본 행사 정보 (페이지 2)
/// 행사명, 일정, 장소, 예산 정보
struct EventBasicInfo: Codable {
    var eventName: String           // 행사명
    var startDate: Date             // 행사 시작일
    var endDate: Date               // 행사 종료일
    var eventLocation: String       // 행사 장소
    var budget: String?                // 행사 예산 (선택)

    // MARK: - Initializer
    init(
        eventName: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        eventLocation: String = "",
        budget: String? = nil
    ) {
        self.eventName = eventName
        self.startDate = startDate
        self.endDate = endDate
        self.eventLocation = eventLocation
        self.budget = budget
    }

    // MARK: - Validation
    var isValid: Bool {
        !eventName.isEmpty && !eventLocation.isEmpty && endDate >= startDate
    }

    var eventPeriodText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }
}
