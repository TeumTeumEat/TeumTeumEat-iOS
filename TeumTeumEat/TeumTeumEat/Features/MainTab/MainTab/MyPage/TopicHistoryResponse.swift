//
//  TopicHistoryResponse.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI

struct TopicHistoryResponse: Codable, Equatable {
    let code: String
    let message: String
    let data: [TopicCategory]
}

struct TopicCategory: Codable, Equatable, Identifiable {
    var id: String { categoryName }
    let categoryName: String
    let histories: [TopicHistoryItem]
}

struct TopicHistoryItem: Codable, Equatable, Identifiable {
    let id: Int
    let type: HistoryType
    let title: String
    let summarySnippet: String
    let lastStudiedAt: String
    
    enum HistoryType: String, Codable {
        case document = "DOCUMENT"
        case quiz = "QUIZ"
        case unknown
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = HistoryType(rawValue: rawValue) ?? .unknown
        }
    }
}
