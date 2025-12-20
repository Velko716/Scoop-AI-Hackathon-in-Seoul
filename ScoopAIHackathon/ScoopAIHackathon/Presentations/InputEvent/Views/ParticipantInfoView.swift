//
//  ParticipantInfoView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// Step 2: 참가자 정보 입력 화면
struct ParticipantInfoView: View {

    // MARK: - Properties

    @Bindable var viewModel: InputEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.primary50
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Control
                NavigationControlBar(
                    onBack: onBack,
                    onNext: onNext,
                    isNextEnabled: isValidStep
                )

                // Progress Indicator (Step 2)
                ProgressIndicatorView(currentStep: 2, totalSteps: 4)
                    .padding(.top, 8)

                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("행사 종류를 선택해주세요")
                            .font(.pretendard(type: .semiBold, size: 24))
                            .foregroundStyle(Color.grayscaleBlack)
                            .padding(.top, 24)

                        // Form Fields
                        formFields
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Validation

    private var isValidStep: Bool {
        !viewModel.formData.participantInfo.targetAudience.isEmpty &&
        !viewModel.formData.participantInfo.participantCount.isEmpty
    }
}

// MARK: - View Components

private extension ParticipantInfoView {

    var formFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 행사 대상
            FormTextField(
                label: "행사 대상",
                placeholder: "예시)  IT 스타트업 예비 창업가",
                text: $viewModel.formData.participantInfo.targetAudience
            )

            // 행사 인원
            FormTextField(
                label: "행사 인원",
                placeholder: "예시) 100명",
                text: $viewModel.formData.participantInfo.participantCount
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ParticipantInfoView(
        viewModel: InputEventViewModel(),
        onBack: {},
        onNext: {}
    )
}
