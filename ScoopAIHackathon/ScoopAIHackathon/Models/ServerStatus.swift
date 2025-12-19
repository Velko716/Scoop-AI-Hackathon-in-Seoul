//
//  ServerStatus.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

struct ServerStatus: Codable {
    let status: String
    let message: String
    let version: String
}
