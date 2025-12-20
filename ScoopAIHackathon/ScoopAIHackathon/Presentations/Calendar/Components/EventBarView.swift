//
//  EventBarView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct EventBarView: View {
    let event: CalendarEvent
    let position: BarPosition
    let verticalIndex: Int

    private let barHeight: CGFloat = 18
    private let barSpacing: CGFloat = 2
    private let cornerRadius: CGFloat = 4

    var body: some View {
        HStack(spacing: 0) {
            if position == .start || position == .single {
                Text(event.title)
                    .font(.pretendard(type: .medium, size: 10))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
        .background(event.color.opacity(0.85))
        .clipShape(barShape)
    }

    private var barShape: some Shape {
        RoundedCornersShape(position: position, radius: cornerRadius)
    }

    /// 수직 오프셋 계산 (날짜 숫자 아래에 배치)
    var verticalOffset: CGFloat {
        CGFloat(verticalIndex) * (barHeight + barSpacing)
    }
}

// MARK: - Rounded Corners Shape
struct RoundedCornersShape: Shape {
    let position: BarPosition
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var corners: UIRectCorner = []

        switch position {
        case .start:
            corners = [.topLeft, .bottomLeft]
        case .end:
            corners = [.topRight, .bottomRight]
        case .single:
            corners = .allCorners
        case .middle:
            corners = []
        }

        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 20) {
        EventBarView(
            event: CalendarEvent(
                title: "Conference",
                startDate: Date(),
                endDate: Date(),
                color: .blue
            ),
            position: .single,
            verticalIndex: 0
        )

        EventBarView(
            event: CalendarEvent(
                title: "Workshop",
                startDate: Date(),
                endDate: Date(),
                color: .green
            ),
            position: .start,
            verticalIndex: 0
        )

        EventBarView(
            event: CalendarEvent(
                title: "Workshop",
                startDate: Date(),
                endDate: Date(),
                color: .green
            ),
            position: .middle,
            verticalIndex: 0
        )

        EventBarView(
            event: CalendarEvent(
                title: "Workshop",
                startDate: Date(),
                endDate: Date(),
                color: .green
            ),
            position: .end,
            verticalIndex: 0
        )
    }
    .padding()
}
