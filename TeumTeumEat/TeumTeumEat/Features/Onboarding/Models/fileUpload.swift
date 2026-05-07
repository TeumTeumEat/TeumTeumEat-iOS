//
//  fileUpload.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct PresignedURLRequest: Encodable {
    let fileName: String
    let fileSize: Int64
}

struct PresignedURLData: Decodable {
    let presignedUrl: String
    let key: String
}

struct RegisterDocumentRequest: Encodable {
    let fileName: String
    let fileKey: String
}

struct RegisterDocumentData: Decodable, Equatable {
    let documentId: Int
}

struct GoalListData: Decodable {
    let goalResponses: [GoalResponse]
}

struct GoalResponse: Decodable, Equatable {
    let goalId: Int
    let type: String
    let startDate: String
    let endDate: String
    let studyPeriod: String
    let difficulty: String
    let prompt: String?
    let fileName: String?
    let category: CategoryInfo?
    let documentId: Int?
    let isExpired: Bool
    let isCompleted: Bool
}

struct CategoryInfo: Decodable, Equatable {
    let categoryId: Int
    let name: String
    let path: String
    let description: String?
}

enum SSEDocumentStatus: Equatable {
    case connected
    case pending
    case processing(remainMs: Int)
    case completed
    case failed(reason: SSEFailureReason)
}

enum SSEFailureReason: String, Equatable {
    case timeout = "TIMEOUT"
    case serverError = "SERVER_ERROR"
    case encryptedFile = "ENCRYPTED_FILE"

    var userMessage: String {
        switch self {
        case .timeout:
            return "네트워크가 불안정하거나 처리가 지연되고 있습니다. 잠시 후 다시 시도해주세요."
        case .serverError:
            return "서비스 점검 중이거나 일시적인 오류가 발생했습니다. 나중에 다시 이용해주세요."
        case .encryptedFile:
            return "암호화된 파일은 읽을 수 없습니다. 암호를 해제 후 업로드해주세요."
        }
    }
}
