//
//  RegisterDeviceTokenRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import Foundation

public struct RegisterDeviceTokenRequest: Encodable {
    public let token: String
    public let deviceType: String
    public init(token: String, deviceType: String) {
        self.token = token
        self.deviceType = deviceType
    }
}
