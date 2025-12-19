//
//  ChatResponse.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

struct ChatResponse: Codable {
    let success: Bool
    let response: String
    let error: String?
}
