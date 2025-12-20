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

    /// 행사명
    var eventName: String? {
        eventPlanResponse?.eventName
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
