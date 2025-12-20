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
    @State private var showingAIPlanner: Bool = false

    @GestureState private var dragOffset: CGFloat = 0

    // 행사 정보 (PriorityChecklistView의 MockData 사용)
    let eventInfo: [EventInfo] = EventInfo.mockEventData

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 월 헤더
                monthHeader

                // 요일 헤더
                weekdayHeader

                // 캘린더 그리드 (스와이프 지원)
                calendarContent

                // AI 일정 기획 버튼
                aiPlannerButton
            }
            .background(Color(.systemBackground))

            // 로딩 오버레이
            if viewModel.isLoadingAI {
                loadingOverlay
            }
        }
        .alert("오류", isPresented: .init(
            get: { viewModel.aiError != nil },
            set: { if !$0 { viewModel.aiError = nil } }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.aiError ?? "")
        }
    }

    // MARK: - AI Planner Button
    private var aiPlannerButton: some View {
        Button {
            Task {
                await viewModel.planEventWithAI(eventInfo: eventInfo)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("AI 일정 기획")
            }
            .font(.pretendard(type: .semiBold, size: 16))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .disabled(viewModel.isLoadingAI)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("AI가 일정을 기획하고 있어요...")
                    .font(.pretendard(type: .medium, size: 16))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
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
