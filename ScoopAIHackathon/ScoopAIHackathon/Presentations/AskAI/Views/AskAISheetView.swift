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
    @State private var resultMessage: String?
    @State private var showSuccess: Bool = false
    @State private var lastResponse: ScheduleModifyResponse?
    @FocusState private var isInputFocused: Bool

    private let agentService = SpoonAgentService.shared
    var existingEvents: [CalendarEvent] = []

    var onScheduleChanged: ((ScheduleModifyResponse) -> Void)?
    var onConfirmSchedule: (([ScheduleChangeItem]) -> Void)?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Grabber & Header
                headerSection

                // Content Area - 성공 시 다른 화면 표시
                if showSuccess, let response = lastResponse {
                    successContentSection(response: response)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    contentSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // Error Message (에러일 때만 표시)
                if !showSuccess, let message = resultMessage {
                    resultBanner(message: message)
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

    // MARK: - Result Banner
    private func resultBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: showSuccess ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(showSuccess ? Color.green : Color("Primary500"))

            Text(message)
                .font(.pretendard(type: .medium, size: 14))
                .foregroundStyle(Color("GrayscaleBlack"))
                .lineLimit(2)

            Spacer()
        }
        .padding(12)
        .background(showSuccess ? Color.green.opacity(0.1) : Color("Primary50"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
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
            Text("무엇을 도와드릴까요?")
                .font(.pretendard(type: .semiBold, size: 20))
                .foregroundStyle(Color("GrayscaleBlack"))
                .tracking(-0.43)

            // Suggestion Texts (버튼 아님, 그냥 텍스트)
            VStack(alignment: .leading, spacing: 12) {
                SuggestionText(icon: "calendar", title: "일정 변경하기")
                SuggestionText(icon: "person.fill", title: "행동 추천하기")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Success Content Section
    private func successContentSection(response: ScheduleModifyResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // AI Icon
            Image("ChatBotColorIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .padding(.top, 60)

            // Success Message
            Text("변경된 일정을 반영해 전체 일정이 변경되었어요!")
                .font(.pretendard(type: .semiBold, size: 20))
                .foregroundStyle(Color("GrayscaleBlack"))
                .tracking(-0.43)

            // "일정 확인하러 가기" 버튼
            Button(action: {
                if let changes = response.changes {
                    onConfirmSchedule?(changes)
                }
            }) {
                Text("일정 확인하러 가기")
                    .font(.pretendard(type: .medium, size: 15))
                    .foregroundStyle(.white)
                    .tracking(-0.43)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Primary300"))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 16)
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
        resultMessage = nil

        let result = await agentService.modifySchedule(message: message)

        await MainActor.run {
            isLoading = false

            switch result {
            case .success(let response):
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                    lastResponse = response
                    resultMessage = nil
                }
                onScheduleChanged?(response)

            case .failure(let error):
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = false
                    lastResponse = nil
                    resultMessage = "오류: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Reset State
    private func resetState() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccess = false
            lastResponse = nil
            resultMessage = nil
        }
    }
}

// MARK: - Suggestion Text Component (버튼 아님)
struct SuggestionText: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))

            Text(title)
                .font(.pretendard(type: .medium, size: 15))
                .tracking(-0.43)
        }
        .foregroundStyle(Color("Grayscale100"))
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
