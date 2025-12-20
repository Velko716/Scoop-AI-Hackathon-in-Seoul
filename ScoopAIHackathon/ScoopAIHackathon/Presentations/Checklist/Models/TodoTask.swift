//
//  TodoTask.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - Priority Enum
enum Priority: Int, CaseIterable, Sendable {
    case high = 0
    case medium = 1
    case low = 2

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

// MARK: - TodoTask Model
struct TodoTask: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        priority: Priority = .medium
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
    }
}

// MARK: - Mock Data
extension TodoTask {
    static let mockTasks: [TodoTask] = [
        TodoTask(title: "프로젝트 기획서 작성", isCompleted: false, priority: .high),
        TodoTask(title: "UI 디자인 검토", isCompleted: false, priority: .high),
        TodoTask(title: "API 연동 테스트", isCompleted: false, priority: .medium),
        TodoTask(title: "코드 리뷰 요청", isCompleted: true, priority: .high),
        TodoTask(title: "버그 리포트 확인", isCompleted: false, priority: .medium),
        TodoTask(title: "문서 업데이트", isCompleted: false, priority: .low),
        TodoTask(title: "팀 미팅 준비", isCompleted: true, priority: .medium),
        TodoTask(title: "테스트 케이스 작성", isCompleted: false, priority: .high),
        TodoTask(title: "배포 스크립트 점검", isCompleted: false, priority: .low),
        TodoTask(title: "주간 보고서 제출", isCompleted: true, priority: .low),
        TodoTask(title: "신규 기능 브레인스토밍", isCompleted: false, priority: .medium),
        TodoTask(title: "레거시 코드 정리", isCompleted: false, priority: .low)
    ]
}
