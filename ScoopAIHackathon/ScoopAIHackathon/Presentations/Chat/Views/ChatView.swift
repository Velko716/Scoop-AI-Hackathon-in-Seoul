//
//  ChatView.swift
//  ScoopAIHackathon
//
//  SpoonOS 에이전트와 채팅하는 뷰
//

import SwiftUI

// MARK: - Chat View
struct ChatView: View {
    @State private var agentService = SpoonAgentService.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isConnected: Bool = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 연결 상태 배너
                connectionBanner

                // 채팅 메시지 목록
                messageList

                // 입력 영역
                inputArea
            }
            .navigationTitle("SpoonOS Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: reconnect) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await checkConnection()
        }
    }

    // MARK: - Subviews

    private var connectionBanner: some View {
        Group {
            if !isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("서버에 연결되지 않음")
                    Spacer()
                    Button("재연결") {
                        Task { await checkConnection() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if agentService.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("생각하는 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onTapGesture {
                hideKeyboard()
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("메시지를 입력하세요", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .disabled(!isConnected || agentService.isLoading)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
            }
            .disabled(inputText.isEmpty || !isConnected || agentService.isLoading)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }

    // MARK: - Actions

    private func checkConnection() async {
        isConnected = await agentService.testConnection()

        if isConnected && messages.isEmpty {
            // 연결 성공 시 환영 메시지 추가
            messages.append(ChatMessage(
                content: "안녕하세요! SpoonOS 에이전트입니다. 무엇을 도와드릴까요?",
                isUser: false
            ))
        }
    }

    private func reconnect() {
        Task {
            await checkConnection()
        }
    }

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // 사용자 메시지 추가
        let userMessage = ChatMessage(content: trimmedText, isUser: true)
        messages.append(userMessage)

        // 입력 필드 초기화
        inputText = ""

        // 에이전트에게 메시지 전송
        Task {
            let result = await agentService.chat(message: trimmedText)

            switch result {
            case .success(let response):
                let agentMessage = ChatMessage(content: response, isUser: false)
                messages.append(agentMessage)

            case .failure(let error):
                let errorMessage = ChatMessage(
                    content: "오류가 발생했습니다: \(error.localizedDescription)",
                    isUser: false
                )
                messages.append(errorMessage)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
