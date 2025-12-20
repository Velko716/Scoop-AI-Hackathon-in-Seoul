//
//  CalendarEvent.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct CalendarEvent: Identifiable, Equatable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let color: Color

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        color: Color
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.color = color
    }
}

// MARK: - Mock Data
extension CalendarEvent {
    static let mockEvents: [CalendarEvent] = {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        func date(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? now
        }

        return [
            // 컨퍼런스 A: 15일 ~ 18일 (파란색)
            CalendarEvent(
                title: "Apple Developer Conference",
                startDate: date(15),
                endDate: date(18),
                color: .blue
            ),
            // 컨퍼런스 B: 17일 ~ 20일 (초록색) - A와 겹침
            CalendarEvent(
                title: "SwiftUI Workshop",
                startDate: date(17),
                endDate: date(20),
                color: .green
            ),
            // 워크샵: 22일 ~ 24일 (주황색)
            CalendarEvent(
                title: "Design Sprint",
                startDate: date(22),
                endDate: date(24),
                color: .orange
            ),
            // 단일 이벤트: 10일
            CalendarEvent(
                title: "Team Meeting",
                startDate: date(10),
                endDate: date(10),
                color: .purple
            ),
            // 긴 이벤트: 5일 ~ 12일 (빨간색)
            CalendarEvent(
                title: "Hackathon Week",
                startDate: date(5),
                endDate: date(12),
                color: .red
            )
        ]
    }()
}
