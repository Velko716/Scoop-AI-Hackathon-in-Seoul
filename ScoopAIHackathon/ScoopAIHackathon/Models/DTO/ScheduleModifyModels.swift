//
//  ScheduleModifyModels.swift
//  ScoopAIHackathon
//
//  일정 변경 API 요청/응답 모델
//

import Foundation

// MARK: - Request Models

/// 일정 변경 요청
struct ScheduleModifyRequest: Codable {
    let message: String
    let currentSchedules: [CurrentScheduleItem]?

    enum CodingKeys: String, CodingKey {
        case message
        case currentSchedules = "current_schedules"
    }
}

/// 현재 일정 항목
struct CurrentScheduleItem: Codable {
    let id: String?
    let title: String
    let date: String
    let startTime: String?
    let endTime: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

// MARK: - Response Models

/// 일정 변경 응답
struct ScheduleModifyResponse: Codable {
    let success: Bool
    let responseType: String?  // "schedule" 또는 "chat"
    let action: String?
    let message: String?
    let changes: [ScheduleChangeItem]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success
        case responseType = "response_type"
        case action
        case message
        case changes
        case error
    }

    /// 일정 변경 응답인지 확인
    var isScheduleResponse: Bool {
        responseType == "schedule"
    }

    /// 채팅 응답인지 확인
    var isChatResponse: Bool {
        responseType == "chat"
    }
}

/// 일정 변경 항목
struct ScheduleChangeItem: Codable, Identifiable {
    var id: String { scheduleId ?? UUID().uuidString }

    let type: String  // add, modify, delete
    let scheduleId: String?
    let title: String?
    let originalDate: String?
    let newDate: String?
    let startTime: String?
    let endTime: String?
    let color: String?

    enum CodingKeys: String, CodingKey {
        case type
        case scheduleId = "schedule_id"
        case title
        case originalDate = "original_date"
        case newDate = "new_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case color
    }
}
