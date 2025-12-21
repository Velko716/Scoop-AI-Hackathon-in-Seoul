//
//  ScheduleConfirmationView.swift
//  ScoopAIHackathon
//
//  일정 변경 확인 뷰 - 변경된 일정을 캘린더에서 미리보기하고 적용/취소
//

import SwiftUI

// MARK: - Preview Schedule Item
struct PreviewScheduleItem: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let color: PreviewScheduleColor
    let isNew: Bool  // AI가 새로 추가한 일정인지
}

enum PreviewScheduleColor {
    case light      // Primary/50
    case medium     // Primary/100
    case dark       // Primary/200

    var backgroundColor: Color {
        switch self {
        case .light: return Color("Primary50")
        case .medium: return Color("Primary100")
        case .dark: return Color("Primary200")
        }
    }

    var textColor: Color {
        switch self {
        case .light: return Color("Primary500")
        case .medium: return Color("Primary600")
        case .dark: return .white
        }
    }
}

// MARK: - ScheduleConfirmationView
struct ScheduleConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let changes: [ScheduleChangeItem]
    let existingEvents: [CalendarEvent]
    var onApply: (() -> Void)?

    @State private var currentMonth: Date = Date()
    @State private var previewSchedules: [PreviewScheduleItem] = []

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            // Background
            Color("Primary50")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Bar
                navigationBar

                // Section Header
                sectionHeader

                // Calendar
                calendarCard

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            buildPreviewSchedules()
        }
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color("Grayscale100"))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            // Apply Button
            Button(action: {
                onApply?()
                dismiss()
            }) {
                Text("적용")
                    .font(.pretendard(type: .medium, size: 18))
                    .foregroundStyle(Color("Primary500"))
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Section Header
    private var sectionHeader: some View {
        Text("행사 일정")
            .font(.pretendard(type: .semiBold, size: 15))
            .foregroundStyle(Color("GrayscaleBlack"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            calendarWeeks
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color("Primary200").opacity(0.2), radius: 4, x: 0, y: 0)
        .padding(.horizontal, 16)
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Text(displayedMonthEnglish)
                .font(.pretendard(type: .semiBold, size: 21))
                .foregroundStyle(Color("Primary600"))

            Spacer()

            HStack(spacing: 4) {
                Button(action: moveToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("Primary500"))
                        .frame(width: 44, height: 44)
                }

                Button(action: moveToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("Primary500"))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 22) {
            ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                Text(day)
                    .font(.pretendard(type: .semiBold, size: 16))
                    .foregroundStyle(day == "일" ? Color("Primary500") : Color("GrayscaleBlack"))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Calendar Weeks
    private var calendarWeeks: some View {
        VStack(spacing: 0) {
            ForEach(weeksInMonth.indices, id: \.self) { weekIndex in
                PreviewWeekRowView(
                    week: weeksInMonth[weekIndex],
                    schedules: previewSchedules,
                    calendar: calendar
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Computed Properties

    private var displayedMonthEnglish: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var weeksInMonth: [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }

        var days: [Date?] = []
        let firstDayOfMonth = monthInterval.start
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

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []

        for day in days {
            currentWeek.append(day)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    // MARK: - Actions

    private func moveToPreviousMonth() {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = previousMonth
    }

    private func moveToNextMonth() {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        currentMonth = nextMonth
    }

    // MARK: - Build Preview Schedules

    private func buildPreviewSchedules() {
        var schedules: [PreviewScheduleItem] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // 기존 이벤트 추가
        for event in existingEvents {
            schedules.append(PreviewScheduleItem(
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                color: .light,
                isNew: false
            ))
        }

        // AI 변경사항 추가
        for change in changes {
            if change.type == "add", let newDateStr = change.newDate,
               let newDate = dateFormatter.date(from: newDateStr) {
                schedules.append(PreviewScheduleItem(
                    title: change.title ?? "새 일정",
                    startDate: newDate,
                    endDate: newDate,
                    color: .dark,
                    isNew: true
                ))
            }
        }

        // 변경사항 중 첫 번째 일정의 월로 이동
        if let firstChange = changes.first,
           let newDateStr = firstChange.newDate,
           let newDate = dateFormatter.date(from: newDateStr) {
            currentMonth = newDate
        }

        previewSchedules = schedules
    }
}

// MARK: - PreviewWeekRowView
struct PreviewWeekRowView: View {
    let week: [Date?]
    let schedules: [PreviewScheduleItem]
    let calendar: Calendar

    private let barHeight: CGFloat = 16
    private let barSpacing: CGFloat = 4
    private let topPadding: CGFloat = 28

    private var schedulesInWeek: [PreviewScheduleItem] {
        let dates = week.compactMap { $0 }
        guard let firstDate = dates.first, let lastDate = dates.last else { return [] }

        return schedules.filter { schedule in
            let scheduleStart = calendar.startOfDay(for: schedule.startDate)
            let scheduleEnd = calendar.startOfDay(for: schedule.endDate)
            let weekStart = calendar.startOfDay(for: firstDate)
            let weekEnd = calendar.startOfDay(for: lastDate)

            return scheduleStart <= weekEnd && scheduleEnd >= weekStart
        }.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 날짜 숫자들
            HStack(spacing: 0) {
                ForEach(week.indices, id: \.self) { dayIndex in
                    PreviewDayCell(
                        date: week[dayIndex],
                        weekdayIndex: dayIndex,
                        calendar: calendar
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // 이벤트 바들
            ForEach(Array(schedulesInWeek.enumerated()), id: \.element.id) { index, schedule in
                PreviewEventBar(
                    schedule: schedule,
                    week: week,
                    rowIndex: index,
                    calendar: calendar
                )
            }
        }
        .frame(height: calculateRowHeight())
    }

    private func calculateRowHeight() -> CGFloat {
        let maxRows = schedulesInWeek.isEmpty ? 1 : schedulesInWeek.count
        return topPadding + CGFloat(maxRows) * (barHeight + barSpacing) + 8
    }
}

// MARK: - PreviewDayCell
struct PreviewDayCell: View {
    let date: Date?
    let weekdayIndex: Int
    let calendar: Calendar

    private var isToday: Bool {
        guard let date = date else { return false }
        return calendar.isDateInToday(date)
    }

    private var dayNumber: String {
        guard let date = date else { return "" }
        return "\(calendar.component(.day, from: date))"
    }

    var body: some View {
        VStack {
            if date != nil {
                Text(dayNumber)
                    .font(.pretendard(type: isToday ? .semiBold : .medium, size: 16))
                    .foregroundStyle(dayTextColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isToday ? Color("Primary500") : Color.clear)
                    )
            }
            Spacer()
        }
        .frame(height: 28)
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        if weekdayIndex == 6 {
            return Color("Primary500")
        }
        return Color("GrayscaleBlack")
    }
}

// MARK: - PreviewEventBar
struct PreviewEventBar: View {
    let schedule: PreviewScheduleItem
    let week: [Date?]
    let rowIndex: Int
    let calendar: Calendar

    private let barHeight: CGFloat = 16
    private let barSpacing: CGFloat = 4
    private let topPadding: CGFloat = 28

    private var startDayIndex: Int {
        let scheduleStart = calendar.startOfDay(for: schedule.startDate)
        for (index, date) in week.enumerated() {
            guard let date = date else { continue }
            if calendar.startOfDay(for: date) >= scheduleStart {
                return index
            }
        }
        return 0
    }

    private var endDayIndex: Int {
        let scheduleEnd = calendar.startOfDay(for: schedule.endDate)
        for (index, date) in week.enumerated().reversed() {
            guard let date = date else { continue }
            if calendar.startOfDay(for: date) <= scheduleEnd {
                return index
            }
        }
        return 6
    }

    private var isStartInWeek: Bool {
        guard let firstDate = week.compactMap({ $0 }).first else { return false }
        return calendar.startOfDay(for: schedule.startDate) >= calendar.startOfDay(for: firstDate)
    }

    private var isEndInWeek: Bool {
        guard let lastDate = week.compactMap({ $0 }).last else { return false }
        return calendar.startOfDay(for: schedule.endDate) <= calendar.startOfDay(for: lastDate)
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let cellWidth = totalWidth / 7

            let startX = CGFloat(startDayIndex) * cellWidth
            let barWidth = CGFloat(endDayIndex - startDayIndex + 1) * cellWidth - 4
            let yOffset = topPadding + CGFloat(rowIndex) * (barHeight + barSpacing)

            HStack(spacing: 0) {
                if isStartInWeek {
                    Text(schedule.title)
                        .font(.pretendard(type: .medium, size: 12))
                        .foregroundStyle(schedule.color.textColor)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
                Spacer(minLength: 0)
            }
            .frame(width: barWidth, height: barHeight)
            .background(schedule.color.backgroundColor)
            .clipShape(barShape)
            .offset(x: startX + 2, y: yOffset)
        }
    }

    private var barShape: some Shape {
        ContinuousBarShape(
            isStart: isStartInWeek,
            isEnd: isEndInWeek,
            radius: 3
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ScheduleConfirmationView(
            changes: [
                ScheduleChangeItem(
                    type: "add",
                    scheduleId: nil,
                    title: "팀 미팅",
                    originalDate: nil,
                    newDate: "2025-12-22",
                    startTime: "15:00",
                    endTime: "16:00",
                    color: "blue"
                )
            ],
            existingEvents: CalendarEvent.mockEvents
        )
    }
}
