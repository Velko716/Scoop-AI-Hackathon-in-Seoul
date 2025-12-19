//
//  HealthCheck.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

struct HealthCheck: Codable {
    let status: String
    let agentReady: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case agentReady = "agent_ready"
    }
}
