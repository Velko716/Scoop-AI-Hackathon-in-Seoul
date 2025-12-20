//
//  TaskRowView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let onToggle: () -> Void
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            checkboxButton

            // 우선순위 배지
            priorityBadge

            // 태스크 제목
            taskTitle

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("탭하여 완료 상태 변경")
        .accessibilityAddTraits(task.isCompleted ? .isSelected : [])
    }

    // MARK: - Checkbox
    private var checkboxButton: some View {
        Button(action: onToggle) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(task.isCompleted ? .green : .gray)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: task.isCompleted)
    }

    // MARK: - Priority Badge
    private var priorityBadge: some View {
        Text(task.priority.label)
            .font(.pretendard(type: .semiBold, size: 10))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(task.priority.color.opacity(task.isCompleted ? 0.5 : 1.0))
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
    }

    // MARK: - Task Title
    private var taskTitle: some View {
        Text(task.title)
            .font(.pretendard(type: .medium, size: 16))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .strikethrough(task.isCompleted, color: .secondary)
            .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
    }

    // MARK: - Accessibility
    private var accessibilityLabel: String {
        let status = task.isCompleted ? "완료됨" : "미완료"
        let priority = task.priority.label
        return "\(task.title), \(priority) 우선순위, \(status)"
    }
}

#Preview {
    VStack(spacing: 0) {
        TaskRowView(
            task: TodoTask(title: "미완료 High 태스크", priority: .high),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "미완료 Medium 태스크", priority: .medium),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "미완료 Low 태스크", priority: .low),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "완료된 태스크", isCompleted: true, priority: .high),
            onToggle: {}
        )
    }
}
