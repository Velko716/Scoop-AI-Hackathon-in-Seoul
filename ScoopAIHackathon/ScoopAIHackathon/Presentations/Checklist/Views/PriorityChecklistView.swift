//
//  PriorityChecklistView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct PriorityChecklistView: View {
    @State private var viewModel = ChecklistViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 상단 진행률 헤더
            progressHeader

            Divider()

            // 태스크 리스트
            taskList
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("오늘의 할 일")
                    .font(.pretendard(type: .bold, size: 20))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(viewModel.progressPercentage)%")
                        .font(.pretendard(type: .bold, size: 14))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())

                    Text("(\(viewModel.progressText))")
                        .font(.pretendard(type: .medium, size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: viewModel.progress)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                .animation(.spring(duration: 0.4), value: viewModel.progress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    // MARK: - Task List
    private var taskList: some View {
        List {
            // 미완료 섹션
            if !viewModel.incompleteTasks.isEmpty {
                Section {
                    ForEach(viewModel.incompleteTasks) { task in
                        taskRow(for: task)
                    }
                } header: {
                    Text("진행 중")
                        .font(.pretendard(type: .semiBold, size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            // 완료 섹션
            if !viewModel.completedTasks.isEmpty {
                Section {
                    ForEach(viewModel.completedTasks) { task in
                        taskRow(for: task)
                    }
                } header: {
                    Text("완료됨")
                        .font(.pretendard(type: .semiBold, size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .animation(.spring(duration: 0.35, bounce: 0.2), value: viewModel.sortedTasks)
    }

    // MARK: - Task Row
    @ViewBuilder
    private func taskRow(for task: TodoTask) -> some View {
        TaskRowView(task: task) {
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                viewModel.toggleTask(task)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteTask(task)
                }
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .geometryGroup()
    }
}

#Preview {
    PriorityChecklistView()
}
