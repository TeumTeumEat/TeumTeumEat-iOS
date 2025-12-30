//
//  Buttons.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI

enum ButtonSize {
    case large // 300 x 60
    case medium // 300 x 50
    case regular // 144 x 50
    case small // 87 x 50
    case grid // 154 x 60
    
    var width: CGFloat {
        switch self {
        case .large, .medium: return 320
        case .grid: return 154
        case .regular: return 144
        case .small: return 87
        }
    }
    
    var height: CGFloat {
        switch self {
        case .large, .grid: return 60
        case .medium: return 50
        case .regular: return 50
        case .small:return 50
        }
    }
    
    var typography: TypographyStyle {
        switch self {
        case .large:
            return .headBold20
        case .medium, .regular:
            return .titleSemibold18
        case .small:
            return .bodyMedium18
        case .grid:
            return .titleSemibold20
        }
    }
}

enum ButtonStyle {
    case primary
    case secondary
    
    // 텍스트 색상
    var foregroundColor: Color {
        switch self {
        case .primary:
            return .white                    // 배경 있을 때 흰색
        case .secondary:
            return ._2_B_8_FFF               // 테두리만 있을 때 파란색
        }
    }
    
    // 배경 색상
    var backgroundColor: Color {
        switch self {
        case .primary:
            return ._2_B_8_FFF              // 파란색 배경
        case .secondary:
            return .clear                   // 투명 배경
        }
    }
    
    // 테두리 색상
    var borderColor: Color {
        switch self {
        case .primary:
            return .clear                     // 테두리 없음
        case .secondary:
            return ._2_B_8_FFF                // 파란색 테두리
        }
    }
    
    // 테두리 두께
    var borderWidth: CGFloat {
        switch self {
        case .primary:
            return 0
        case .secondary:
            return 2
        }
    }
}
