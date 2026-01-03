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

struct GoalResponse: Decodable, Equatable {
    let goalId: Int
    let type: String              // "CATEGORY" or "DOCUMENT"
    let startDate: String          // "2025-12-31"
    let endDate: String            // "2026-01-28"
    let studyPeriod: String        // "4주"
    let difficulty: String         // "EASY", "MEDIUM", "HARD"
    let prompt: String?            // DOCUMENT 타입일 때 nullable
    let fileName: String?          // DOCUMENT 타입일 때만 존재
    let category: CategoryInfo?    // CATEGORY 타입일 때만 존재
    let documentId: Int?
}

struct CategoryInfo: Decodable, Equatable {
    let categoryId: Int
    let name: String
    let path: String
    let description: String?
}
