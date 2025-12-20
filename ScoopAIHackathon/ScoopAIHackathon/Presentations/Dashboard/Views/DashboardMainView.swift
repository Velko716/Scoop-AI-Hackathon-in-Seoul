//
//  DashboardMainView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct DashboardMainView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                logoSection
                Divider()
                calendarSection
                Divider()
                checklistSection
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Logo Section
extension DashboardMainView {
    private var logoSection: some View {
        VStack(spacing: 8) {
            Text("Logo")
                .font(.pretendard(type: .bold, size: 32))
                .foregroundStyle(.primary)

            Text(viewModel.formattedCurrentDate)
                .font(.pretendard(type: .medium, size: 16))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
}

// MARK: - Calendar Section
extension DashboardMainView {
    private var calendarSection: some View {
        VStack(spacing: 0) {
            DashboardSectionHeader(
                title: "캘린더",
                isExpanded: viewModel.isCalendarExpanded,
                onToggle: viewModel.toggleCalendarSection
            )

            if viewModel.isCalendarExpanded {
                DashboardCalendarView(viewModel: viewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Checklist Section
extension DashboardMainView {
    private var checklistSection: some View {
        VStack(spacing: 0) {
            DashboardSectionHeader(
                title: "체크리스트",
                isExpanded: viewModel.isChecklistExpanded,
                onToggle: viewModel.toggleChecklistSection
            )

            if viewModel.isChecklistExpanded {
                IntegratedChecklistView(viewModel: viewModel)
                    .frame(minHeight: 300)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    DashboardMainView()
}
