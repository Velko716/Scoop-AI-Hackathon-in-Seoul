//
//  PriorityChecklistView.swift
//  ScoopAIHackathon
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

// MARK: - Event Info Model
struct EventInfo: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String
}

// MARK: - Mock Event Data
extension EventInfo {
    static let mockEventData: [EventInfo] = [
        EventInfo(label: "행사명", value: "Apple Developer Academy 송년 네트워킹 파티", icon: "star.fill"),
        EventInfo(label: "행사 일정", value: "2024년 12월 28일 (토) 18:00 - 22:00", icon: "calendar"),
        EventInfo(label: "행사 장소", value: "서울특별시 강남구 테헤란로 521 파르나스타워 42층", icon: "mappin.and.ellipse"),
        EventInfo(label: "행사 예산", value: "5,000,000원", icon: "wonsign.circle"),
        EventInfo(label: "행사 대상", value: "Apple Developer Academy @POSTECH 러너 및 졸업생", icon: "person.2.fill"),
        EventInfo(label: "행사 인원", value: "약 150명 (러너 100명, 졸업생 50명)", icon: "person.3.fill"),
        EventInfo(label: "행사 비품", value: "음향장비, 빔프로젝터, 명찰, 현수막, 포토존 소품", icon: "shippingbox.fill"),
        EventInfo(label: "행사 종류", value: "네트워킹 파티 / 송년회", icon: "sparkles"),
        EventInfo(label: "행사 취지", value: "한 해를 마무리하며 러너들 간의 친목 도모 및 졸업생과의 네트워킹 기회 제공", icon: "lightbulb.fill"),
        EventInfo(label: "행사 내용", value: "개회식, 올해의 프로젝트 시상, 네트워킹 타임, 경품 추첨, 포토타임", icon: "list.bullet.clipboard")
    ]
}

struct PriorityChecklistView: View {
    @State private var viewModel = ChecklistViewModel()

    // Mock 행사 정보
    let eventInfo: [EventInfo] = EventInfo.mockEventData

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
            // 행사 정보 섹션
            Section {
                ForEach(eventInfo) { info in
                    eventInfoRow(for: info)
                }
            } header: {
                Text("행사 정보")
                    .font(.pretendard(type: .semiBold, size: 13))
                    .foregroundStyle(.secondary)
            }

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

    // MARK: - Event Info Row
    private func eventInfoRow(for info: EventInfo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: info.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(info.label)
                    .font(.pretendard(type: .semiBold, size: 13))
                    .foregroundStyle(.secondary)

                Text(info.value)
                    .font(.pretendard(type: .medium, size: 15))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
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
