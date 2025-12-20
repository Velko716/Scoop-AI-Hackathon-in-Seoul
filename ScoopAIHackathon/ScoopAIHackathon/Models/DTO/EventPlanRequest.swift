//
//  EventPlanRequest.swift
//  ScoopAIHackathon
//
//  행사 기획 요청 DTO
//

import Foundation

struct EventInfoItem: Codable {
    let label: String
    let value: String
}

struct EventPlanRequest: Codable {
    let eventInfo: [EventInfoItem]

    enum CodingKeys: String, CodingKey {
        case eventInfo = "event_info"
    }
}
