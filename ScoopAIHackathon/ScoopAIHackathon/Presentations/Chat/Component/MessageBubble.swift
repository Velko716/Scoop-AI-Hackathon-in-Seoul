//
//  MessageBubble.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import SwiftUI

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .cornerRadius(18)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
  MessageBubble(message: .init(content: "", isUser: true))
}
