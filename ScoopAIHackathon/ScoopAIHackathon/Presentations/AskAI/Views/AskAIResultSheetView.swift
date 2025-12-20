//
//  AskAIResultSheetView.swift
//  ScoopAIHackathon
//
//  AI 일정 변경 결과 시트 - 성공 시 보여주는 화면
//

import SwiftUI

struct AskAIResultSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    let response: ScheduleModifyResponse
    var onConfirmSchedule: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Grabber & Header
            headerSection

            // Content Area
            contentSection
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Input Area
            inputSection
        }
        .background(Color.white)
        .onTapGesture {
            isInputFocused = false
        }
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

            // "일정 확인하러 가기" 버튼
            Button(action: {
                onConfirmSchedule?()
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

    // MARK: - Input Section
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("무엇이든 물어보세요!", text: $inputText)
                .font(.pretendard(type: .medium, size: 17))
                .focused($isInputFocused)

            // Send Button
            Button(action: {}) {
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
}

#Preview {
    AskAIResultSheetView(
        response: ScheduleModifyResponse(
            success: true,
            action: "add",
            message: "일정이 추가되었습니다",
            changes: nil,
            error: nil
        )
    )
}
