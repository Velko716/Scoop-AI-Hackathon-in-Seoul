//
//  InputEventCom.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/21/25.
//

import SwiftUI

// MARK: - Progress Indicator

struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? Color.primary500 : Color.grayscaleWhite)
                    .frame(width: 60, height: 5)
            }
        }
    }
}

// MARK: - Form Text Field

struct FormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.pretendard(type: .semiBold, size: 15))
                .foregroundStyle(Color.grayscaleBlack)

            TextField(placeholder, text: $text)
                .font(.pretendard(type: .medium, size: 15))
                .foregroundStyle(Color.grayscaleBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(Color.grayscaleWhite)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.primary100, lineWidth: 1)
                )
        }
    }
}

// MARK: - Date Field Row

struct DateFieldRow: View {
    let label: String
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.pretendard(type: .semiBold, size: 15))
                .foregroundStyle(Color.grayscaleBlack)

            HStack(spacing: 0) {
                // 시작일: 오늘 이후만 선택 가능
                DatePickerButton(label: "시작일", date: $startDate, minimumDate: Date())
                    .onChange(of: startDate) { _, newStartDate in
                        // 시작일이 마감일보다 늦으면 마감일을 시작일로 맞춤
                        if newStartDate > endDate {
                            endDate = newStartDate
                        }
                    }

                Text("—")
                    .font(.pretendard(type: .medium, size: 15))
                    .foregroundStyle(Color.grayscale100)
                    .frame(width: 20)

                // 마감일: 시작일 이후만 선택 가능
                DatePickerButton(label: "마감일", date: $endDate, minimumDate: startDate)
            }
        }
    }
}

// MARK: - Date Picker Button

struct DatePickerButton: View {
    let label: String
    @Binding var date: Date
    let minimumDate: Date
    @State private var showDatePicker = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }

    var body: some View {
        Button {
            showDatePicker = true
        } label: {
            Text(dateFormatter.string(from: date))
                .font(.pretendard(type: .medium, size: 15))
                .foregroundStyle(Color.grayscale100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.grayscaleWhite)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.primary100, lineWidth: 1)
                )
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $date, label: label, minimumDate: minimumDate)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var date: Date
    let label: String
    let minimumDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                label,
                selection: $date,
                in: minimumDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Glass Back Button

struct GlassBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.grayscale100)
            }
        }
    }
}

// MARK: - Navigation Control Bar

struct NavigationControlBar: View {
    let onBack: () -> Void
    let onNext: () -> Void
    let isNextEnabled: Bool

    var body: some View {
        HStack {
            GlassBackButton(action: onBack)

            Spacer()

            Button(action: onNext) {
                Text("다음")
                    .font(.pretendard(type: .medium, size: 18))
                    .foregroundStyle(isNextEnabled ? Color.primary500 : Color.grayscale100)
            }
            .disabled(!isNextEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Progress Indicator") {
    VStack(spacing: 20) {
        ProgressIndicatorView(currentStep: 1, totalSteps: 4)
        ProgressIndicatorView(currentStep: 2, totalSteps: 4)
        ProgressIndicatorView(currentStep: 3, totalSteps: 4)
        ProgressIndicatorView(currentStep: 4, totalSteps: 4)
    }
    .padding()
    .background(Color.primary50)
}

#Preview("Form Text Field") {
    FormTextField(label: "행사명", placeholder: "예시) 쇼케이스", text: .constant(""))
        .padding()
        .background(Color.primary50)
}

#Preview("Date Field Row") {
    DateFieldRow(label: "행사 일정", startDate: .constant(Date()), endDate: .constant(Date()))
        .padding()
        .background(Color.primary50)
}

#Preview("Navigation Control Bar") {
    NavigationControlBar(onBack: {}, onNext: {}, isNextEnabled: true)
        .background(Color.primary50)
}
