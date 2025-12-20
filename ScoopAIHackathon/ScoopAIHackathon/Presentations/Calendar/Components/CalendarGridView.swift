//
//  CalendarGridView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct CalendarGridView: View {
    let viewModel: CalendarViewModel
    let onDateTap: ((Date) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let calendar = Calendar.current

    init(viewModel: CalendarViewModel, onDateTap: ((Date) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDateTap = onDateTap
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { index, date in
                CalendarDayCell(
                    date: date,
                    events: date.map { viewModel.events(for: $0) } ?? [],
                    viewModel: viewModel,
                    isToday: isToday(date)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if let date = date {
                        onDateTap?(date)
                    }
                }
                .overlay(alignment: .top) {
                    if shouldShowTopBorder(at: index) {
                        Divider()
                    }
                }
                .overlay(alignment: .leading) {
                    if shouldShowLeadingBorder(at: index) {
                        Divider()
                            .frame(width: 0.5)
                    }
                }
            }
        }
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return calendar.isDateInToday(date)
    }

    private func shouldShowTopBorder(at index: Int) -> Bool {
        index >= 7 // 첫 주 이후부터 상단 테두리
    }

    private func shouldShowLeadingBorder(at index: Int) -> Bool {
        index % 7 != 0 // 첫 열 제외하고 좌측 테두리
    }
}

#Preview {
    CalendarGridView(viewModel: CalendarViewModel()) { date in
        print("Tapped: \(date)")
    }
    .padding()
}
