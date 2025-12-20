//
//  EventType.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - 행사 종류 (페이지 4)
enum EventType: Codable, Equatable {
    case festival           // 축제
    case hackathon          // 해커톤
    case conference         // 컨퍼런스
    case fair               // 박람회
    case seminar            // 세미나
    case other(String)      // 기타 (사용자 직접 입력)

    // MARK: - Display Name
    var displayName: String {
        switch self {
        case .festival: return "축제"
        case .hackathon: return "해커톤"
        case .conference: return "컨퍼런스"
        case .fair: return "박람회"
        case .seminar: return "세미나"
        case .other(let name): return name
        }
    }

    // MARK: - Description (행사 종류별 특성)
    var description: String {
        switch self {
        case .festival:
            return "음악, 음식, 문화 등 다양한 활동이 포함된 대규모 행사"
        case .hackathon:
            return "제한된 시간 내 집중적으로 아이디어를 구현하는 개발 행사"
        case .conference:
            return "발표와 네트워킹 중심의 전문가 모임"
        case .fair:
            return "제품, 서비스, 기술 등을 전시하고 홍보하는 박람회 행사"
        case .seminar:
            return "특정 주제에 대한 강의 및 토론 중심 행사"
        case .other(let name):
            return "\(name) 형태의 사용자 정의 행사"
        }
    }

    // MARK: - Raw Value (서버 전송용)
    var rawValue: String {
        switch self {
        case .festival: return "festival"
        case .hackathon: return "hackathon"
        case .conference: return "conference"
        case .fair: return "fair"
        case .seminar: return "seminar"
        case .other(let name): return "other:\(name)"
        }
    }

    // MARK: - Predefined Cases (UI에서 선택 가능한 기본 옵션들)
    static var predefinedCases: [EventType] {
        [.festival, .hackathon, .conference, .fair, .seminar]
    }

    // MARK: - Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        switch value {
        case "festival": self = .festival
        case "hackathon": self = .hackathon
        case "conference": self = .conference
        case "fair": self = .fair
        case "seminar": self = .seminar
        default:
            // "other:커스텀이름" 형식 또는 그냥 문자열
            if value.hasPrefix("other:") {
                let customName = String(value.dropFirst(6))
                self = .other(customName)
            } else {
                self = .other(value)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
