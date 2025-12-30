//
//  UpdateCommuteInfoRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct UpdateCommuteInfoRequest: Encodable {
    let startTime: String
    let endTime: String
    let usageTime: Int     
}
