//
//  CategoryAPIClient.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies

struct CategoryAPIClient {
    var fetchCategories: @Sendable () async throws -> [CategoryResponse]
}

extension CategoryAPIClient: DependencyKey {
    static let liveValue = CategoryAPIClient(
        fetchCategories: {
            
            let baseURL = Config.baseURL
            let endPoint = "/api/v1/categories"
            let fullPath = baseURL + endPoint
            print("fullpath: \(fullPath)")
            
            let url = URL(string: fullPath)!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Base Response로 디코딩
            let response = try JSONDecoder().decode(
                APIResponse<CategoryData>.self,
                from: data
            )
            
            // 에러 처리
            guard response.code == "OK",
                  let categoryData = response.data else {
                throw CategoryAPIError.invalidResponse(
                    message: response.message,
                    details: response.details
                )
            }
            
            return categoryData.categoryResponses
        }
    )
}

extension DependencyValues {
    var categoryAPIClient: CategoryAPIClient {
        get { self[CategoryAPIClient.self] }
        set { self[CategoryAPIClient.self] = newValue }
    }
}



enum CategoryAPIError: Error, LocalizedError {
    case invalidResponse(message: String, details: String?)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message, let details):
            if let details = details {
                return "\(message)\n\(details)"
            }
            return message
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}

extension CategoryAPIClient {
    static let testValue = CategoryAPIClient(
        fetchCategories: {
            // Mock 데이터
            return [
                CategoryResponse(
                    categoryId: 1,
                    name: "SwiftUI",
                    path: "/IT/앱개발자/iOS"
                ),
                CategoryResponse(
                    categoryId: 2,
                    name: "Swift 언어",
                    path: "/IT/앱개발자/iOS"
                )
            ]
        }
    )
    
    static let failingValue = CategoryAPIClient(
        fetchCategories: {
            throw CategoryAPIError.invalidResponse(
                message: "서버 오류가 발생했습니다.",
                details: "잠시 후 다시 시도해주세요."
            )
        }
    )
}
