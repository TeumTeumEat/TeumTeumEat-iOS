//
//  UpdateUserNameRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

public struct UpdateUserNameRequest: Encodable {
    public let name: String
    public init(name: String) { self.name = name }
}

public struct UserNameData: Codable, Equatable {
    public let name: String
}

public struct CommuteInfoData: Codable, Equatable {
    public let startTime: String  // "08:00:00" 형식
    public let endTime: String    // "18:00:00" 형식
    public let usageTime: Int     // 분 단위
}
