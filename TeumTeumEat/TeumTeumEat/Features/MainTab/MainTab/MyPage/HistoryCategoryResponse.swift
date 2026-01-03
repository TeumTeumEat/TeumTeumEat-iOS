//
//  HistoryCategoryResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import Foundation

struct HistoryCategoryResponse: Decodable {
    let categoryName: String
    let histories: [HistoryItemResponse]
}

struct HistoryItemResponse: Decodable {
    let id: Int
    let type: String
    let title: String
    let summarySnippet: String
    let lastStudiedAt: String
}

struct CalendarHistoryData: Decodable {
    let stampedDates: [String] 
    let totalStamps: Int
    let currentStreak: Int
}

struct QuizHistoryDetailData: Decodable {
    let createdAt: String
    let quizzes: [QuizDetailItem]
}

struct QuizDetailItem: Decodable {
    let quizId: Int
    let question: String
    let options: [String]
    let answer: String
    let type: String       
    let explanation: String
    let isCorrect: Bool
}
