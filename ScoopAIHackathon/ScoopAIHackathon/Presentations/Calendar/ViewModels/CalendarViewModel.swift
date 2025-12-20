//
//  CalendarViewModel.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

@Observable
class CalendarViewModel {
    // MARK: - State
    var currentMonth: Date = Date()
    var events: [CalendarEvent] = CalendarEvent.mockEvents

    private let calendar = Calendar.current

    // MARK: - Computed Properties

    /// 현재 월 표시 문자열 (예: "2025년 1월")
    var displayedMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }

    /// 해당 월의 날짜 배열 (앞쪽 빈 셀 포함)
    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        var days: [Date?] = []

        // 첫 주의 시작일부터 월의 첫날까지 빈 셀 추가
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // 일요일 = 1, 월요일 = 2, ... 토요일 = 7
        // 일요일 시작이므로 (firstWeekday - 1) 만큼 nil 추가
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }

        // 해당 월의 모든 날짜 추가
        var currentDate = firstDayOfMonth
        while calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }

    /// 요일 헤더
    var weekdaySymbols: [String] {
        return ["일", "월", "화", "수", "목", "금", "토"]
    }

    // MARK: - Core Logic

    /// 특정 날짜가 이벤트 기간 내에 있는지 판단
    func isDateInEventRange(_ date: Date, event: CalendarEvent) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        let eventStart = calendar.startOfDay(for: event.startDate)
        let eventEnd = calendar.startOfDay(for: event.endDate)
        return startOfDay >= eventStart && startOfDay <= eventEnd
    }

    /// 특정 날짜에 해당하는 이벤트들 반환 (startDate 기준 정렬)
    func events(for date: Date) -> [CalendarEvent] {
        events
            .filter { isDateInEventRange(date, event: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// 이벤트의 막대 위치 결정 (시작/중간/끝/단일)
    func barPosition(for event: CalendarEvent, on date: Date) -> BarPosition {
        let startOfDay = calendar.startOfDay(for: date)
        let eventStart = calendar.startOfDay(for: event.startDate)
        let eventEnd = calendar.startOfDay(for: event.endDate)

        let isStart = calendar.isDate(startOfDay, inSameDayAs: eventStart)
        let isEnd = calendar.isDate(startOfDay, inSameDayAs: eventEnd)

        if isStart && isEnd {
            return .single
        } else if isStart {
            return .start
        } else if isEnd {
            return .end
        } else {
            return .middle
        }
    }

    /// 겹치는 이벤트의 수직 인덱스(Row Index) 계산
    /// 각 이벤트가 전체 기간 동안 일관된 row를 유지하도록 계산
    func verticalIndex(for event: CalendarEvent) -> Int {
        // 이벤트를 시작일 기준으로 정렬
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }

        // 각 row의 마지막 종료일을 추적
        var rowEndDates: [Date] = []

        for e in sortedEvents {
            let eventStart = calendar.startOfDay(for: e.startDate)

            // 사용 가능한 row 찾기 (이전 이벤트가 끝난 후 시작하는 경우)
            var assignedRow: Int?
            for (index, endDate) in rowEndDates.enumerated() {
                if eventStart > endDate {
                    assignedRow = index
                    rowEndDates[index] = calendar.startOfDay(for: e.endDate)
                    break
                }
            }

            // 사용 가능한 row가 없으면 새 row 생성
            if assignedRow == nil {
                assignedRow = rowEndDates.count
                rowEndDates.append(calendar.startOfDay(for: e.endDate))
            }

            // 찾고 있는 이벤트인 경우 인덱스 반환
            if e.id == event.id {
                return assignedRow!
            }
        }

        return 0
    }

    /// 특정 날짜에 표시할 이벤트의 최대 row 수
    func maxRowCount(for date: Date) -> Int {
        let eventsOnDate = events(for: date)
        guard !eventsOnDate.isEmpty else { return 0 }
        return eventsOnDate.map { verticalIndex(for: $0) }.max()! + 1
    }

    // MARK: - Actions

    func moveToNextMonth() {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = nextMonth
    }

    func moveToPreviousMonth() {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = previousMonth
    }

    func moveToMonth(_ date: Date) {
        currentMonth = date
    }
}

// MARK: - Bar Position
enum BarPosition {
    case start   // 시작일: 왼쪽만 둥글게
    case middle  // 중간: 직사각형
    case end     // 종료일: 오른쪽만 둥글게
    case single  // 단일: 양쪽 둥글게
}
