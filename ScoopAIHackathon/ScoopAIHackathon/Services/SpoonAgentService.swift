//
//  SpoonAgentService.swift
//  ScoopAIHackathon
//
//  SpoonOS 에이전트와 통신하는 서비스
//

import Foundation
import Combine

// MARK: - Service
/// SpoonOS 에이전트 서비스
@MainActor
@Observable
class SpoonAgentService {

    // MARK: - Properties

    /// 서버 기본 URL (로컬 개발 환경)
    /// 시뮬레이터: localhost 사용
    /// 실제 기기: Mac의 IP 주소 사용 (예: 192.168.x.x)
    private let baseURL: String

    /// 에이전트 준비 상태
    var isReady: Bool = false

    /// 로딩 상태
    var isLoading: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    // MARK: - Singleton

    static let shared = SpoonAgentService()

    // MARK: - Initialization

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
    }

    // MARK: - Public Methods

    /// 서버 상태 확인
    func checkServerStatus() async -> Result<ServerStatus, SpoonAgentError> {
        guard let url = URL(string: "\(baseURL)/") else {
            return .failure(.invalidURL)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let status = try JSONDecoder().decode(ServerStatus.self, from: data)
            return .success(status)
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }

    /// 헬스 체크
    func healthCheck() async -> Result<HealthCheck, SpoonAgentError> {
        guard let url = URL(string: "\(baseURL)/health") else {
            return .failure(.invalidURL)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let health = try JSONDecoder().decode(HealthCheck.self, from: data)

            await MainActor.run {
                self.isReady = health.agentReady
            }

            return .success(health)
        } catch let error as DecodingError {
            return .failure(.decodingError(error))
        } catch {
            return .failure(.networkError(error))
        }
    }

    /// 에이전트와 채팅
    func chat(message: String) async -> Result<String, SpoonAgentError> {
        guard let url = URL(string: "\(baseURL)/chat") else {
            return .failure(.invalidURL)
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        // 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = ChatRequest(message: message)

        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
        } catch {
            return .failure(.decodingError(error))
        }

        // 요청 전송
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // HTTP 상태 코드 확인
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                return .failure(.serverError("HTTP \(httpResponse.statusCode)"))
            }

            // 응답 파싱
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

            if chatResponse.success {
                return .success(chatResponse.response)
            } else {
                let errorMsg = chatResponse.error ?? "알 수 없는 오류"
                await MainActor.run {
                    self.errorMessage = errorMsg
                }
                return .failure(.serverError(errorMsg))
            }

        } catch let error as DecodingError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return .failure(.decodingError(error))
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return .failure(.networkError(error))
        }
    }

    /// 연결 테스트
    func testConnection() async -> Bool {
        let result = await healthCheck()
        switch result {
        case .success(let health):
            return health.agentReady
        case .failure:
            return false
        }
    }

    /// 행사 계획 생성
    func generateEventPlan(request: EventPlanRequest) async -> Result<EventPlanResponse, SpoonAgentError> {
        guard let url = URL(string: "\(baseURL)/chat") else {
            return .failure(.invalidURL)
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }

        // 프롬프트 생성
        let prompt = request.generatePrompt()

        // 요청 생성
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120 // AI 응답 대기 시간 증가

        let chatRequest = ChatRequest(message: prompt)

        do {
            urlRequest.httpBody = try JSONEncoder().encode(chatRequest)
        } catch {
            return .failure(.decodingError(error))
        }

        // 요청 전송
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            // HTTP 상태 코드 확인
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                return .failure(.serverError("HTTP \(httpResponse.statusCode)"))
            }

            // ChatResponse 파싱
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

            guard chatResponse.success else {
                let errorMsg = chatResponse.error ?? "알 수 없는 오류"
                await MainActor.run {
                    self.errorMessage = errorMsg
                }
                return .failure(.serverError(errorMsg))
            }

            // AI 응답에서 JSON 추출 및 파싱
            let eventPlanResponse = try parseEventPlanResponse(from: chatResponse.response)
            return .success(eventPlanResponse)

        } catch let error as SpoonAgentError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return .failure(error)
        } catch let error as DecodingError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return .failure(.decodingError(error))
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return .failure(.networkError(error))
        }
    }

    // MARK: - Private Methods

    /// AI 응답에서 JSON을 추출하여 EventPlanResponse로 파싱
    private func parseEventPlanResponse(from response: String) throws -> EventPlanResponse {
        // JSON 블록 추출 (```json ... ``` 또는 순수 JSON)
        var jsonString = response

        // ```json ... ``` 패턴 제거
        if let jsonStart = response.range(of: "```json"),
           let jsonEnd = response.range(of: "```", range: jsonStart.upperBound..<response.endIndex) {
            jsonString = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])
        } else if let jsonStart = response.range(of: "```"),
                  let jsonEnd = response.range(of: "```", range: jsonStart.upperBound..<response.endIndex) {
            jsonString = String(response[jsonStart.upperBound..<jsonEnd.lowerBound])
        }

        // { 로 시작하는 JSON 찾기
        if let braceStart = jsonString.firstIndex(of: "{"),
           let braceEnd = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[braceStart...braceEnd])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw SpoonAgentError.serverError("JSON 데이터 변환 실패")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(EventPlanResponse.self, from: jsonData)
        } catch {
            throw SpoonAgentError.decodingError(error)
        }
    }
}


