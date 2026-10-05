//
//  Quiz.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import Foundation

// MARK: - Models
struct Quiz: Equatable, Identifiable {
    let id: Int
    let question: String
    let type: QuizType
    let choices: [String]?  // 객관식일 때만
    
    enum QuizType {
        case ox
        case multipleChoice
    }
    
    init(from userQuiz: UserQuiz) {
        self.id = userQuiz.quizId
        self.question = userQuiz.question
        
        // type 변환
        if userQuiz.type == "OX" {
            self.type = .ox
            self.choices = nil
        } else {
            self.type = .multipleChoice
            self.choices = userQuiz.options.isEmpty ? nil : userQuiz.options
        }
    }
    
}
