//
//  Buttons.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import Foundation

enum ButtonSize {
    case large // 300 x 60
    case medium // 300 x 50
    case regular // 144 x 50
    case small // 87 x 50
    
    var width: CGFloat {
        switch self {
        case .large, .medium: return 300
        case .regular: return 144
        case .small: return 87
        }
    }
    
    var height: CGFloat {
        switch self {
        case .large: return 60
        case .medium: return 50
        case .regular: return 50
        case .small:return 50
        }
    }
}

enum ButtonStyle {
    case primary
    case secondary
}

