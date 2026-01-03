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
