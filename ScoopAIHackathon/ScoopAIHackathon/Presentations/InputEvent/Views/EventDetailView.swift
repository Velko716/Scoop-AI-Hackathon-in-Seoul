//
//  EventDetailView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// Step 4: 행사 상세 정보 입력 화면
struct EventDetailView: View {

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
                // Navigation Control (마지막 단계이므로 "완료" 버튼)
                HStack {
                    GlassBackButton(action: onBack)

                    Spacer()

                    Button(action: onNext) {
                        Text("완료")
                            .font(.pretendard(type: .medium, size: 18))
                            .foregroundStyle(isValidStep ? Color.primary500 : Color.grayscale100)
                    }
                    .disabled(!isValidStep)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Progress Indicator (Step 4)
                ProgressIndicatorView(currentStep: 4, totalSteps: 4)
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
        .navigationBarHidden(true)
    }

    // MARK: - Validation

    private var isValidStep: Bool {
        viewModel.isStep4Valid
    }
}

// MARK: - View Components

private extension EventDetailView {

    var formFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 행사 취지 (작은 필드 - 85px)
            FormTextEditor(
                label: "행사 취지",
                placeholder: "예시) 쇼케이스",
                text: $viewModel.formData.detailInfo.eventOverview,
                minHeight: 85
            )

            // 행사 내용 (큰 필드 - 276px)
            FormTextEditor(
                label: "행사 내용",
                placeholder: "예시) 쇼케이스",
                text: $viewModel.formData.detailInfo.eventContent,
                minHeight: 276
            )
        }
    }
}

// MARK: - Form Text Editor (Multi-line)

struct FormTextEditor: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.pretendard(type: .semiBold, size: 15))
                .foregroundStyle(Color.grayscaleBlack)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.pretendard(type: .medium, size: 15))
                        .foregroundStyle(Color.grayscale100)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $text)
                    .font(.pretendard(type: .medium, size: 15))
                    .foregroundStyle(Color.grayscaleBlack)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: minHeight)
            .background(Color.grayscaleWhite)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.primary100, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    EventDetailView(
        viewModel: InputEventViewModel(),
        onBack: {},
        onNext: {}
    )
}
