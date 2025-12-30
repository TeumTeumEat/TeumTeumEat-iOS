//
//  TTECategoryButton.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/19/25.
//

import SwiftUI

struct TTECategoryButton: View {
    let icon: Image
    let title: String
    let subtitle: String
    let isSelected: Bool
    
    let width: CGFloat?
    let height: CGFloat
    
    let customIconTint: Color?
    let customBorderColor: Color?
    let customSelectedBorderColor: Color?
    
    let action: () -> Void
    
    init(
        icon: Image,
        title: String,
        subtitle: String,
        isSelected: Bool = false,
        width: CGFloat? = nil,
        height: CGFloat = 200,
        iconTint: Color? = ._7_A_7_A_7_A,
        borderColor: Color? = .C_8_C_8_C_8,
        selectedBorderColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.width = width
        self.height = height
        self.customIconTint = iconTint
        self.customBorderColor = borderColor
        self.customSelectedBorderColor = selectedBorderColor
        self.action = action
    }
    
    private var contentColor: Color {
        if isSelected {
            let selectedColor: Color = customSelectedBorderColor ?? ._2_B_8_FFF
            return selectedColor
        } else {
            let normalColor: Color = customIconTint ?? ._7_A_7_A_7_A
            return normalColor
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            let selectedColor: Color = customSelectedBorderColor ?? ._2_B_8_FFF
            return selectedColor
        } else {
            let normalColor: Color = customBorderColor ?? .C_8_C_8_C_8
            return normalColor
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // 아이콘
                icon
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(contentColor)
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 0) {
                    // 타이틀
                    Text(title)
                        .titleSemibold20()
                        .foregroundColor(contentColor)
                        .padding(.bottom, 4)
                    
                    // 서브타이틀
                    Text(subtitle)
                        .bodyMedium14()
                        .foregroundColor(contentColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .background(Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
    }
}
