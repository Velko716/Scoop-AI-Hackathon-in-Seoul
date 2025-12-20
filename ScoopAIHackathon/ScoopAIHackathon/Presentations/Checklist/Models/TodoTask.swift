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
    /// 기본 목 데이터 (레거시 뷰 호환용)
    static var mockTasks: [TodoTask] {
        [
            TodoTask(title: "회의 안건 정리", isCompleted: false, sortOrder: 0),
            TodoTask(title: "회의록 템플릿 준비", isCompleted: false, sortOrder: 1),
            TodoTask(title: "참석자 확인", isCompleted: true, sortOrder: 2)
        ]
    }

    /// 이벤트별 체크리스트 템플릿
    enum EventTaskTemplate: CaseIterable {
        case conference
        case workshop
        case designSprint
        case meeting
        case hackathon

        var tasks: [(title: String, isCompleted: Bool)] {
            switch self {
            case .conference:
                return [
                    ("발표 자료 최종 검토", false),
                    ("참가 등록 확인", true),
                    ("숙소 예약", true),
                    ("명함 준비", false),
                    ("노트북 충전기 챙기기", false)
                ]
            case .workshop:
                return [
                    ("예제 코드 준비", false),
                    ("실습 환경 테스트", false),
                    ("참가자 명단 확인", true),
                    ("교재 인쇄", false)
                ]
            case .designSprint:
                return [
                    ("디자인 도구 준비", false),
                    ("사용자 인터뷰 일정 확인", true),
                    ("프로토타입 템플릿 준비", false),
                    ("포스트잇 & 마커 준비", false),
                    ("회의실 예약 확인", true)
                ]
            case .meeting:
                return [
                    ("회의 안건 정리", false),
                    ("회의록 템플릿 준비", false),
                    ("참석자 확인", true)
                ]
            case .hackathon:
                return [
                    ("아이디어 구상", true),
                    ("팀원 역할 분담", false),
                    ("개발 환경 설정", false),
                    ("API 문서 확인", false),
                    ("발표 자료 템플릿 준비", false),
                    ("데모 시나리오 작성", false)
                ]
            }
        }
    }

    /// 이벤트 제목에 따라 적절한 체크리스트 생성
    static func tasksForEvent(eventId: UUID, eventTitle: String) -> [TodoTask] {
        let template: EventTaskTemplate

        let lowerTitle = eventTitle.lowercased()
        if lowerTitle.contains("conference") || lowerTitle.contains("컨퍼런스") {
            template = .conference
        } else if lowerTitle.contains("workshop") || lowerTitle.contains("워크샵") {
            template = .workshop
        } else if lowerTitle.contains("design") || lowerTitle.contains("디자인") {
            template = .designSprint
        } else if lowerTitle.contains("meeting") || lowerTitle.contains("미팅") || lowerTitle.contains("회의") {
            template = .meeting
        } else if lowerTitle.contains("hackathon") || lowerTitle.contains("해커톤") {
            template = .hackathon
        } else {
            // 기본 템플릿
            template = .meeting
        }

        return template.tasks.enumerated().map { index, taskInfo in
            TodoTask(
                title: taskInfo.title,
                isCompleted: taskInfo.isCompleted,
                eventId: eventId,
                sortOrder: index
            )
        }
    }
}
