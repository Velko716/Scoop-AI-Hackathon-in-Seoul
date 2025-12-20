//
//  InputEventView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// 행사 정보 입력 메인 컨테이너
/// Step 1~4를 관리하고 네비게이션 처리
struct InputEventView: View {

    // MARK: - Properties

    @State private var viewModel = InputEventViewModel()
    @Environment(\.dismiss) private var dismiss

    /// AI 응답 완료 후 호출되는 콜백
    var onComplete: (() -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .basicInfo:
                    BasicInfoView(
                        viewModel: viewModel,
                        onNext: { viewModel.nextStep() },
                        onBack: { viewModel.previousStep() }
                    )

                case .participantInfo:
                    ParticipantInfoView(
                        viewModel: viewModel,
                        onBack: { viewModel.previousStep() },
                        onNext: { viewModel.nextStep() }
                    )

                case .eventType:
                    EventTypeSelectionView(
                        viewModel: viewModel,
                        onBack: { viewModel.previousStep() },
                        onNext: { viewModel.nextStep() }
                    )

                case .detailInfo:
                    EventDetailView(
                        viewModel: viewModel,
                        onBack: { viewModel.previousStep() },
                        onNext: { viewModel.nextStep() }
                    )
                }
            }
            .navigationBarHidden(true)
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.showResult) { _, showResult in
                if showResult {
                    onComplete?()
                }
            }
        }
    }
}

// MARK: - View Components

private extension InputEventView {

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("AI가 행사 계획을 생성하고 있습니다...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    InputEventView()
}
