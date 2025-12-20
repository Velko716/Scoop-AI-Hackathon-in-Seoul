//
//  TodoTask.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - TodoTask Model
struct TodoTask: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var eventId: UUID?
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        eventId: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.eventId = eventId
        self.sortOrder = sortOrder
    }
}

// MARK: - Mock Data
extension TodoTask {
    static let mockTasks: [TodoTask] = [
        TodoTask(title: "프로젝트 기획서 작성", isCompleted: false, sortOrder: 0),
        TodoTask(title: "UI 디자인 검토", isCompleted: false, sortOrder: 1),
        TodoTask(title: "API 연동 테스트", isCompleted: false, sortOrder: 2),
        TodoTask(title: "코드 리뷰 요청", isCompleted: true, sortOrder: 3),
        TodoTask(title: "버그 리포트 확인", isCompleted: false, sortOrder: 4),
        TodoTask(title: "문서 업데이트", isCompleted: false, sortOrder: 5),
        TodoTask(title: "팀 미팅 준비", isCompleted: true, sortOrder: 6),
        TodoTask(title: "테스트 케이스 작성", isCompleted: false, sortOrder: 7),
        TodoTask(title: "배포 스크립트 점검", isCompleted: false, sortOrder: 8),
        TodoTask(title: "주간 보고서 제출", isCompleted: true, sortOrder: 9),
        TodoTask(title: "신규 기능 브레인스토밍", isCompleted: false, sortOrder: 10),
        TodoTask(title: "레거시 코드 정리", isCompleted: false, sortOrder: 11)
    ]

    static func mockTasksForEvent(_ eventId: UUID) -> [TodoTask] {
        [
            TodoTask(title: "장소 예약 확인", isCompleted: false, eventId: eventId, sortOrder: 0),
            TodoTask(title: "참가자 명단 정리", isCompleted: false, eventId: eventId, sortOrder: 1),
            TodoTask(title: "발표 자료 준비", isCompleted: false, eventId: eventId, sortOrder: 2),
            TodoTask(title: "케이터링 주문", isCompleted: true, eventId: eventId, sortOrder: 3),
            TodoTask(title: "안내 이메일 발송", isCompleted: false, eventId: eventId, sortOrder: 4)
        ]
    }
}
