//
//  CreateGoalRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct CreateGoalRequest: Encodable {
    let type: GoalType
    let studyPeriod: String
    let difficulty: Difficulty
    let prompt: String?
    let categoryId: Int?         
    
    enum GoalType: String, Encodable {
        case category = "CATEGORY"
        case document = "DOCUMENT"
    }
    
    enum Difficulty: String, Encodable {
        case easy = "EASY"
        case medium = "MEDIUM"
        case hard = "HARD"
    }
}
