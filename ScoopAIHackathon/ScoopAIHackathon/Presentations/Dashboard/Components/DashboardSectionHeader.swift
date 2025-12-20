//
//  DashboardSectionHeader.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(title)
                    .font(.pretendard(type: .semiBold, size: 18))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        DashboardSectionHeader(
            title: "캘린더",
            isExpanded: true,
            onToggle: {}
        )
        Divider()
        DashboardSectionHeader(
            title: "체크리스트",
            isExpanded: false,
            onToggle: {}
        )
    }
}
