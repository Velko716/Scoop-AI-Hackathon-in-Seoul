//
//  InputEventView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

struct InputEventView: View {

    // MARK: - Properties

    @State private var viewModel = InputEventViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 필수 입력 섹션
                requiredSection

                // MARK: - 선택 입력 섹션
                optionalSection

                // MARK: - 제출 버튼
                submitSection
            }
            .navigationTitle("행사 기획")
            .navigationBarTitleDisplayMode(.large)
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
            .navigationDestination(isPresented: $viewModel.showResult) {
                if let response = viewModel.eventPlanResponse {
                    EventPlanResultView(response: response)
                }
            }
        }
    }
}

// MARK: - View Components

private extension InputEventView {

    // MARK: - Required Section

    var requiredSection: some View {
        Section {
            // 행사명
            TextField("행사명", text: $viewModel.eventName)

            // 행사기간
            DatePicker("시작일", selection: $viewModel.startDate, displayedComponents: .date)
            DatePicker("종료일", selection: $viewModel.endDate, displayedComponents: .date)

            // 행사대상
            TextField("행사대상", text: $viewModel.targetAudience)

            // 행사장소
            TextField("행사장소", text: $viewModel.eventLocation)

            // 인원
            HStack {
                Text("스태프")
                TextField("인원", text: $viewModel.staffCount)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("명")
            }

            HStack {
                Text("참가자")
                TextField("인원", text: $viewModel.participantCount)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("명")
            }

            // 행사개요
            TextField("행사개요", text: $viewModel.eventOverview, axis: .vertical)
                .lineLimit(2...4)

            // 행사내용
            TextField("행사내용", text: $viewModel.eventContent, axis: .vertical)
                .lineLimit(3...6)

        } header: {
            Text("필수 정보")
        } footer: {
            Text("모든 필수 항목을 입력해주세요")
        }
    }

    // MARK: - Optional Section

    var optionalSection: some View {
        Section {
            // 소요예산
            HStack {
                Text("소요예산")
                TextField("금액", text: $viewModel.budget)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("원")
            }

            // 필요비품
            TextField("필요비품", text: $viewModel.requiredEquipment, axis: .vertical)
                .lineLimit(2...4)

        } header: {
            Text("선택 정보")
        } footer: {
            Text("입력하지 않아도 계획을 생성할 수 있습니다")
        }
    }

    // MARK: - Submit Section

    var submitSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.generateEventPlan()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("행사 계획 생성")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!viewModel.isValidInput)

            Button(role: .destructive) {
                viewModel.resetForm()
            } label: {
                HStack {
                    Spacer()
                    Text("초기화")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Loading Overlay

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
