//
//  SubmitQuizAnswerRequest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import Foundation

struct SubmitQuizAnswerRequest: Codable {
    let quizId: Int
    let userAnswer: String
}

struct SubmitQuizAnswerData: Codable, Equatable {
    let isCorrect: Bool
    let correctAnswer: String
    let explanation: String
}
