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

    /// 서버 URL 자동 결정
    /// - 시뮬레이터: localhost 사용
    /// - 실제 기기: ngrok 공개 URL 사용
    init(baseURL: String? = nil) {
        if let customURL = baseURL {
            self.baseURL = customURL
        } else {
            #if targetEnvironment(simulator)
            self.baseURL = "http://localhost:8000"
            #else
            // 실제 기기: ngrok 공개 URL (네트워크 상관없이 접속 가능)
            // ngrok 재시작 시 URL이 변경되므로 업데이트 필요
            self.baseURL = "https://23b6061cfa9b.ngrok-free.app"
            #endif
        }
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

    /// 행사 계획 생성 (/plan-event 엔드포인트 호출)
    func generateEventPlan(request: EventPlanRequest) async -> Result<EventPlanResponse, SpoonAgentError> {
        guard let url = URL(string: "\(baseURL)/plan-event") else {
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

        // EventPlanRequest를 EventInfoItem 배열로 변환
        let eventInfo = buildEventInfoItems(from: request)

        // API 요청 바디 생성
        struct PlanEventRequestBody: Codable {
            let event_info: [EventInfoItem]
        }
        let requestBody = PlanEventRequestBody(event_info: eventInfo)

        // 요청 생성
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120

        do {
            urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return .failure(.decodingError(error))
        }

        // 요청 전송
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                return .failure(.serverError("HTTP \(httpResponse.statusCode)"))
            }

            // 직접 EventPlanResponse로 디코딩
            let eventPlanResponse = try JSONDecoder().decode(EventPlanResponse.self, from: data)

            if !eventPlanResponse.success {
                let errorMsg = eventPlanResponse.error ?? "알 수 없는 오류"
                await MainActor.run {
                    self.errorMessage = errorMsg
                }
                return .failure(.serverError(errorMsg))
            }

            return .success(eventPlanResponse)

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

    /// EventPlanRequest를 EventInfoItem 배열로 변환
    private func buildEventInfoItems(from request: EventPlanRequest) -> [EventInfoItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")

        var items: [EventInfoItem] = []

        items.append(EventInfoItem(label: "행사명", value: request.eventName))
        items.append(EventInfoItem(label: "행사 시작일", value: dateFormatter.string(from: request.startDate)))
        items.append(EventInfoItem(label: "행사 마감일", value: dateFormatter.string(from: request.endDate)))
        items.append(EventInfoItem(label: "행사 장소", value: request.eventLocation))

        if let budget = request.budget {
            items.append(EventInfoItem(label: "행사 예산", value: "\(budget)원"))
        }

        items.append(EventInfoItem(label: "행사 대상", value: request.targetAudience))
        items.append(EventInfoItem(label: "행사 인원", value: "\(request.participantCount)명"))
        items.append(EventInfoItem(label: "행사 종류", value: request.eventType.displayName))
        items.append(EventInfoItem(label: "행사 취지", value: request.eventOverview))
        items.append(EventInfoItem(label: "행사 내용", value: request.eventContent))

        return items
    }
}


