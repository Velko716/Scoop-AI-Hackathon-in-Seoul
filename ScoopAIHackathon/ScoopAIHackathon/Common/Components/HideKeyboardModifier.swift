//
//  HideKeyboardModifier.swift
//  ScoopAIHackathon
//
//  배경 터치 시 키보드를 숨기는 ViewModifier
//

import SwiftUI

// MARK: - Hide Keyboard Modifier

struct HideKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                hideKeyboard()
            }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - View Extension

extension View {
    /// 배경 터치 시 키보드를 숨기는 modifier
    func hideKeyboardOnTap() -> some View {
        modifier(HideKeyboardModifier())
    }
}

// MARK: - Global Helper

/// 어디서든 키보드를 숨길 수 있는 전역 함수
func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
