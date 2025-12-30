//
//  SocialLoginData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

typealias SocialLoginResponse = APIResponse<SocialLoginData>

struct SocialLoginRequest: Encodable {
    let idToken: String
    let authCode: String?
    let termsAgreed: Bool
    let name: String
}

struct SocialLoginData: Decodable {
    let accessToken: String
    let refreshToken: String
    let isOnboardingCompleted: Bool
}
