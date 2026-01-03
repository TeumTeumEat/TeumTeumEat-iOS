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
}
