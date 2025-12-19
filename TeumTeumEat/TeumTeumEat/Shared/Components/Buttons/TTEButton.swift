//
//  CommonButton.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI

struct TTEButton: View {
    let title: String
    let size: ButtonSize
    let style: ButtonStyle
    let isEnabled: Bool
    
    // 커스텀 색상 (optional)
    let customBackgroundColor: Color?
    let customForegroundColor: Color?
    let customBorderColor: Color?
    let customBorderWidth: CGFloat?
    
    let action: () -> Void
    
    init(
        title: String,
        size: ButtonSize,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.size = size
        self.style = style
        self.isEnabled = isEnabled
        self.customBackgroundColor = backgroundColor
        self.customForegroundColor = foregroundColor
        self.customBorderColor = borderColor
        self.customBorderWidth = borderWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.typography.font)
                .foregroundColor(customForegroundColor ?? style.foregroundColor)
                .frame(width: size.width, height: size.height)
                .background(customBackgroundColor ?? style.backgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            customBorderColor ?? style.borderColor,
                            lineWidth: customBorderWidth ?? style.borderWidth
                        )
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}


