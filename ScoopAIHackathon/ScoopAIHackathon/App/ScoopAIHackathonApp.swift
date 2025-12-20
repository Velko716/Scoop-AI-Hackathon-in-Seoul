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
            switch appFlow {
            case .onboarding:
                OnboardingView(onComplete: {
                    withAnimation {
                        appFlow = .inputEvent
                    }
                })

            case .inputEvent:
                InputEventView(onComplete: {
                    withAnimation {
                        appFlow = .dashboard
                    }
                })

            case .dashboard:
                DashboardWrapperView()
            }
        }
    }
}

// MARK: - App Flow State

enum AppFlow {
    case onboarding
    case inputEvent
    case dashboard
}

// MARK: - Dashboard Wrapper View

struct DashboardWrapperView: View {
    var body: some View {
        NavigationStack {
            DashboardMainView()
        }
    }
}
