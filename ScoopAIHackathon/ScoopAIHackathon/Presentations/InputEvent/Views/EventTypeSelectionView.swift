//
//  EventTypeSelectionView.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

/// Step 3: 행사 종류 선택 화면
struct EventTypeSelectionView: View {

    // MARK: - Properties

    @Bindable var viewModel: InputEventViewModel
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var showCustomTypeAlert = false
    @State private var customTypeName = ""
    @State private var customTypes: [EventType] = []

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.primary50
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Control
                NavigationControlBar(
                    onBack: onBack,
                    onNext: onNext,
                    isNextEnabled: true
                )

                // Progress Indicator (Step 3)
                ProgressIndicatorView(currentStep: 3, totalSteps: 4)
                    .padding(.top, 8)

                // Main Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("행사 종류를 선택해주세요")
                            .font(.pretendard(type: .semiBold, size: 24))
                            .foregroundStyle(Color.grayscaleBlack)
                            .padding(.top, 24)

                        // Event Type Grid
                        eventTypeGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("카테고리 추가", isPresented: $showCustomTypeAlert) {
            TextField("카테고리 이름", text: $customTypeName)
            Button("취소", role: .cancel) {
                customTypeName = ""
            }
            Button("추가") {
                if !customTypeName.isEmpty {
                    let newType = EventType.other(customTypeName)
                    customTypes.append(newType)
                    viewModel.formData.eventType = newType
                    customTypeName = ""
                }
            }
        } message: {
            Text("새로운 행사 종류를 입력해주세요")
        }
    }

    // MARK: - All Event Types

    private var allEventTypes: [EventType] {
        EventType.predefinedCases + customTypes
    }
}

// MARK: - View Components

private extension EventTypeSelectionView {

    var eventTypeGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            // All event types (predefined + custom)
            ForEach(allEventTypes, id: \.rawValue) { eventType in
                EventTypeGridButton(
                    title: eventType.displayName,
                    isSelected: viewModel.formData.eventType == eventType,
                    action: {
                        viewModel.formData.eventType = eventType
                    }
                )
            }

            // Add custom type button (always at the end)
            EventTypeGridButton(
                title: "+",
                isSelected: false,
                isAddButton: true,
                action: {
                    showCustomTypeAlert = true
                }
            )
        }
    }
}

// MARK: - Event Type Grid Button

struct EventTypeGridButton: View {
    let title: String
    let isSelected: Bool
    var isAddButton: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(type: .medium, size: 16))
                .foregroundStyle(isSelected ? Color.white : Color.grayscaleBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 107)
                .background(isSelected ? Color.primary500 : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.clear : Color.primary100, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    EventTypeSelectionView(
        viewModel: InputEventViewModel(),
        onBack: {},
        onNext: {}
    )
}
