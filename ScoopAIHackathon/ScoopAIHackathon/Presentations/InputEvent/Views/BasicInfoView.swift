//
//  BasicInfoView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// Step 1: 기본 정보 입력 화면
struct BasicInfoView: View {

    // MARK: - Properties

    @Bindable var viewModel: InputEventViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.primary50
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    GlassBackButton(action: onBack)
                    
                    Spacer()

                    Button(action: onNext) {
                        Text("다음")
                            .font(.pretendard(type: .medium, size: 18))
                            .foregroundStyle(viewModel.isStep1Valid ? Color.primary500 : Color.grayscale100)
                    }
                    .disabled(!viewModel.isStep1Valid)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Progress Indicator (Step 1)
                ProgressIndicatorView(currentStep: 1, totalSteps: 4)
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
            }
        }
    }
}

// MARK: - View Components

private extension BasicInfoView {

    var formFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 행사명
            FormTextField(
                label: "행사명",
                placeholder: "예시) 쇼케이스",
                text: $viewModel.eventName
            )

            // 행사 일정
            DateFieldRow(
                label: "행사 일정",
                startDate: $viewModel.startDate,
                endDate: $viewModel.endDate
            )

            // 행사 장소
            FormTextField(
                label: "행사 장소",
                placeholder: "예시) 신논현 주변",
                text: $viewModel.eventLocation
            )

            // 행사 예산
            FormTextField(
                label: "행사 예산",
                placeholder: "예시) 1000만원",
                text: $viewModel.budget
            )
        }
    }
}

// MARK: - Preview

#Preview {
    BasicInfoView(
        viewModel: InputEventViewModel(),
        onNext: {},
        onBack: {}
    )
}
