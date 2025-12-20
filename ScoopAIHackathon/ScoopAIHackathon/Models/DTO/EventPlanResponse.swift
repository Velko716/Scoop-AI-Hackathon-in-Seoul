//
//  EventPlanResponse.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import Foundation

// MARK: - Main Response
struct EventPlanResponse: Codable {
    let eventSummary: EventSummary
    let schedules: [Schedule]
    let dailyChecklists: [DailyChecklist]
}

// MARK: - Event Summary
struct EventSummary: Codable {
    let name: String
    let period: String
    let totalDays: Int
    let prepDays: Int
}

// MARK: - Schedule
struct Schedule: Codable, Identifiable {
    let id: String
    let date: String
    let startTime: String
    let endTime: String
    let title: String
    let description: String
    let phase: Phase
    let category: Category
    let location: String
}

// MARK: - Daily Checklist
struct DailyChecklist: Codable, Identifiable {
    var id: String { date }
    let date: String
    let dDay: String
    let tasksByCategory: TasksByCategory
}

// MARK: - Tasks By Category
struct TasksByCategory: Codable {
    let planning: [ChecklistTask]
    let finance: [ChecklistTask]
    let facilities: [ChecklistTask]
    let promotion: [ChecklistTask]
    let operations: [ChecklistTask]
}

// MARK: - Checklist Task
struct ChecklistTask: Codable, Identifiable {
    let id: String
    let task: String
    let priority: Priority
    let estimatedTime: String
}

