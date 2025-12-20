//
//  ScoopAIHackathonApp.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import SwiftUI

@main
struct ScoopAIHackathonApp: App {
    @State private var appFlow: AppFlow = .onboarding

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                NavigationStack {
                    DashboardMainView()
                        .navigationTitle("대시보드")
                        .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                OnboardingView(onComplete: {
                    withAnimation {
                        appFlow = .inputEvent
                    }
                })

            case .inputEvent:
                InputEventView(onComplete: {
                    withAnimation {
                        appFlow = .calendar
                    }
                })

            case .calendar:
                CalendarMainView(onNewEvent: {
                    withAnimation {
                        appFlow = .inputEvent
                    }
                })
            }
        }
    }
}

// MARK: - App Flow State

enum AppFlow {
    case onboarding
    case inputEvent
    case calendar
}

// MARK: - Calendar Main View (Wrapper)

struct CalendarMainView: View {
    var onNewEvent: (() -> Void)?

    var body: some View {
        NavigationStack {
            EventCalendarView()
                .navigationTitle("일정 캘린더")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // 데이터 초기화 후 새 행사 입력
                            EventDataStore.shared.reset()
                            onNewEvent?()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
        }
    }
}
