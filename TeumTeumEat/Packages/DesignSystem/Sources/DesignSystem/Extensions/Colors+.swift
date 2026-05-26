//
//  Colors+.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/19/25.
//

import SwiftUI

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - GrayScale
    static let gray100 = Color(hex: "#F7F7F7")
    static let gray200 = Color(hex: "#E2E3E4")
    static let gray300 = Color(hex: "#CCCED0")
    static let gray400 = Color(hex: "#B5B8BB")
    static let gray500 = Color(hex: "#9EA1A7")
    static let gray600 = Color(hex: "#787B82")
    static let gray700 = Color(hex: "#5F636A")
    static let gray800 = Color(hex: "#4B5055")
    static let gray900 = Color(hex: "#393B41")

    // MARK: - Primary Blue
    static let blue100 = Color(hex: "#EAF4FF")
    static let blue300 = Color(hex: "#89C1FF")
    static let blue500 = Color(hex: "#2B8FFF")
    static let blue700 = Color(hex: "#1875DD")

    // MARK: - Red
    static let red100 = Color(hex: "#FFF3F3")
    static let red200 = Color(hex: "#FF8181")
    static let red400 = Color(hex: "#FF5D5D")
    static let red500 = Color(hex: "#F03440")

    // MARK: - Legacy hex-named colors (xcassets 자동 생성 이름)
    static let _2_B_8_FFF = Color(hex: "#2B8FFF")
    static let _2690_FB = Color(hex: "#2690FB")
    static let _7_A_7_A_7_A = Color(hex: "#7A7A7A")
    static let _929292 = Color(hex: "#929292")
    static let _C_4_C_4_C_4 = Color(hex: "#C4C4C4")
    static let _C_8_C_8_C_8 = Color(hex: "#C8C8C8")
    static let _EDF_0_FF = Color(hex: "#EDF0FF")
}
