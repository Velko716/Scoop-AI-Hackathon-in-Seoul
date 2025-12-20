//
//  DashboardViewModel.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Section Expansion State

    var isCalendarExpanded: Bool = true
    var isChecklistExpanded: Bool = true

    // MARK: - Calendar State

    var currentMonth: Date = Date()
    var events: [CalendarEvent] = []
    var selectedEventID: UUID?

    // MARK: - Checklist State

    private(set) var allTasks: [TodoTask] = []

    // MARK: - Dependencies

    private let calendar = Calendar.current
    private let dataStore = EventDataStore.shared

    // MARK: - Initialization

    init() {
        loadInitialData()
    }

    // MARK: - Computed Properties

    /// 현재 날짜 포맷팅 (예: "2025년 12월 21일 토요일")
    var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    /// 현재 월 표시 문자열 (예: "2025년 1월")
    var displayedMonth: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }

    /// 현재 월 표시 문자열 영문 (예: "July 2025")
    var displayedMonthEnglish: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    /// 해당 월의 날짜 배열 (앞쪽 빈 셀 포함) - 일요일 시작
    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }

        var days: [Date?] = []

        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }

        var currentDate = firstDayOfMonth
        while calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }

    /// 해당 월의 날짜 배열 (앞쪽 빈 셀 포함) - 월요일 시작
    var daysInMonthMonday: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }

        var days: [Date?] = []

        let firstDayOfMonth = monthInterval.start
        // 일요일=1, 월요일=2, ... 토요일=7
        // 월요일 시작으로 변환: 월=0, 화=1, 수=2, 목=3, 금=4, 토=5, 일=6
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let mondayBasedWeekday = (firstWeekday + 5) % 7

        for _ in 0..<mondayBasedWeekday {
            days.append(nil)
        }

        var currentDate = firstDayOfMonth
        while calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }

    /// 요일 헤더 - 일요일 시작
    var weekdaySymbols: [String] {
        ["일", "월", "화", "수", "목", "금", "토"]
    }

    /// 요일 헤더 - 월요일 시작
    var weekdaySymbolsMonday: [String] {
        ["월", "화", "수", "목", "금", "토", "일"]
    }

    /// 해당 월을 주 단위로 나눈 배열 (월요일 시작)
    var weeksInMonth: [[Date?]] {
        let days = daysInMonthMonday
        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []

        for day in days {
            currentWeek.append(day)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }

        // 마지막 주가 7일 미만이면 nil로 채움
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    /// 선택된 이벤트에 해당하는 태스크만 필터링 (완료되지 않은 것 우선, sortOrder 순)
    var filteredTasks: [TodoTask] {
        guard let eventId = selectedEventID else { return [] }

        return allTasks
            .filter { $0.eventId == eventId }
            .sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return task1.sortOrder < task2.sortOrder
            }
    }

    /// 진행률 (0.0 ~ 1.0)
    var progress: Double {
        let tasks = filteredTasks
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    /// 진행률 텍스트 (예: "3/5 완료")
    var progressText: String {
        let tasks = filteredTasks
        let completed = tasks.filter(\.isCompleted).count
        return "\(completed)/\(tasks.count) 완료"
    }

    /// 선택된 이벤트
    var selectedEvent: CalendarEvent? {
        guard let id = selectedEventID else { return nil }
        return events.first { $0.id == id }
    }

    // MARK: - Calendar Logic

    func isDateInEventRange(_ date: Date, event: CalendarEvent) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        let eventStart = calendar.startOfDay(for: event.startDate)
        let eventEnd = calendar.startOfDay(for: event.endDate)
        return startOfDay >= eventStart && startOfDay <= eventEnd
    }

    func events(for date: Date) -> [CalendarEvent] {
        events
            .filter { isDateInEventRange(date, event: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

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

    func verticalIndex(for event: CalendarEvent) -> Int {
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        var rowEndDates: [Date] = []

        for e in sortedEvents {
            let eventStart = calendar.startOfDay(for: e.startDate)
            var assignedRow: Int?

            for (index, endDate) in rowEndDates.enumerated() {
                if eventStart > endDate {
                    assignedRow = index
                    rowEndDates[index] = calendar.startOfDay(for: e.endDate)
                    break
                }
            }

            if assignedRow == nil {
                assignedRow = rowEndDates.count
                rowEndDates.append(calendar.startOfDay(for: e.endDate))
            }

            if e.id == event.id {
                return assignedRow!
            }
        }

        return 0
    }

    func maxRowCount(for date: Date) -> Int {
        let eventsOnDate = events(for: date)
        guard !eventsOnDate.isEmpty else { return 0 }
        return eventsOnDate.map { verticalIndex(for: $0) }.max()! + 1
    }

    // MARK: - Calendar Actions

    func moveToNextMonth() {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = nextMonth
    }

    func moveToPreviousMonth() {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = previousMonth
    }

    func selectEvent(_ eventId: UUID?) {
        selectedEventID = eventId
    }

    func isEventSelected(_ event: CalendarEvent) -> Bool {
        selectedEventID == event.id
    }

    // MARK: - Checklist Actions

    func toggleTask(_ task: TodoTask) {
        guard let index = allTasks.firstIndex(where: { $0.id == task.id }) else { return }

        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
            allTasks[index].isCompleted.toggle()

            if allTasks[index].isCompleted {
                moveCompletedTaskToBottom(at: index)
            }
        }
    }

    func addTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              let eventId = selectedEventID else { return }

        let maxOrder = allTasks
            .filter { $0.eventId == eventId }
            .map(\.sortOrder)
            .max() ?? -1

        let newTask = TodoTask(
            title: title.trimmingCharacters(in: .whitespaces),
            eventId: eventId,
            sortOrder: maxOrder + 1
        )

        withAnimation(.spring(duration: 0.3)) {
            allTasks.append(newTask)
        }
    }

    func updateTaskTitle(_ task: TodoTask, newTitle: String) {
        guard let index = allTasks.firstIndex(where: { $0.id == task.id }) else { return }
        allTasks[index].title = newTitle.trimmingCharacters(in: .whitespaces)
    }

    func deleteTask(_ task: TodoTask) {
        withAnimation(.spring(duration: 0.3)) {
            allTasks.removeAll { $0.id == task.id }
        }
    }

    func moveTasks(from source: IndexSet, to destination: Int) {
        guard let eventId = selectedEventID else { return }

        var tasksForEvent = allTasks
            .filter { $0.eventId == eventId }
            .sorted { $0.sortOrder < $1.sortOrder }

        tasksForEvent.move(fromOffsets: source, toOffset: destination)

        for (newIndex, task) in tasksForEvent.enumerated() {
            if let globalIndex = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks[globalIndex].sortOrder = newIndex
            }
        }
    }

    // MARK: - Private Methods

    private func loadInitialData() {
        let storeEvents = dataStore.calendarEvents
        if !storeEvents.isEmpty {
            events = storeEvents
            if let firstEvent = storeEvents.first {
                currentMonth = firstEvent.startDate
            }
        } else {
            events = CalendarEvent.mockEvents
        }

        selectTodaysEventIfExists()
        loadMockTasksForEvents()
    }

    private func selectTodaysEventIfExists() {
        let today = calendar.startOfDay(for: Date())

        if let todayEvent = events.first(where: { isDateInEventRange(today, event: $0) }) {
            selectedEventID = todayEvent.id
        } else if let firstEvent = events.first {
            selectedEventID = firstEvent.id
        }
    }

    private func loadMockTasksForEvents() {
        for event in events {
            let tasks = TodoTask.mockTasksForEvent(event.id)
            allTasks.append(contentsOf: tasks)
        }
    }

    private func moveCompletedTaskToBottom(at index: Int) {
        guard let eventId = allTasks[index].eventId else { return }

        let tasksForEvent = allTasks.filter { $0.eventId == eventId }
        let maxOrder = tasksForEvent.map(\.sortOrder).max() ?? 0

        allTasks[index].sortOrder = maxOrder + 1
    }

    // MARK: - Section Toggle

    func toggleCalendarSection() {
        withAnimation(.spring(duration: 0.3)) {
            isCalendarExpanded.toggle()
        }
    }

    func toggleChecklistSection() {
        withAnimation(.spring(duration: 0.3)) {
            isChecklistExpanded.toggle()
        }
    }
}
