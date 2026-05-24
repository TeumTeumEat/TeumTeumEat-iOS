//
//  TTEQuizButton.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/19/25.
//

import SwiftUI

enum QuizAnswer: Equatable {
    case none       // 선택 안함 (default)
    case correct    // O 선택
    case wrong      // X 선택
    case choice(Int)
}

enum QuizButtonType {
    case correct    // O 버튼
    case wrong      // X 버튼
    
    var icon: String {
        switch self {
        case .correct: return "o_bold"
        case .wrong: return "x_bold"
        }
    }
    
    // 선택된 아이콘 (두꺼운 버전)
    var selectedIcon: String {
        switch self {
        case .correct: return "o_bold"
        case .wrong: return "x_bold"
        }
    }
    
    var selectedBackgroundColor: Color {
        switch self {
        case .correct: return .blue500
        case .wrong: return .red500
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .correct: return .blue100
        case .wrong: return .red100
        }
    }
}


struct TTEQuizButton: View {
    let type: QuizButtonType
    let currentAnswer: QuizAnswer
    let buttonWidth: CGFloat
    let buttonHeight: CGFloat
    let iconSize: CGFloat
    let action: () -> Void
    
    init(
        type: QuizButtonType,
        currentAnswer: QuizAnswer,
        buttonWidth: CGFloat = 120,
        buttonHeight: CGFloat = 80,
        iconSize: CGFloat = 40,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.currentAnswer = currentAnswer
        self.buttonWidth = buttonWidth
        self.buttonHeight = buttonHeight
        self.iconSize = iconSize
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(currentIcon)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(iconColor)
                .frame(width: buttonWidth, height: buttonHeight)

        }
        .frame(width: buttonWidth, height: buttonHeight)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .animation(.easeInOut(duration: 0.2), value: currentAnswer)
    }
    
    // 선택 여부 확인
    private var isSelected: Bool {
        switch (type, currentAnswer) {
        case (.correct, .correct), (.wrong, .wrong):
            return true
        default:
            return false
        }
    }
    
    private var isUnselected: Bool {
         return currentAnswer != .none && !isSelected
     }
    
    // 현재 보여줄 아이콘 (선택 상태에 따라)
    private var currentIcon: String {
        return isSelected ? type.selectedIcon : type.icon
    }
    
    // 배경 색상
    private var backgroundColor: Color {
        if isSelected {
            // 선택된 상태
            return type.selectedBackgroundColor
        } else if isUnselected {
            // 선택되지 않은 상태 (다른 버튼이 선택됨)
            return .gray100
        } else {
            // 기본 상태
            return type.backgroundColor
        }
    }
    
    // 아이콘 색상
    private var iconColor: Color {
            if isSelected {
                // 선택된 상태 - 흰색
                return .white
            } else if isUnselected {
                // 선택되지 않은 상태 - 회색
                return .gray500
            } else {
                // 기본 상태
                switch type {
                case .correct: return .blue500
                case .wrong: return .red500
                }
            }
        }
    
    // 테두리 색상
    private var borderColor: Color {
        return .clear
    }
    
    // 테두리 두께
    private var borderWidth: CGFloat {
            return 0
        }
}
