//
//  DashboardCalendarView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct DashboardCalendarView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            calendarWeeks
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color("Grayscale400").opacity(0.25), radius: 4, x: 0, y: 0)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Calendar Colors
private enum CalendarColors {
    static let primaryStrong = Color("Primary600")        // 월 제목
    static let primaryNormal = Color("Primary500")        // 화살표
}

// MARK: - Subviews
extension DashboardCalendarView {
    private var monthHeader: some View {
        HStack {
            Text(viewModel.displayedMonthEnglish)
                .font(.pretendard(type: .semiBold, size: 21))
                .foregroundStyle(CalendarColors.primaryStrong)

            Spacer()

            HStack(spacing: 4) {
                Button(action: viewModel.moveToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CalendarColors.primaryNormal)
                        .frame(width: 44, height: 44)
                }

                Button(action: viewModel.moveToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CalendarColors.primaryNormal)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 22) {
            ForEach(viewModel.weekdaySymbolsMonday.indices, id: \.self) { index in
                Text(viewModel.weekdaySymbolsMonday[index])
                    .font(.pretendard(type: .semiBold, size: 16))
                    .foregroundStyle(weekdayHeaderColor(for: index))
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var calendarWeeks: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.weeksInMonth.indices, id: \.self) { weekIndex in
                WeekRowView(
                    week: viewModel.weeksInMonth[weekIndex],
                    weekIndex: weekIndex,
                    viewModel: viewModel
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }

    private func weekdayHeaderColor(for index: Int) -> Color {
        if index == 6 {
            return Color("Primary500")  // 일요일
        }
        return Color("GrayscaleBlack")
    }
}

// MARK: - WeekRowView
struct WeekRowView: View {
    let week: [Date?]
    let weekIndex: Int
    @Bindable var viewModel: DashboardViewModel

    private let cellWidth: CGFloat = 44
    private let rowHeight: CGFloat = 44
    private let barHeight: CGFloat = 16
    private let barSpacing: CGFloat = 2
    private let topPadding: CGFloat = 24

    private var eventsInWeek: [CalendarEvent] {
        let dates = week.compactMap { $0 }
        guard let firstDate = dates.first, let lastDate = dates.last else { return [] }

        return viewModel.events.filter { event in
            let eventStart = Calendar.current.startOfDay(for: event.startDate)
            let eventEnd = Calendar.current.startOfDay(for: event.endDate)
            let weekStart = Calendar.current.startOfDay(for: firstDate)
            let weekEnd = Calendar.current.startOfDay(for: lastDate)

            return eventStart <= weekEnd && eventEnd >= weekStart
        }.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 날짜 숫자들
            HStack(spacing: 0) {
                ForEach(week.indices, id: \.self) { dayIndex in
                    DayNumberCell(
                        date: week[dayIndex],
                        weekdayIndex: dayIndex
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // 이벤트 바들 (오버레이)
            ForEach(eventsInWeek) { event in
                ContinuousEventBar(
                    event: event,
                    week: week,
                    rowIndex: viewModel.verticalIndex(for: event),
                    isSelected: viewModel.isEventSelected(event),
                    onTap: { viewModel.selectEvent(event.id) }
                )
            }
        }
        .frame(height: calculateRowHeight())
    }

    private func calculateRowHeight() -> CGFloat {
        let maxRows = eventsInWeek.isEmpty ? 1 : (eventsInWeek.map { viewModel.verticalIndex(for: $0) }.max() ?? 0) + 1
        return topPadding + CGFloat(maxRows) * (barHeight + barSpacing) + 4
    }
}

// MARK: - DayNumberCell
struct DayNumberCell: View {
    let date: Date?
    let weekdayIndex: Int

    private let calendar = Calendar.current

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
                    .font(.pretendard(type: .medium, size: 16))
                    .foregroundStyle(dayTextColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isToday ? Color("Primary600") : Color.clear)
                    )
            }
            Spacer()
        }
        .frame(height: 24)
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        if weekdayIndex == 6 {
            return Color("Primary500")  // 일요일
        }
        return Color("GrayscaleBlack")
    }
}

// MARK: - ContinuousEventBar
struct ContinuousEventBar: View {
    let event: CalendarEvent
    let week: [Date?]
    let rowIndex: Int
    let isSelected: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current
    private let barHeight: CGFloat = 16
    private let barSpacing: CGFloat = 2
    private let cornerRadius: CGFloat = 4
    private let topPadding: CGFloat = 24

    private var barColor: Color {
        isSelected ? Color("Primary200") : Color("Primary50")
    }

    private var textColor: Color {
        isSelected ? .white : Color("Primary500")
    }

    private var startDayIndex: Int {
        let eventStart = calendar.startOfDay(for: event.startDate)

        for (index, date) in week.enumerated() {
            guard let date = date else { continue }
            let dayStart = calendar.startOfDay(for: date)

            if dayStart >= eventStart {
                return index
            }
        }

        return 0
    }

    private var endDayIndex: Int {
        let eventEnd = calendar.startOfDay(for: event.endDate)

        for (index, date) in week.enumerated().reversed() {
            guard let date = date else { continue }
            let dayStart = calendar.startOfDay(for: date)

            if dayStart <= eventEnd {
                return index
            }
        }

        return 6
    }

    private var isStartInWeek: Bool {
        guard let firstDate = week.compactMap({ $0 }).first else { return false }
        let eventStart = calendar.startOfDay(for: event.startDate)
        let weekStart = calendar.startOfDay(for: firstDate)
        return eventStart >= weekStart
    }

    private var isEndInWeek: Bool {
        guard let lastDate = week.compactMap({ $0 }).last else { return false }
        let eventEnd = calendar.startOfDay(for: event.endDate)
        let weekEnd = calendar.startOfDay(for: lastDate)
        return eventEnd <= weekEnd
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
                    Text(event.title)
                        .font(.pretendard(type: .medium, size: 12))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
                Spacer(minLength: 0)
            }
            .frame(width: barWidth, height: barHeight)
            .background(barColor)
            .clipShape(barShape)
            .offset(x: startX + 2, y: yOffset)
            .onTapGesture {
                onTap()
            }
            .sensoryFeedback(.selection, trigger: isSelected)
        }
    }

    private var barShape: some Shape {
        ContinuousBarShape(
            isStart: isStartInWeek,
            isEnd: isEndInWeek,
            radius: cornerRadius
        )
    }
}

// MARK: - ContinuousBarShape
struct ContinuousBarShape: Shape {
    let isStart: Bool
    let isEnd: Bool
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var corners: UIRectCorner = []

        if isStart {
            corners.insert(.topLeft)
            corners.insert(.bottomLeft)
        }
        if isEnd {
            corners.insert(.topRight)
            corners.insert(.bottomRight)
        }

        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardCalendarView(viewModel: DashboardViewModel())
        .padding()
        .background(Color(.systemGroupedBackground))
}
