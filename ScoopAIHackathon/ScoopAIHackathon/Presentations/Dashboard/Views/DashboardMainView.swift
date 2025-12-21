//
//  DashboardMainView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - Design Colors
private enum DashboardColors {
    static let backgroundNormal = Color("Primary50")
    static let labelAssistive = Color("GrayscaleBlack")
    static let labelNormal = Color("Grayscale300")
}

struct DashboardMainView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showChatbotSheet = false
    @State private var showScheduleConfirmation = false
    @State private var pendingChanges: [ScheduleChangeItem] = []

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        logoSection
                        calendarSection
                        checklistSection
                    }
                }
                .background(DashboardColors.backgroundNormal)

                // 챗봇 FAB 버튼
                chatbotButton
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showScheduleConfirmation) {
                ScheduleConfirmationView(
                    changes: pendingChanges,
                    existingEvents: viewModel.events,
                    onApply: {
                        applyScheduleChanges()
                    }
                )
            }
        }
        .sheet(isPresented: $showChatbotSheet) {
            AskAISheetView(
                existingEvents: viewModel.events,
                onConfirmSchedule: { changes in
                    pendingChanges = changes
                    showChatbotSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showScheduleConfirmation = true
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Apply Schedule Changes
    private func applyScheduleChanges() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var newEvents: [CalendarEvent] = []

        for change in pendingChanges {
            switch change.type {
            case "add":
                if let dateStr = change.newDate,
                   let date = dateFormatter.date(from: dateStr) {
                    let event = CalendarEvent(
                        title: change.title ?? "새 일정",
                        startDate: date,
                        endDate: date,
                        color: colorFromString(change.color)
                    )
                    newEvents.append(event)
                }

            case "modify":
                // 기존 일정 찾아서 삭제 후 새로 추가
                if let title = change.title,
                   let existingEvent = viewModel.events.first(where: { $0.title == title }) {
                    viewModel.removeEvent(id: existingEvent.id)
                }
                if let dateStr = change.newDate,
                   let date = dateFormatter.date(from: dateStr) {
                    let event = CalendarEvent(
                        title: change.title ?? "수정된 일정",
                        startDate: date,
                        endDate: date,
                        color: colorFromString(change.color)
                    )
                    newEvents.append(event)
                }

            case "delete":
                if let title = change.title,
                   let existingEvent = viewModel.events.first(where: { $0.title == title }) {
                    viewModel.removeEvent(id: existingEvent.id)
                }

            default:
                break
            }
        }

        // 새 이벤트들 추가
        if !newEvents.isEmpty {
            viewModel.addEvents(newEvents)
        }

        // 변경사항 초기화
        pendingChanges = []
    }

    private func colorFromString(_ colorName: String?) -> Color {
        switch colorName?.lowercased() {
        case "blue": return Color("Primary500")
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        default: return Color("Primary200")
        }
    }

    // MARK: - Chatbot FAB
    private var chatbotButton: some View {
        Button(action: {
            showChatbotSheet = true
        }) {
            Image("ChatBotIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 33, height: 33)
                .padding(13)
                .background(Color("Primary500"))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Logo Section
extension DashboardMainView {
    private var logoSection: some View {
        Text("LOGO")
            .font(.pretendard(type: .semiBold, size: 24))
            .foregroundStyle(DashboardColors.labelAssistive)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }
}

// MARK: - Calendar Section
extension DashboardMainView {
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            HStack {
                Text("행사 일정")
                    .font(.pretendard(type: .semiBold, size: 15))
                    .foregroundStyle(DashboardColors.labelAssistive)

                Spacer()

                Button(action: {
                    // 편집 액션
                }) {
                    Text("편집")
                        .font(.pretendard(type: .semiBold, size: 15))
                        .foregroundStyle(DashboardColors.labelNormal)
                }
            }
            .padding(.horizontal, 16)

            // 캘린더 뷰
            DashboardCalendarView(viewModel: viewModel)
        }
    }
}

// MARK: - Checklist Section
extension DashboardMainView {
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 섹션 헤더
            Text("To Do")
                .font(.pretendard(type: .semiBold, size: 15))
                .foregroundStyle(DashboardColors.labelAssistive)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // 체크리스트 뷰
            IntegratedChecklistView(viewModel: viewModel)
        }
    }
}

#Preview {
    DashboardMainView()
}
