//
//  IntegratedChecklistView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct IntegratedChecklistView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var newTaskTitle: String = ""
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            if viewModel.filteredTasks.isEmpty {
                emptyStateView
            } else {
                taskList
            }

            quickAddField
        }
    }
}

// MARK: - Subviews
extension IntegratedChecklistView {
    private var progressHeader: some View {
        HStack {
            if let event = viewModel.selectedEvent {
                Text(event.title)
                    .font(.pretendard(type: .medium, size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.progressText)
                .font(.pretendard(type: .medium, size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("할 일이 없습니다")
                .font(.pretendard(type: .medium, size: 16))
                .foregroundStyle(.secondary)

            Text("아래에서 새 할 일을 추가하세요")
                .font(.pretendard(type: .regular, size: 14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                InlineTaskRow(
                    task: task,
                    onToggle: { viewModel.toggleTask(task) },
                    onUpdate: { newTitle in
                        viewModel.updateTaskTitle(task, newTitle: newTitle)
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let task = viewModel.filteredTasks[index]
                    viewModel.deleteTask(task)
                }
            }
            .onMove { source, destination in
                viewModel.moveTasks(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
    }

    private var quickAddField: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.blue)

            TextField("새 할 일 추가", text: $newTaskTitle)
                .font(.pretendard(type: .regular, size: 16))
                .focused($isAddFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    addNewTask()
                }

            if !newTaskTitle.isEmpty {
                Button(action: addNewTask) {
                    Text("추가")
                        .font(.pretendard(type: .semiBold, size: 14))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private func addNewTask() {
        viewModel.addTask(title: newTaskTitle)
        newTaskTitle = ""
        isAddFieldFocused = false
    }
}

// MARK: - InlineTaskRow
struct InlineTaskRow: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onUpdate: (String) -> Void

    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: task.isCompleted)

            if isEditing {
                TextField("할 일", text: $editedTitle)
                    .font(.pretendard(type: .regular, size: 16))
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        finishEditing()
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            finishEditing()
                        }
                    }
            } else {
                Text(task.title)
                    .font(.pretendard(type: .regular, size: 16))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func startEditing() {
        editedTitle = task.title
        isEditing = true
        isFocused = true
    }

    private func finishEditing() {
        if !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            onUpdate(editedTitle)
        }
        isEditing = false
    }
}

#Preview {
    IntegratedChecklistView(viewModel: DashboardViewModel())
}
