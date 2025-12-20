//
//  EventCalendarView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct EventCalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // 월 헤더
            monthHeader

            // 요일 헤더
            weekdayHeader

            // 캘린더 그리드 (스와이프 지원)
            calendarContent
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.moveToPreviousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.displayedMonth)
                .font(.pretendard(type: .bold, size: 20))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.moveToNextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .font(.pretendard(type: .semiBold, size: 12))
                    .foregroundStyle(weekdayColor(for: index))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return .red      // 일요일
        case 6: return .blue     // 토요일
        default: return .secondary
        }
    }

    // MARK: - Calendar Content with Swipe
    private var calendarContent: some View {
        GeometryReader { geometry in
            CalendarGridView(viewModel: viewModel) { date in
                selectedDate = date
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = geometry.size.width * 0.25
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if value.translation.width > threshold {
                                viewModel.moveToPreviousMonth()
                            } else if value.translation.width < -threshold {
                                viewModel.moveToNextMonth()
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    EventCalendarView()
}
