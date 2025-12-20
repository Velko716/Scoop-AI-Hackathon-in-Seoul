//
//  DashboardMainView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - Design Colors
private enum DashboardColors {
    static let backgroundNormal = Color(hex: "E8EAF5")    // Primary/50
    static let labelAssistive = Color(hex: "1D1E23")      // Grayscale/Black
    static let labelNormal = Color(hex: "6D758A")         // Grayscale/300
}

struct DashboardMainView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                logoSection
                calendarSection
                checklistSection
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .background(DashboardColors.backgroundNormal)
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
