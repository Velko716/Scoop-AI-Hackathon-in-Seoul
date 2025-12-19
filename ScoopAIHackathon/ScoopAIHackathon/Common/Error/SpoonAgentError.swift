//
//  SpoonAgentError.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import Foundation

// MARK: - Errors
enum SpoonAgentError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)
    case agentNotReady

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 서버 URL입니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .serverError(let message):
            return "서버 오류: \(message)"
        case .decodingError(let error):
            return "응답 파싱 오류: \(error.localizedDescription)"
        case .agentNotReady:
            return "에이전트가 준비되지 않았습니다."
        }
    }
}
