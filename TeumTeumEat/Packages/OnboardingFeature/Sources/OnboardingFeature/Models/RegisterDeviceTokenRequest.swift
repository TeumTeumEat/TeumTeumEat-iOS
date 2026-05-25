//
//  RegisterDeviceTokenRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI

struct RegisterDeviceTokenRequest: Encodable {
    let token: String
    let deviceType: String  
}
