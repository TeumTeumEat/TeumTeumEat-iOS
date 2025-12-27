//
//  SocialLoginData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

typealias SocialLoginResponse = APIResponse<SocialLoginData>

struct SocialLoginData: Decodable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool?
}
