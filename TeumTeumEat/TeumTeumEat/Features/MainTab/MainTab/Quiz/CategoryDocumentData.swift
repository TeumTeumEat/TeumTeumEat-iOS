//
//  CategoryDocumentData.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import Foundation

struct CategoryDocumentData: Codable, Equatable {
    let documentId: Int
    let content: String
    let hasSolvedToday: Bool
    let isFirstTime: Bool
    let createdAt: String
}

struct PDFSummaryData: Codable, Equatable {
    let documentId: Int
    let fileName: String
    let fileKey: String
    let summary: String
    let status: String  // "COMPLETED", "PROCESSING" 등
    let hasSolvedToday: Bool
    let isFirstTime: Bool
    let createdAt: String
}
