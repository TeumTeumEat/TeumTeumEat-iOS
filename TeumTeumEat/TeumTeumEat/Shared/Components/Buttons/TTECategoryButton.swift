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
    
    // 커스텀 옵션
    let customIconTint: Color?
    let customBorderColor: Color?
    let customSelectedBorderColor: Color?
    
    let action: () -> Void
    
    init(
        icon: Image,
        title: String,
        subtitle: String,
        isSelected: Bool = false,
        iconTint: Color? = ._7_A_7_A_7_A,
        borderColor: Color? = .C_8_C_8_C_8,
        selectedBorderColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.customIconTint = iconTint
        self.customBorderColor = borderColor
        self.customSelectedBorderColor = selectedBorderColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // 아이콘
                if let tintColor = customIconTint {
                    icon
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(tintColor)
                        .frame(width: 60, height: 60)
                } else {
                    icon
                        .resizable()
                        .frame(width: 60, height: 60)
                }
                
                VStack(spacing: 0) {
                    // 타이틀
                    Text(title)
                        .headBold20()
                        .foregroundColor(._7_A_7_A_7_A)
                        .padding(.bottom, 4)
                    
                    // 서브타이틀
                    Text(subtitle)
                        .bodyRegular16()
                        .foregroundColor(._7_A_7_A_7_A)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 142, height: 200)
            .background(Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? (customSelectedBorderColor ?? ._2_B_8_FFF)
                        : (customBorderColor ?? .C_8_C_8_C_8),
                        lineWidth: 2
                    )
            )
        }
    }
}
