//
//  Font.swift
//  ScoopAIHackathon
//
//  Created by 김진혁 on 12/19/25.
//

import SwiftUI
import UIKit

extension Font {
    enum Pretendard {
        case bold
        case semiBold
        case medium
        case regular
        
        var value: String {
            switch self {
            case .bold:
                return "Pretendard-Bold"
            case .semiBold:
                return "Pretendard-SemiBold"
            case .medium:
                return "Pretendard-Medium"
            case .regular:
                return "Pretendard-Regular"
            }
        }
    }
    /// pretendard 폰트 생성 함수
    static func pretendard(type: Pretendard, size: CGFloat) -> Font {
        return .custom(type.value, size: size)
    }
}

