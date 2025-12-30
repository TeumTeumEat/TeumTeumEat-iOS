//
//  fileUpload.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct PresignedURLRequest: Encodable {
    let fileName: String
}

struct PresignedURLData: Decodable {
    let presignedUrl: String
    let key: String
}

struct RegisterDocumentRequest: Encodable {
    let fileName: String
    let fileKey: String
}

struct GoalListData: Decodable {
    let goalResponses: [GoalResponse]
}

struct GoalResponse: Decodable {
    let goalId: Int
    let type: String              // "CATEGORY" or "DOCUMENT"
    let startDate: String          // "2025-12-30"
    let endDate: String            // "2025-12-30"
    let studyPeriod: String        // "1주"
    let difficulty: String         // "EASY", "MEDIUM", "HARD"
    let prompt: String?            // nullable
    let category: CategoryInfo?    // DOCUMENT 타입이면 nil
}

struct CategoryInfo: Decodable {
    let categoryId: Int
    let name: String
    let path: String
    let description: String?
}
