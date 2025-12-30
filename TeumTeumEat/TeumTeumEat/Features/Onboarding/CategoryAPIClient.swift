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
            do {
                let baseURL = Config.baseURL
                let endPoint = "/api/v1/categories"
                let fullPath = baseURL + endPoint
                print("Fetching categories from: \(fullPath)")
                
                guard let url = URL(string: fullPath) else {
                    print("Invalid URL: \(fullPath)")
                    throw CategoryAPIError.invalidResponse(
                        message: "잘못된 URL입니다.",
                        details: nil
                    )
                }
                
                // URLRequest 생성
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                //  KeyChain에서 토큰 가져오기
                if let token = KeyChainManager.shared.getAccessToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    print("Access Token added to request")
                } else {
                    print("No access token found in KeyChain")
                    throw CategoryAPIError.invalidResponse(
                        message: "인증 토큰이 없습니다.",
                        details: "다시 로그인해주세요."
                    )
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // HTTP 응답 확인
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        // 401 에러 처리
                        if httpResponse.statusCode == 401 {
                            throw CategoryAPIError.invalidResponse(
                                message: "인증이 만료되었습니다.",
                                details: "다시 로그인해주세요."
                            )
                        }
                        throw CategoryAPIError.invalidResponse(
                            message: "서버 오류 (상태 코드: \(httpResponse.statusCode))",
                            details: nil
                        )
                    }
                }
                
                // 응답 데이터 확인
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON:")
                    print(jsonString)
                }
                
                // Base Response로 디코딩
                let apiResponse = try JSONDecoder().decode(
                    APIResponse<CategoryData>.self,
                    from: data
                )
                
                print("API Response Code: \(apiResponse.code)")
                print("API Response Message: \(apiResponse.message)")
                
                // 에러 처리
                guard apiResponse.code == "OK",
                      let categoryData = apiResponse.data else {
                    print("Invalid API Response")
                    throw CategoryAPIError.invalidResponse(
                        message: apiResponse.message,
                        details: apiResponse.details
                    )
                }
                
                print("Categories loaded: \(categoryData.categoryResponses.count) items")
                return categoryData.categoryResponses
                
            } catch let decodingError as DecodingError {
                print("Decoding Error: \(decodingError)")
                throw CategoryAPIError.invalidResponse(
                    message: "데이터 파싱 오류",
                    details: decodingError.localizedDescription
                )
            } catch let error as CategoryAPIError {
                print("Category API Error: \(error)")
                throw error
            } catch {
                print("Network Error: \(error)")
                throw CategoryAPIError.networkError(error)
            }
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
