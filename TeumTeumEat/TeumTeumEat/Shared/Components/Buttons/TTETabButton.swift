//
//  TTETabButton.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/19/25.
//

import SwiftUI

enum TabButtonSize {
    case large      // 80x80, icon 50x50
    case small      // 50x50, icon 24x24
    
    var buttonSize: CGFloat {
        switch self {
        case .large: return 80
        case .small: return 50
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .large: return 50
        case .small: return 24
        }
    }
}

struct TTETabButton: View {
    let icon: Image
    let size: TabButtonSize
    let isSelected: Bool
    
    // 커스텀 색상
    let selectedBackgroundColor: Color?
    let unselectedBackgroundColor: Color?
    let selectedIconColor: Color?
    let unselectedIconColor: Color?
    
    let action: () -> Void
    
    init(
        icon: Image,
        size: TabButtonSize = .large,
        isSelected: Bool = false,
        selectedBackgroundColor: Color? = nil,
        unselectedBackgroundColor: Color? = nil,
        selectedIconColor: Color? = nil,
        unselectedIconColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.isSelected = isSelected
        self.selectedBackgroundColor = selectedBackgroundColor
        self.unselectedBackgroundColor = unselectedBackgroundColor
        self.selectedIconColor = selectedIconColor
        self.unselectedIconColor = unselectedIconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 원형 배경
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size.buttonSize, height: size.buttonSize)
                
                // 아이콘
                icon
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(iconColor)
                    .frame(width: size.iconSize, height: size.iconSize)
            }
        }
    }
    
    // 배경 색상
    private var backgroundColor: Color {
        if isSelected {
            return selectedBackgroundColor ?? ._2_B_8_FFF
        } else {
            return unselectedBackgroundColor ?? ._2690_FB
        }
    }
    
    // 아이콘 색상
    private var iconColor: Color {
        if isSelected {
            return selectedIconColor ?? .white
        } else {
            return unselectedIconColor ?? .white.opacity(0.6)
        }
    }
}
