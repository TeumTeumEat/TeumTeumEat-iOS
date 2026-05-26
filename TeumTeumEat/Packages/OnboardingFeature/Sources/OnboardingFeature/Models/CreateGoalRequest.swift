//
//  CreateGoalRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

public struct CreateGoalRequest: Encodable {
    public let type: GoalType
    public let studyPeriod: String
    public let difficulty: Difficulty
    public let prompt: String?
    public let categoryId: Int?

    public init(type: GoalType, studyPeriod: String, difficulty: Difficulty, prompt: String?, categoryId: Int?) {
        self.type = type
        self.studyPeriod = studyPeriod
        self.difficulty = difficulty
        self.prompt = prompt
        self.categoryId = categoryId
    }

    public enum GoalType: String, Encodable {
        case category = "CATEGORY"
        case document = "DOCUMENT"
    }

    public enum Difficulty: String, Encodable {
        case easy = "EASY"
        case medium = "MEDIUM"
        case hard = "HARD"
    }
}
