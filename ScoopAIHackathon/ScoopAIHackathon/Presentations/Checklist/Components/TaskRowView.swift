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
        return "\(task.title), \(status)"
    }
}

#Preview {
    VStack(spacing: 0) {
        TaskRowView(
            task: TodoTask(title: "미완료 태스크 1", sortOrder: 0),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "미완료 태스크 2", sortOrder: 1),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "미완료 태스크 3", sortOrder: 2),
            onToggle: {}
        )
        Divider()
        TaskRowView(
            task: TodoTask(title: "완료된 태스크", isCompleted: true, sortOrder: 3),
            onToggle: {}
        )
    }
}
