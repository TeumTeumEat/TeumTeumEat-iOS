//
//  UserNotificationSettingsData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/3/26.
//

import SwiftUI

struct UserNotificationSettingsData: Decodable {
    let pushEnabled: Bool
}

struct UpdateNotificationSettingRequest: Encodable {
    let pushEnabled: Bool
}
