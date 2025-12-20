//
//  ChecklistViewModel.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

@MainActor
@Observable
final class ChecklistViewModel {
    // MARK: - State
    private(set) var tasks: [TodoTask] = TodoTask.mockTasks

    // MARK: - Computed Properties

    /// 복합 정렬된 태스크 목록
    /// 1. 미완료 항목이 완료 항목보다 위에 위치
    /// 2. sortOrder 순으로 정렬
    var sortedTasks: [TodoTask] {
        tasks.sorted { lhs, rhs in
            // 1. 상태 우선: 미완료가 위로
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            // 2. sortOrder 순
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    /// 미완료 태스크 목록
    var incompleteTasks: [TodoTask] {
        sortedTasks.filter { !$0.isCompleted }
    }

    /// 완료된 태스크 목록
    var completedTasks: [TodoTask] {
        sortedTasks.filter { $0.isCompleted }
    }

    /// 전체 진행률 (0.0 ~ 1.0)
    var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }

    /// 완료된 태스크 수
    var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    /// 전체 태스크 수
    var totalCount: Int {
        tasks.count
    }

    /// 진행률 텍스트
    var progressText: String {
        "\(completedCount)/\(totalCount) 완료"
    }

    /// 진행률 퍼센트
    var progressPercentage: Int {
        Int(progress * 100)
    }

    // MARK: - Actions

    /// 태스크 완료 상태 토글
    func toggleTask(_ task: TodoTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
    }

    /// ID로 태스크 완료 상태 토글
    func toggleTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
    }

    /// 새 태스크 추가
    func addTask(title: String) {
        let maxOrder = tasks.map(\.sortOrder).max() ?? -1
        let newTask = TodoTask(title: title, sortOrder: maxOrder + 1)
        tasks.append(newTask)
    }

    /// 태스크 삭제
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
    }

    /// ID로 태스크 삭제
    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }
}
