//
//  PlanEventModels.swift
//  ScoopAIHackathon
//
//  /plan-event API 요청에 사용되는 모델
//

import Foundation

// MARK: - Request Models

/// 일정 기획 요청에 사용되는 이벤트 정보 아이템
struct EventInfoItem: Codable {
    let label: String
    let value: String
}
