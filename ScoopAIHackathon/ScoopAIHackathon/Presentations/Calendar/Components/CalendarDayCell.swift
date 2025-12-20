//
//  CalendarDayCell.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date?
    let events: [CalendarEvent]
    let viewModel: CalendarViewModel
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 날짜 숫자
            if let date = date {
                dayNumber(for: date)
            }

            // 이벤트 바들
            eventBars

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: cellHeight)
    }

    @ViewBuilder
    private func dayNumber(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let isSunday = weekday == 1
        let isSaturday = weekday == 7

        Text("\(day)")
            .font(.pretendard(type: isToday ? .bold : .regular, size: 14))
            .foregroundStyle(dayColor(isSunday: isSunday, isSaturday: isSaturday))
            .frame(width: 24, height: 24)
            .background {
                if isToday {
                    Circle()
                        .fill(Color.blue)
                }
            }
            .foregroundStyle(isToday ? .white : dayColor(isSunday: isSunday, isSaturday: isSaturday))
            .padding(.leading, 2)
            .padding(.top, 2)
    }

    private func dayColor(isSunday: Bool, isSaturday: Bool) -> Color {
        if isToday {
            return .white
        } else if isSunday {
            return .red
        } else if isSaturday {
            return .blue
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private var eventBars: some View {
        if let date = date {
            let eventsForDate = viewModel.events(for: date)
            let maxRows = viewModel.maxRowCount(for: date)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<max(maxRows, 1), id: \.self) { rowIndex in
                    if let event = eventsForDate.first(where: { viewModel.verticalIndex(for: $0) == rowIndex }) {
                        EventBarView(
                            event: event,
                            position: viewModel.barPosition(for: event, on: date),
                            verticalIndex: 0
                        )
                    } else {
                        // 빈 공간 유지 (다른 이벤트와 높이 맞추기)
                        Color.clear
                            .frame(height: 18)
                    }
                }
            }
        }
    }

    private var cellHeight: CGFloat {
        // 기본 높이 + 이벤트 바 공간
        let baseHeight: CGFloat = 30
        let eventHeight: CGFloat = 20
        guard let date = date else { return baseHeight }
        let maxRows = viewModel.maxRowCount(for: date)
        return baseHeight + CGFloat(max(maxRows, 1)) * eventHeight
    }
}

#Preview {
    CalendarDayCell(
        date: Date(),
        events: CalendarEvent.mockEvents,
        viewModel: CalendarViewModel(),
        isToday: true
    )
    .frame(width: 50)
    .border(Color.gray.opacity(0.3))
}
