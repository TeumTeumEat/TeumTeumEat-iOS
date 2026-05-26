//
//  UpdateCommuteInfoRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

public struct UpdateCommuteInfoRequest: Encodable {
    public let startTime: String
    public let endTime: String
    public let usageTime: Int
    public init(startTime: String, endTime: String, usageTime: Int) {
        self.startTime = startTime
        self.endTime = endTime
        self.usageTime = usageTime
    }
}
