//
//  UserQuizStatusData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI

struct UserQuizStatusData: Codable, Equatable {
    let hasSolvedToday: Bool
    let isFirstTime: Bool
    let hasCreatedToday: Bool
    let isQuizGuideSeen: Bool
    let availableQuizCount: Int
    let targetQuizSetCount: Int
    let completedQuizSetCount: Int
    let isCompleted: Bool
    let canIssueCoupon: Bool
}
