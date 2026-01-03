//
//  UserAccountInfoData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/3/26.
//

import SwiftUI

struct UserAccountInfoData: Decodable {
    let socialProvider: String  // "KAKAO" or "APPLE"
    let email: String
}

