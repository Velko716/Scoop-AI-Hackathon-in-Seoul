//
//  ScoopAIHackathonApp.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import SwiftUI

@main
struct ScoopAIHackathonApp: App {
    @State private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: Tab = .input
    private let dataStore = EventDataStore.shared

    enum Tab: String, CaseIterable {
        case input = "행사 입력"
        case calendar = "캘린더"
        case checklist = "체크리스트"

        var icon: String {
            switch self {
            case .input: return "plus.circle.fill"
            case .calendar: return "calendar"
            case .checklist: return "checklist"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .onChange(of: dataStore.shouldNavigateToCalendar) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = .calendar
                dataStore.shouldNavigateToCalendar = false
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .input:
            NavigationStack {
                InputEventView()
                    .navigationTitle("행사 입력")
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .calendar:
            NavigationStack {
                EventCalendarView()
                    .navigationTitle("일정 캘린더")
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .checklist:
            NavigationStack {
                PriorityChecklistView()
                    .navigationTitle("체크리스트")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
