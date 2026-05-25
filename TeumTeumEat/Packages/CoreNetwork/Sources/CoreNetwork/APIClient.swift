//
//  APIClient.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - Token Reissue Models
private struct ReissueTokenRequest: Encodable {
    let refreshToken: String
}

private struct ReissueTokenData: Decodable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Token Refresh Coordinator
/// 동시에 여러 API 요청이 토큰 만료를 감지했을 때 중복 재발급을 방지하는 Actor
private actor TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()
    private init() {}

    private var refreshTask: Task<Void, Error>?

    func refresh(using apiClient: APIClient) async throws {
        if let task = refreshTask {
            try await task.value
            return
        }

        let task = Task<Void, Error> {
            try await apiClient.performTokenReissue()
        }
        refreshTask = task

        do {
            try await task.value
            refreshTask = nil
        } catch {
            refreshTask = nil
            throw error
        }
    }
}

public struct APIClient {

    public init() {}

    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true,
        isRetry: Bool = false
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
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    return decodedData
                } catch {
                    print("Decoding Error: \(error)")
                    throw APIError.decodingError(error)
                }

            case 400...599:
                let errorCode: String
                let errorMessage: String
                let errorDetails: String?

                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                    errorCode = errorResponse.code
                    errorMessage = errorResponse.message
                    errorDetails = errorResponse.details
                    print("Server Error - Code: \(errorCode), Message: \(errorMessage)")
                } catch {
                    errorCode = "HTTP-\(httpResponse.statusCode)"
                    errorMessage = "서버 오류 (상태 코드: \(httpResponse.statusCode))"
                    errorDetails = nil
                    print("Failed to decode error response, fallback to HTTP status")
                }

                // AUTH-002: 액세스 토큰 만료 → 재발급 후 1회 retry
                if errorCode == "AUTH-002", requiresAuth, !isRetry {
                    print("Access token expired. Attempting token refresh...")
                    try await TokenRefreshCoordinator.shared.refresh(using: self)
                    print("Token refreshed. Retrying original request...")
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        requiresAuth: requiresAuth,
                        isRetry: true
                    )
                }

                throw APIError.serverError(code: errorCode, message: errorMessage, details: errorDetails)

            default:
                throw APIError.serverError(
                    code: "HTTP-\(httpResponse.statusCode)",
                    message: "예상치 못한 응답 (상태 코드: \(httpResponse.statusCode))",
                    details: nil
                )
            }

        } catch let error as APIError {
            throw error
        } catch {
            print("Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

extension APIClient: DependencyKey {
    public static let liveValue = APIClient()
}

// MARK: - Token Reissue
extension APIClient {
    fileprivate func performTokenReissue() async throws {
        guard let refreshToken = KeyChainManager.shared.getRefreshToken() else {
            print("No refresh token found in KeyChain")
            throw APIError.noRefreshToken
        }

        let response: APIResponse<ReissueTokenData> = try await request(
            endpoint: "/api/v2/users/reissue",
            method: .post,
            body: ReissueTokenRequest(refreshToken: refreshToken),
            requiresAuth: false,
            isRetry: true
        )

        guard response.code == "OK", let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        KeyChainManager.shared.saveAccessToken(data.accessToken)
        KeyChainManager.shared.saveRefreshToken(data.refreshToken)
        print("Token reissued and saved successfully")
    }
}

public extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
