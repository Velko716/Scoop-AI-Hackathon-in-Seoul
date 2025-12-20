//
//  EventPlanResponse.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - Main Response (백엔드 /plan-event 응답)
struct EventPlanResponse: Codable {
    let success: Bool
    let eventName: String?
    let schedules: [ScheduleItem]?
    let todos: [TodoResponseItem]?  // 체크리스트 추가
    let rawResponse: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case eventName = "event_name"
        case schedules
        case todos
        case rawResponse = "raw_response"
        case error
    }
}

// MARK: - Schedule Item (일정 항목)
struct ScheduleItem: Codable, Identifiable {
    var id: String { "\(title)-\(startDate)" }
    let title: String
    let startDate: String
    let endDate: String
    let color: String
}

// MARK: - Todo Response Item (체크리스트 항목)
struct TodoResponseItem: Codable, Identifiable {
    var id: String { "\(title)-\(scheduleId)" }
    let title: String
    let scheduleId: String   // 연관된 스케줄 ID
    let priority: Int        // 우선순위 (1: 높음, 2: 중간, 3: 낮음)
    let category: String     // 카테고리
}
