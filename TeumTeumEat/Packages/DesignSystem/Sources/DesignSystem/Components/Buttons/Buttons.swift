//
//  Buttons.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI

public enum ButtonSize {
    case large // 300 x 60
    case largeFull
    case medium // 300 x 50
    case regular // 144 x 50
    case small // 87 x 50
    case grid // 154 x 60

    public var width: CGFloat? {
        switch self {
        case .large, .medium: return 320
        case .largeFull: return nil
        case .grid: return 154
        case .regular: return 144
        case .small: return 87
        }
    }
    
    public var height: CGFloat? {
        switch self {
        case .large, .grid: return 60
        case .largeFull: return 60
        case .medium: return 50
        case .regular: return 50
        case .small:return 50
        }
    }

    public func applyTypography(to text: Text) -> some View {
            switch self {
            case .large, .largeFull:
                return AnyView(text.btBold20_24())
            case .medium, .regular:
                return AnyView(text.stSemibold18())
            case .small:
                return AnyView(text.bdMedium16())
            case .grid:
                return AnyView(text.stSemibold20())
            }
        }
    
    public var typography: TypographyStyle {
        switch self {
        case .large, .largeFull:
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

public enum ButtonStyle {
    case primary
    case secondary

    // 텍스트 색상
    public func foregroundColor(isEnabled: Bool) -> Color {
        switch self {
        case .primary:
            return .white
        case .secondary:
            return isEnabled ? .blue500 : .gray600
        }
    }
    
    // 배경 색상
    public func backgroundColor(isEnabled: Bool) -> Color {
        switch self {
        case .primary:
            return isEnabled ? .blue500 : .gray600
        case .secondary:
            return .clear
        }
    }
    
    // 테두리 색상
    public func borderColor(isEnabled: Bool) -> Color {
        switch self {
        case .primary:
            return .clear
        case .secondary:
            return isEnabled ? .blue500 : .gray600
        }
    }
    
    // 테두리 두께
    public var borderWidth: CGFloat {
        switch self {
        case .primary:
            return 0
        case .secondary:
            return 2
        }
    }
}
