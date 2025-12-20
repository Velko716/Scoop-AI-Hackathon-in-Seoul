//
//  OnboardingView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// 앱 첫 화면 - 온보딩/랜딩 페이지
struct OnboardingView: View {

    // MARK: - Properties

    var onComplete: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.primary50
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Main Title
                titleSection
                    .padding(.horizontal, 16)

                Spacer()

                // Start Button
                ActionButton(title: "시작하기") {
                    onComplete?()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - View Components

private extension OnboardingView {

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Headline
            VStack(alignment: .leading, spacing: 0) {
                Text("행사 준비가")
                    .font(.pretendard(type: .medium, size: 40))
                    .foregroundStyle(Color.grayscaleBlack)

                Text("쉬워지는 순간")
                    .font(.pretendard(type: .medium, size: 40))
                    .foregroundStyle(Color.grayscaleBlack)
            }

            // Logo
            Text("LOGO")
                .font(.pretendard(type: .semiBold, size: 40))
                .foregroundStyle(Color.grayscaleBlack)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
