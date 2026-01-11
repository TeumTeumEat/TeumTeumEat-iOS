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
        iconTint: Color? = nil,
        borderColor: Color? = nil,
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
    
    private var iconColor: Color {
        if isSelected {
            return customIconTint ?? .blue500
        } else {
            return customIconTint ?? .gray300
        }
    }
    
    private var textColor: Color {
        isSelected ? .blue500 : .gray600
    }
    
    private var borderColor: Color {
        if isSelected {
            return customSelectedBorderColor ?? .blue500
        } else {
            return customBorderColor ?? .gray300
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // 아이콘
                icon
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(iconColor)
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 0) {
                    // 타이틀
                    Text(title)
                        .stSemibold20()
                        .foregroundColor(textColor)
                        .padding(.bottom, 4)
                    
                    // 서브타이틀
                    Text(subtitle)
                        .bdMedium14()
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .background(Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
        }   
    }
}
