//
//  EventPlanResponse.swift
//  ScoopAIHackathon
//
//  행사 기획 응답 DTO
//

import Foundation

struct ScheduleItem: Codable {
    let title: String
    let startDate: String
    let endDate: String
    let color: String
}

struct EventPlanResponse: Codable {
    let success: Bool
    let eventName: String?
    let schedules: [ScheduleItem]?
    let rawResponse: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case eventName = "event_name"
        case schedules
        case rawResponse = "raw_response"
        case error
    }
}
