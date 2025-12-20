//
//  Priority.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

enum Priority: String, Codable, CaseIterable, Sendable {
    case high
    case medium
    case low

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    var label: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var localizedLabel: String {
        switch self {
        case .high: return "높음"
        case .medium: return "보통"
        case .low: return "낮음"
        }
    }
}
