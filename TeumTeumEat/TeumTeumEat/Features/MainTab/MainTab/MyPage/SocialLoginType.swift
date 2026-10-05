//
//  SocialLoginType.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI

enum SocialLoginType: String, Equatable {
    case apple = "Apple"
    case kakao = "Kakao"
    
    var icon: String {
        switch self {
        case .apple:
            return "apple.logo"
        case .kakao:
            return "message.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .apple:
            return .black
        case .kakao:
            return .yellow
        }
    }
    
    // API 응답 매핑용 initializer
    init?(from apiString: String) {
        switch apiString.uppercased() {
        case "APPLE":
            self = .apple
        case "KAKAO":
            self = .kakao
        default:
            return nil
        }
    }
}
