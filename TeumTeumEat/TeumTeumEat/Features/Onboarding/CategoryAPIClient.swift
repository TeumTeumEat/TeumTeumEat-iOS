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
