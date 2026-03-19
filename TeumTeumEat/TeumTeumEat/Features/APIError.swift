//
//  APIError.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation

struct APIErrorResponse: Decodable {
    let code: String
    let message: String
    let details: String?
}


enum APIError: Error, LocalizedError, Equatable {
    // 클라이언트 측 에러
    case invalidURL
    case noAccessToken
    case noRefreshToken
    case encodingFailed(Error)
    
    // 서버 에러
    case serverError(code: String, message: String, details: String?)
    
    // 네트워크 에러
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
            
        case .noAccessToken:
            return "인증 정보가 없습니다. 다시 로그인해주세요."

        case .noRefreshToken:
            return "갱신 토큰이 없습니다. 다시 로그인해주세요."
            
        case .encodingFailed(let error):
            return "요청 데이터 인코딩 실패: \(error.localizedDescription)"
            
        case .serverError(let code, let message, let details):
            if let details = details {
                return "\(message) (\(code))\n상세: \(details)"
            }
            return "\(message) (\(code))"
            
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
            
        case .decodingError(let error):
            return "데이터 파싱 오류: \(error.localizedDescription)"
            
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        }
    }
    
    // 에러 코드별 사용자 메시지
    var userFriendlyMessage: String {
        switch self {
        case .serverError(let code, let message, _):
            return userFriendlyMessage(for: code) ?? message
        default:
            return errorDescription ?? "알 수 없는 오류가 발생했습니다."
        }
    }
    
    private func userFriendlyMessage(for code: String) -> String? {
        switch code {
        // COMMON 에러
        case "COMMON-001": return "잘못된 요청입니다."
        case "COMMON-002": return "올바르지 않은 요청 형식입니다."
        case "COMMON-003": return "데이터 무결성 제약 조건을 위반하였습니다."
        case "COMMON-004": return "접근 권한이 없습니다."
        case "COMMON-005": return "요청한 리소스를 찾을 수 없습니다."
        case "COMMON-006": return "지원하지 않는 요청 방식입니다."
        case "COMMON-007": return "서버 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요."
            
        // AUTH 에러
        case "AUTH-001": return "헤더가 올바르지 않습니다."
        case "AUTH-002": return "토큰이 만료되었습니다.\n다시 로그인해주세요."
        case "AUTH-003": return "유효하지 않은 토큰입니다.\n다시 로그인해주세요."
        case "AUTH-004": return "해당 소셜 로그인은 지원되지 않습니다."
        case "AUTH-005": return "인증 정보가 유효하지 않습니다.\n다시 로그인해주세요."
            
        // USER 에러
        case "USER-001": return "존재하지 않는 사용자입니다."
        case "USER-002": return "아직 온보딩 정보가 설정되어 있지 않습니다."
            
        // CATEGORY 에러
        case "CATEGORY-001": return "존재하지 않는 카테고리입니다."
        case "CATEGORY-DOCUMENT-001": return "존재하지 않는 카테고리 문서입니다."
            
        // DOCUMENT 에러
        case "DOCUMENT-001": return "존재하지 않는 문서입니다."
            
        // GOAL 에러
        case "GOAL-001": return "존재하지 않는 목표입니다."
            
        // QUIZ 에러
        case "QUIZ-001": return "존재하지 않는 퀴즈입니다."
            
        // FILE 에러
        case "FILE-001": return "지원되지 않는 파일 형식입니다."
        case "FILE-002": return "업로드된 문서가 아닙니다."
            
        default: return nil
        }
    }
    
    // 재로그인이 필요한 에러인지 확인
    var requiresRelogin: Bool {
        if case .serverError(let code, _, _) = self {
            return ["AUTH-002", "AUTH-003", "AUTH-005"].contains(code)
        }
        if case .noAccessToken = self { return true }
        if case .noRefreshToken = self { return true }
        return false
    }
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.noAccessToken, .noAccessToken):
            return true
        case (.noRefreshToken, .noRefreshToken):
            return true
        case (.encodingFailed(let lhsError), .encodingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.serverError(let lhsCode, let lhsMessage, let lhsDetails),
              .serverError(let rhsCode, let rhsMessage, let rhsDetails)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage && lhsDetails == rhsDetails
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.invalidResponse, .invalidResponse):
            return true
        default:
            return false
        }
    }
}
