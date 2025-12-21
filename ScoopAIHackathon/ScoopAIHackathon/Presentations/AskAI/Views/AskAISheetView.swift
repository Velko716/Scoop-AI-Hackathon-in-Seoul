//
//  AskAISheetView.swift
//  ScoopAIHackathon
//
//  Ask AI 시트 뷰 - 키보드 올라갔을때/내려갔을때 대응
//

import SwiftUI

// MARK: - Ask AI Sheet View
struct AskAISheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool

    private let agentService = SpoonAgentService.shared
    var existingEvents: [CalendarEvent] = []
    var onConfirmSchedule: (([ScheduleChangeItem]) -> Void)?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Grabber & Header
                headerSection

                // Content
                contentSection
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Error Message
                if let message = errorMessage {
                    errorBanner(message: message)
                }

                // Input Area
                inputSection
            }
            .background(Color.white)
            .onTapGesture {
                isInputFocused = false
            }

            // Loading Overlay
            if isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("AI가 생각하는 중...")
                    .font(.pretendard(type: .medium, size: 16))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
    }

    // MARK: - Error Banner
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.pretendard(type: .medium, size: 14))
                .foregroundStyle(Color("GrayscaleBlack"))
                .lineLimit(2)

            Spacer()

            Button(action: { errorMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("Grayscale300"))
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Grabber
            RoundedRectangle(cornerRadius: 100)
                .fill(Color("Grayscale50"))
                .frame(width: 45, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 11)

            // Title Bar with Close Button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("Grayscale100"))
                        .frame(width: 44, height: 44)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // AI Icon
            Image("ChatBotColorIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .padding(.top, 110)

            // Title
            Text("일정을 변경해 드릴게요")
                .font(.pretendard(type: .semiBold, size: 20))
                .foregroundStyle(Color("GrayscaleBlack"))
                .tracking(-0.43)

            // 예시 텍스트
            VStack(alignment: .leading, spacing: 8) {
                Text("예: \"25일에 회의 추가해줘\"")
                    .font(.pretendard(type: .medium, size: 14))
                    .foregroundStyle(Color("Grayscale300"))
                Text("예: \"내일 미팅 취소해줘\"")
                    .font(.pretendard(type: .medium, size: 14))
                    .foregroundStyle(Color("Grayscale300"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Input Section (iOS 26 Liquid Glass)
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("무엇이든 물어보세요!", text: $inputText)
                .font(.pretendard(type: .medium, size: 17))
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }

            // Send Button
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        inputText.isEmpty
                        ? Color("Grayscale100")
                        : Color("Primary500")
                    )
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Actions
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        inputText = ""
        isInputFocused = false

        Task {
            await requestScheduleModify(message: trimmedText)
        }
    }

    private func requestScheduleModify(message: String) async {
        isLoading = true
        errorMessage = nil

        let result = await agentService.modifySchedule(message: message)

        await MainActor.run {
            isLoading = false

            switch result {
            case .success(let response):
                // 일정 변경 → 바로 확인 화면으로 이동
                if let changes = response.changes, !changes.isEmpty {
                    onConfirmSchedule?(changes)
                } else {
                    errorMessage = response.message ?? "일정 변경 정보를 찾을 수 없습니다."
                }

            case .failure(let error):
                errorMessage = "오류: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview
#Preview("키보드 내려갔을 때") {
    AskAISheetView()
        .presentationDetents([.large])
}

#Preview("시트로 표시") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            AskAISheetView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
}
