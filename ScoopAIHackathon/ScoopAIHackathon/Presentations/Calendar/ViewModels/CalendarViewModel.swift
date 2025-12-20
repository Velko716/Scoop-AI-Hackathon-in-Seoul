//
//  CalendarViewModel.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

@Observable
@MainActor
class CalendarViewModel {
    // MARK: - State
    var currentMonth: Date = Date()
    var events: [CalendarEvent] = []

    // AI 관련 상태
    var isLoadingAI: Bool = false
    var aiError: String?

    private let calendar = Calendar.current
    private let service = SpoonAgentService.shared

    // 색상 매핑
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

    // MARK: - AI Event Planning

    /// EventInfo를 기반으로 AI에게 일정 기획 요청
    func planEventWithAI(eventInfo: [EventInfo]) async {
        isLoadingAI = true
        aiError = nil

        // EventInfo를 EventInfoItem으로 변환
        let items = eventInfo.map { EventInfoItem(label: $0.label, value: $0.value) }

        let result = await service.planEvent(eventInfo: items)

        switch result {
        case .success(let response):
            if let schedules = response.schedules {
                // ScheduleItem을 CalendarEvent로 변환
                let newEvents = schedules.compactMap { schedule -> CalendarEvent? in
                    guard let startDate = parseDate(schedule.startDate),
                          let endDate = parseDate(schedule.endDate) else {
                        return nil
                    }

                    return CalendarEvent(
                        title: schedule.title,
                        startDate: startDate,
                        endDate: endDate,
                        color: colorMap[schedule.color.lowercased()] ?? .blue
                    )
                }

                // 기존 이벤트를 새 이벤트로 교체
                events = newEvents

                // 첫 번째 이벤트의 월로 이동
                if let firstEvent = newEvents.first {
                    moveToMonth(firstEvent.startDate)
                }
            } else {
                aiError = response.error ?? "일정을 파싱할 수 없습니다."
            }

        case .failure(let error):
            aiError = error.localizedDescription
        }

        isLoadingAI = false
    }

    /// 날짜 문자열 파싱 (YYYY-MM-DD)
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.date(from: dateString)
    }

    /// 이벤트 초기화
    func clearEvents() {
        events = []
    }

    /// Mock 이벤트 로드
    func loadMockEvents() {
        events = CalendarEvent.mockEvents
    }
}

// MARK: - Bar Position
enum BarPosition {
    case start   // 시작일: 왼쪽만 둥글게
    case middle  // 중간: 직사각형
    case end     // 종료일: 오른쪽만 둥글게
    case single  // 단일: 양쪽 둥글게
}
