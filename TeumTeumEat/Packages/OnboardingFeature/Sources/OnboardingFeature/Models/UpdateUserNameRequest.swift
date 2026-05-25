//
//  UpdateUserNameRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct EmptyData: Decodable {}


struct UpdateUserNameRequest: Encodable {
    let name: String
}

struct UserNameData: Codable, Equatable {
    let name: String
}

struct CommuteInfoData: Codable, Equatable {
    let startTime: String  // "08:00:00" 형식
    let endTime: String    // "18:00:00" 형식
    let usageTime: Int     // 분 단위
}
