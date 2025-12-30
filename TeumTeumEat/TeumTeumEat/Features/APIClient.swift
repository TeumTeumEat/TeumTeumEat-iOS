//
//  APIClient.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct APIClient {
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        // 1. URL 구성
        let baseURL = Config.baseURL
        let fullPath = baseURL + endpoint
        print("API Request: \(method.rawValue) \(fullPath)")
        
        guard let url = URL(string: fullPath) else {
            print("Invalid URL: \(fullPath)")
            throw APIError.invalidURL
        }
        
        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. 인증 토큰 추가
        if requiresAuth {
            guard let token = KeyChainManager.shared.getAccessToken() else {
                print("No access token found in KeyChain")
                throw APIError.noAccessToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Access Token added to request")
        }
        
        // 4. Request Body 추가 (POST, PUT 등)
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
                if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                    print("Request Body: \(bodyString)")
                }
            } catch {
                print("Failed to encode request body: \(error)")
                throw APIError.encodingFailed(error)
            }
        }
        
        // 5. 네트워크 요청
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 6. HTTP 응답 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("HTTP Status: \(httpResponse.statusCode)")
            
            // 7. 응답 데이터 로깅
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            // 8. 상태 코드별 처리
            switch httpResponse.statusCode {
            case 200...299:
                // 성공 - 데이터 디코딩
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    print("Successfully decoded response")
                    return decodedData
                } catch {
                    print("Decoding Error: \(error)")
                    throw APIError.decodingError(error)
                }
                
            case 400...599:
                // 에러 응답 - 서버 에러 파싱
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                    print("Server Error - Code: \(errorResponse.code), Message: \(errorResponse.message)")
                    throw APIError.serverError(
                        code: errorResponse.code,
                        message: errorResponse.message,
                        details: errorResponse.details
                    )
                } catch let decodingError as DecodingError {
                    // 에러 응답 파싱 실패 - HTTP 상태 코드로 폴백
                    print("Failed to decode error response: \(decodingError)")
                    throw APIError.serverError(
                        code: "HTTP-\(httpResponse.statusCode)",
                        message: "서버 오류 (상태 코드: \(httpResponse.statusCode))",
                        details: nil
                    )
                } catch let apiError as APIError {
                    // 이미 APIError인 경우 그대로 throw
                    throw apiError
                }
                
            default:
                // 예상치 못한 상태 코드
                throw APIError.serverError(
                    code: "HTTP-\(httpResponse.statusCode)",
                    message: "예상치 못한 응답 (상태 코드: \(httpResponse.statusCode))",
                    details: nil
                )
            }
            
        } catch let error as APIError {
            // 이미 APIError로 변환된 경우 그대로 throw
            throw error
        } catch {
            // 네트워크 레이어 에러 (연결 실패, 타임아웃 등)
            print("Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

extension APIClient: DependencyKey {
    static let liveValue = APIClient()
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
