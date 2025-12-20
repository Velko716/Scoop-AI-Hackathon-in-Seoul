//
//  IntegratedChecklistView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - Design Colors
private enum ChecklistColors {
    static let primaryStrong = Color(hex: "344BA5")      // 이벤트 제목
    static let labelNormal = Color(hex: "989EAD")        // 체크박스 아이콘
    static let labelAssistive = Color(hex: "1D1E23")     // 할 일 텍스트
    static let primaryAssistive = Color(hex: "7787C6")   // 상세보기, 완료 체크
    static let backgroundStrong = Color.white            // 배경
    static let shadow = Color(hex: "7787C6").opacity(0.2)
}

struct IntegratedChecklistView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var newTaskTitle: String = ""
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            checklistCard
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Subviews
extension IntegratedChecklistView {
    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이벤트 제목 헤더
            eventHeader

            // 태스크 리스트
            if viewModel.filteredTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }

            // 할 일 추가 필드
            quickAddField
        }
        .background(ChecklistColors.backgroundStrong)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: ChecklistColors.shadow, radius: 4, x: 0, y: 0)
    }

    private var eventHeader: some View {
        HStack {
            if let event = viewModel.selectedEvent {
                Text(event.title)
                    .font(.pretendard(type: .semiBold, size: 15))
                    .foregroundStyle(ChecklistColors.primaryStrong)
            } else {
                Text("할 일")
                    .font(.pretendard(type: .semiBold, size: 15))
                    .foregroundStyle(ChecklistColors.primaryStrong)
            }
            Spacer()
        }
        .padding(.horizontal, 19)
        .padding(.top, 15)
        .padding(.bottom, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundStyle(ChecklistColors.labelNormal)

            Text("할 일이 없습니다")
                .font(.pretendard(type: .medium, size: 14))
                .foregroundStyle(ChecklistColors.labelNormal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var taskListView: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                FigmaTaskRow(
                    task: task,
                    onToggle: { viewModel.toggleTask(task) },
                    onUpdate: { newTitle in
                        viewModel.updateTaskTitle(task, newTitle: newTitle)
                    }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 11, bottom: 2, trailing: 11))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.deleteTask(task)
                        }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(minHeight: CGFloat(viewModel.filteredTasks.count) * 44)
    }

    private var quickAddField: some View {
        HStack(spacing: 0) {
            // 체크박스 아이콘 영역
            Image(systemName: "plus.circle")
                .font(.system(size: 20))
                .foregroundStyle(ChecklistColors.labelNormal)
                .frame(width: 40, height: 40)

            TextField("새 할 일 추가", text: $newTaskTitle)
                .font(.pretendard(type: .medium, size: 15))
                .foregroundStyle(ChecklistColors.labelAssistive)
                .focused($isAddFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    addNewTask()
                }

            Spacer()

            if !newTaskTitle.isEmpty {
                Button(action: addNewTask) {
                    Text("추가")
                        .font(.pretendard(type: .medium, size: 15))
                        .foregroundStyle(ChecklistColors.primaryAssistive)
                }
                .padding(.trailing, 10)
            }
        }
        .padding(.horizontal, 11)
        .padding(.bottom, 8)
    }

    private func addNewTask() {
        viewModel.addTask(title: newTaskTitle)
        newTaskTitle = ""
        isAddFieldFocused = false
    }
}

// MARK: - FigmaTaskRow
struct FigmaTaskRow: View {
    let task: TodoTask
    let onToggle: () -> Void
    let onUpdate: (String) -> Void

    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // 체크박스
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? ChecklistColors.primaryAssistive : ChecklistColors.labelNormal)
            }
            .buttonStyle(.plain)
            .frame(width: 40, height: 40)
            .sensoryFeedback(.selection, trigger: task.isCompleted)

            // 할 일 텍스트
            if isEditing {
                TextField("할 일", text: $editedTitle)
                    .font(.pretendard(type: .semiBold, size: 15))
                    .foregroundStyle(ChecklistColors.labelAssistive)
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
                    .font(.pretendard(type: .semiBold, size: 15))
                    .foregroundStyle(task.isCompleted ? ChecklistColors.labelNormal : ChecklistColors.labelAssistive)
                    .strikethrough(task.isCompleted, color: ChecklistColors.labelNormal)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func startEditing() {
        guard !task.isCompleted else { return }
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
        .padding()
        .background(Color(.systemGroupedBackground))
}
