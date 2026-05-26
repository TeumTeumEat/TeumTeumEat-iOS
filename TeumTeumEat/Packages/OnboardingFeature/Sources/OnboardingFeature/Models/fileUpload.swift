//
//  fileUpload.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

public struct PresignedURLRequest: Encodable {
    public let fileName: String
    public let fileSize: Int64
    public init(fileName: String, fileSize: Int64) {
        self.fileName = fileName
        self.fileSize = fileSize
    }
}

public struct PresignedURLData: Decodable {
    public let presignedUrl: String
    public let key: String
}

public struct RegisterDocumentRequest: Encodable {
    public let fileName: String
    public let fileKey: String
    public init(fileName: String, fileKey: String) {
        self.fileName = fileName
        self.fileKey = fileKey
    }
}

struct RegisterDocumentData: Decodable, Equatable {
    let documentId: Int
}

public struct GoalListData: Decodable {
    public let goalResponses: [GoalResponse]
}

public struct GoalResponse: Decodable, Equatable {
    public let goalId: Int
    public let type: String
    public let startDate: String
    public let endDate: String
    public let studyPeriod: String
    public let difficulty: String
    public let prompt: String?
    public let fileName: String?
    public let category: CategoryInfo?
    public let documentId: Int?
    public let isExpired: Bool
    public let isCompleted: Bool
}

public struct CategoryInfo: Decodable, Equatable {
    public let categoryId: Int
    public let name: String
    public let path: String
    public let description: String?
}

public enum SSEDocumentStatus: Equatable {
    case connected
    case pending
    case processing(remainMs: Int)
    case completed
    case failed(reason: SSEFailureReason)
}

public enum SSEFailureReason: String, Equatable {
    case timeout = "TIMEOUT"
    case serverError = "SERVER_ERROR"
    case encryptedFile = "ENCRYPTED_FILE"

    public var userMessage: String {
        switch self {
        case .timeout:
            return "네트워크가 불안정하거나 처리가 지연되고 있습니다. 잠시 후 다시 시도해주세요."
        case .serverError:
            return "서비스 점검 중이거나 일시적인 오류가 발생했습니다. 나중에 이용해주세요."
        case .encryptedFile:
            return "암호화된 파일은 읽을 수 없습니다. 암호를 해제 후 업로드해주세요."
        }
    }
}

public enum CategoryStreamEvent: Equatable {
    case connected
    case textChunk(String)
    case titleChunk(String)
    case completed
}
