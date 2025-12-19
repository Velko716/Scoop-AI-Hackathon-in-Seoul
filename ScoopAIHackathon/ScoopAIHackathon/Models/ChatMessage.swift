//
//  ChatMessage.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}
