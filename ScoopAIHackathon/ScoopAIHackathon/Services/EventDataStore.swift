//
//  EventDataStore.swift
//  ScoopAIHackathon
//
//  AI 응답 데이터를 앱 전역에서 공유하는 스토어
//

import SwiftUI

@MainActor
@Observable
final class EventDataStore {

    // MARK: - Singleton

    static let shared = EventDataStore()

    private init() {}

    // MARK: - Properties

    /// AI로부터 받은 행사 계획 응답
    var eventPlanResponse: EventPlanResponse?

    /// 캘린더 탭으로 이동해야 하는지 여부
    var shouldNavigateToCalendar: Bool = false

    // MARK: - Color Mapping

    private let colorMap: [String: Color] = [
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        "green": .green,
        "blue": .blue,
        "purple": .purple,
        "pink": .pink
    ]

    // MARK: - Computed Properties

    /// EventPlanResponse의 schedules를 CalendarEvent 배열로 변환
    var calendarEvents: [CalendarEvent] {
        guard let schedules = eventPlanResponse?.schedules else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")

        return schedules.compactMap { schedule -> CalendarEvent? in
            guard let startDate = dateFormatter.date(from: schedule.startDate),
                  let endDate = dateFormatter.date(from: schedule.endDate) else {
                return nil
            }

            return CalendarEvent(
                title: schedule.title,
                startDate: startDate,
                endDate: endDate,
                color: colorMap[schedule.color.lowercased()] ?? .blue
            )
        }
    }

    /// EventPlanResponse의 todos를 TodoTask 배열로 변환 (우선순위 순)
    /// - Parameter eventId: 연관된 CalendarEvent의 ID
    /// - Returns: 우선순위 순으로 정렬된 TodoTask 배열
    func todoTasks(for eventId: UUID, scheduleId: String) -> [TodoTask] {
        guard let todos = eventPlanResponse?.todos else { return [] }

        return todos
            .filter { $0.scheduleId == scheduleId }
            .sorted { $0.priority < $1.priority }
            .enumerated()
            .map { index, todo in
                TodoTask(
                    title: todo.title,
                    isCompleted: false,
                    eventId: eventId,
                    sortOrder: index
                )
            }
    }

    /// 모든 todos를 CalendarEvent와 매핑하여 TodoTask 배열로 변환
    func allTodoTasks(for events: [CalendarEvent]) -> [TodoTask] {
        guard let todos = eventPlanResponse?.todos else { return [] }

        var allTasks: [TodoTask] = []

        for event in events {
            let scheduleId = "\(event.title)-\(formatDateForScheduleId(event.startDate))"

            let tasksForEvent = todos
                .filter { $0.scheduleId == scheduleId }
                .sorted { $0.priority < $1.priority }
                .enumerated()
                .map { index, todo in
                    TodoTask(
                        title: todo.title,
                        isCompleted: false,
                        eventId: event.id,
                        sortOrder: index
                    )
                }

            allTasks.append(contentsOf: tasksForEvent)
        }

        return allTasks
    }

    /// Date를 scheduleId 형식으로 변환
    private func formatDateForScheduleId(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: date)
    }

    /// 행사명
    var eventName: String? {
        eventPlanResponse?.eventName
    }

    /// 서버에서 받은 todos가 있는지 확인
    var hasTodos: Bool {
        guard let todos = eventPlanResponse?.todos else { return false }
        return !todos.isEmpty
    }

    // MARK: - Methods

    /// AI 응답 저장 및 캘린더 탭 이동 트리거
    func saveResponse(_ response: EventPlanResponse) {
        self.eventPlanResponse = response
        self.shouldNavigateToCalendar = true
    }

    /// 데이터 초기화
    func reset() {
        eventPlanResponse = nil
        shouldNavigateToCalendar = false
    }
}
