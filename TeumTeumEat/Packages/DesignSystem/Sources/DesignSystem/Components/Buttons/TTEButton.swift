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
    
    // 아이콘 관련 (optional)
    let icon: Image?
    let iconSize: CGFloat?
    let iconTextSpacing: CGFloat?
    let iconLeadingPadding: CGFloat?
    
    // 커스텀 색상 (optional)
    let customBackgroundColor: Color?
    let customForegroundColor: Color?
    let customBorderColor: Color?
    let customBorderWidth: CGFloat?
    let customIconTint: Color?
    
    let action: () -> Void
    
    init(
        title: String,
        size: ButtonSize,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        icon: Image? = nil,
        iconSize: CGFloat = 30,
        iconTextSpacing: CGFloat = 4,
        iconLeadingPadding: CGFloat = 22.5,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat? = nil,
        iconTint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.size = size
        self.style = style
        self.isEnabled = isEnabled
        self.icon = icon
        self.iconSize = iconSize
        self.iconTextSpacing = iconTextSpacing
        self.iconLeadingPadding = iconLeadingPadding
        self.customBackgroundColor = backgroundColor
        self.customForegroundColor = foregroundColor
        self.customBorderColor = borderColor
        self.customBorderWidth = borderWidth
        self.customIconTint = iconTint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let icon = icon {
                // 아이콘이 있을 때
                HStack(spacing: iconTextSpacing) {
                    if let tintColor = customIconTint {
                        // iconTint가 있으면 template 모드로 색상 적용
                        icon
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(tintColor)
                            .frame(width: iconSize ?? 30, height: iconSize ?? 30)
                    } else {
                        // iconTint가 nil이면 원본 색상 유지
                        icon
                            .resizable()
                            .frame(width: iconSize ?? 30, height: iconSize ?? 30)
                    }
                    
                    size.applyTypography(to: Text(title))
                        .foregroundColor(customForegroundColor ?? style.foregroundColor(isEnabled: isEnabled))
                    
                    Spacer()
                }
                .padding(.leading, iconLeadingPadding ?? 22.5)
                .frame(maxWidth: size.width == nil ? .infinity : size.width)
                .frame(height: size.height)
                .background(customBackgroundColor ?? style.backgroundColor(isEnabled: isEnabled))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            customBorderColor ?? style.borderColor(isEnabled: isEnabled),
                            lineWidth: customBorderWidth ?? style.borderWidth
                        )
                )
            } else {
                // 아이콘이 없을 때 (기존 버튼)
                size.applyTypography(to: Text(title))
                    .foregroundColor(customForegroundColor ?? style.foregroundColor(isEnabled: isEnabled))
                    .frame(maxWidth: size.width == nil ? .infinity : size.width)
                    .frame(height: size.height)
                    .background(customBackgroundColor ?? style.backgroundColor(isEnabled: isEnabled))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                customBorderColor ?? style.borderColor(isEnabled: isEnabled),
                                lineWidth: customBorderWidth ?? style.borderWidth
                            )
                    )
            }
        }
        .disabled(!isEnabled)
    }
}


