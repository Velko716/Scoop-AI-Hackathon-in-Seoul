//
//  EventPlanResultView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

struct EventPlanResultView: View {

    // MARK: - Properties

    let response: EventPlanResponse

    // MARK: - Body

    var body: some View {
        ScrollView {
            Text(jsonString)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .navigationTitle("생성 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = jsonString
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(response),
              let string = String(data: data, encoding: .utf8) else {
            return "JSON 변환 실패"
        }

        return string
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventPlanResultView(response: EventPlanResponse(
            eventSummary: EventSummary(
                name: "테스트 행사",
                period: "2025-01-15 ~ 2025-01-17",
                totalDays: 3,
                prepDays: 14
            ),
            schedules: [],
            dailyChecklists: []
        ))
    }
}
