//
//  ActionButton.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// Primary Action Button
/// 주요 액션에 사용되는 버튼 컴포넌트
struct ActionButton: View {

    // MARK: - Properties

    let title: String
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - Initialization

    init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(type: .medium, size: 16))
                .foregroundStyle(Color.grayscaleWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEnabled ? Color.primary500 : Color.grayscale100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ActionButton(title: "시작하기") {
            print("Tapped")
        }

        ActionButton(title: "비활성화", isEnabled: false) {
            print("Tapped")
        }
    }
    .padding()
    .background(Color.primary50)
}
