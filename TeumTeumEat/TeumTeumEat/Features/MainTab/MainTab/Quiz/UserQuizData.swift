//
//  UserQuizData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import Foundation

struct UserQuizData: Codable, Equatable {
    let quizzes: [UserQuiz]
}

struct UserQuiz: Codable, Equatable, Identifiable {
    let quizId: Int
    let question: String
    let options: [String]
    let type: String  // "OX" or "MULTIPLE"
    
    var id: Int { quizId }
}

enum DocumentType: String {
    case category = "CATEGORY"
    case document = "DOCUMENT"
}
