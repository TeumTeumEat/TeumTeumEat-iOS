//
//  CategoryAPIClient.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies

public struct CategoryAPIClient {
    public var fetchCategories: @Sendable () async throws -> [CategoryResponse]

    public init(fetchCategories: @escaping @Sendable () async throws -> [CategoryResponse]) {
        self.fetchCategories = fetchCategories
    }
}

extension CategoryAPIClient: DependencyKey {
    // 공통 APIClient.request 사용 (토큰 만료 시 재발급 + 재시도 포함)
    public static let liveValue = CategoryAPIClient(
        fetchCategories: {
            do {
                let response: APIResponse<CategoryData> = try await APIClient.liveValue.request(
                    endpoint: "/api/v1/categories",
                    method: .get,
                    requiresAuth: true
                )

                guard response.code == "OK", let categoryData = response.data else {
                    throw CategoryAPIError.invalidResponse(
                        message: response.message,
                        details: response.details
                    )
                }

                Log.network.debug("Categories loaded: \(categoryData.categoryResponses.count) items")
                return categoryData.categoryResponses

            } catch let error as CategoryAPIError {
                throw error
            } catch let error as APIError {
                // 화면에서는 CategoryAPIError.errorDescription을 표시하므로 메시지를 유지해 변환
                Log.network.error("Category API Error: \(error)")
                switch error {
                case .networkError(let underlying):
                    throw CategoryAPIError.networkError(underlying)
                default:
                    throw CategoryAPIError.invalidResponse(message: error.userFriendlyMessage, details: nil)
                }
            }
        }
    )
}

public extension DependencyValues {
    var categoryAPIClient: CategoryAPIClient {
        get { self[CategoryAPIClient.self] }
        set { self[CategoryAPIClient.self] = newValue }
    }
}



public enum CategoryAPIError: Error, LocalizedError {
    case invalidResponse(message: String, details: String?)
    case networkError(Error)
    
    public var errorDescription: String? {
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

public extension CategoryAPIClient {
    static let testValue = CategoryAPIClient(
        fetchCategories: {
            return [
                // MARK: IT - 앱개발자 - iOS
                CategoryResponse(categoryId: 1,  name: "SwiftUI",           path: "/IT/앱개발자/iOS"),
                CategoryResponse(categoryId: 2,  name: "UIKit",             path: "/IT/앱개발자/iOS"),
                CategoryResponse(categoryId: 3,  name: "Swift 언어",         path: "/IT/앱개발자/iOS"),
                CategoryResponse(categoryId: 4,  name: "Combine",           path: "/IT/앱개발자/iOS"),
                CategoryResponse(categoryId: 5,  name: "TCA 아키텍처",        path: "/IT/앱개발자/iOS"),
                // MARK: IT - 앱개발자 - Android
                CategoryResponse(categoryId: 6,  name: "Kotlin 기초",        path: "/IT/앱개발자/Android"),
                CategoryResponse(categoryId: 7,  name: "Jetpack Compose",   path: "/IT/앱개발자/Android"),
                CategoryResponse(categoryId: 8,  name: "Coroutines",        path: "/IT/앱개발자/Android"),
                // MARK: IT - 웹개발자 - 프론트엔드
                CategoryResponse(categoryId: 9,  name: "React",             path: "/IT/웹개발자/프론트엔드"),
                CategoryResponse(categoryId: 10, name: "TypeScript",        path: "/IT/웹개발자/프론트엔드"),
                CategoryResponse(categoryId: 11, name: "CSS 레이아웃",        path: "/IT/웹개발자/프론트엔드"),
                // MARK: IT - 웹개발자 - 백엔드
                CategoryResponse(categoryId: 12, name: "Spring Boot",       path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 13, name: "Node.js",           path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 14, name: "RESTful API 설계",   path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 51, name: "Django",            path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 52, name: "FastAPI",           path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 53, name: "GraphQL",           path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 54, name: "gRPC",              path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 55, name: "인증과 보안 (JWT)",    path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 56, name: "서버 아키텍처",         path: "/IT/웹개발자/백엔드"),
                CategoryResponse(categoryId: 57, name: "마이크로서비스",         path: "/IT/웹개발자/백엔드"),
                // MARK: IT - DevOps - 클라우드
                CategoryResponse(categoryId: 15, name: "AWS 기초",           path: "/IT/DevOps/클라우드"),
                CategoryResponse(categoryId: 16, name: "Docker",            path: "/IT/DevOps/클라우드"),
                CategoryResponse(categoryId: 17, name: "Kubernetes",        path: "/IT/DevOps/클라우드"),
                // MARK: IT - 데이터베이스 - SQL
                CategoryResponse(categoryId: 18, name: "MySQL 기초",         path: "/IT/데이터베이스/SQL"),
                CategoryResponse(categoryId: 19, name: "쿼리 최적화",          path: "/IT/데이터베이스/SQL"),
                // MARK: IT - 데이터베이스 - NoSQL
                CategoryResponse(categoryId: 20, name: "MongoDB",           path: "/IT/데이터베이스/NoSQL"),
                CategoryResponse(categoryId: 21, name: "Redis",             path: "/IT/데이터베이스/NoSQL"),
                // MARK: IT - PM - 기획
                CategoryResponse(categoryId: 22, name: "요구사항 분석",         path: "/IT/PM/기획"),
                CategoryResponse(categoryId: 23, name: "와이어프레임",          path: "/IT/PM/기획"),
                CategoryResponse(categoryId: 24, name: "로드맵 작성",          path: "/IT/PM/기획"),
                // MARK: IT - 디자인 - UI/UX
                CategoryResponse(categoryId: 25, name: "Figma 활용",         path: "/IT/디자인/UI·UX"),
                CategoryResponse(categoryId: 26, name: "사용자 리서치",         path: "/IT/디자인/UI·UX"),
                CategoryResponse(categoryId: 27, name: "프로토타입 제작",        path: "/IT/디자인/UI·UX"),
                // MARK: 경제 - 경제 - 금융 기초
                CategoryResponse(categoryId: 28, name: "예금과 적금",          path: "/경제/경제/금융 기초"),
                CategoryResponse(categoryId: 29, name: "환율과 금리",          path: "/경제/경제/금융 기초"),
                CategoryResponse(categoryId: 30, name: "신용과 대출",          path: "/경제/경제/금융 기초"),
                // MARK: 경제 - 경제 - 주식
                CategoryResponse(categoryId: 31, name: "주식 기초",           path: "/경제/경제/주식"),
                CategoryResponse(categoryId: 32, name: "ETF 투자",           path: "/경제/경제/주식"),
                CategoryResponse(categoryId: 33, name: "차트 분석",           path: "/경제/경제/주식"),
                // MARK: 경제 - 경제 - 투자 입문
                CategoryResponse(categoryId: 34, name: "부동산 기초",          path: "/경제/경제/투자 입문"),
                CategoryResponse(categoryId: 35, name: "채권 투자",           path: "/경제/경제/투자 입문"),
                // MARK: 스포츠 - 스포츠 - 구기 종목 (축구 & 농구)
                CategoryResponse(categoryId: 36, name: "축구 규칙",           path: "/스포츠/스포츠/구기 종목 (축구 & 농구)"),
                CategoryResponse(categoryId: 37, name: "농구 포지션",          path: "/스포츠/스포츠/구기 종목 (축구 & 농구)"),
                // MARK: 스포츠 - 스포츠 - 러닝 & 유산소
                CategoryResponse(categoryId: 38, name: "마라톤 훈련",          path: "/스포츠/스포츠/러닝 & 유산소"),
                CategoryResponse(categoryId: 39, name: "심박수 관리",          path: "/스포츠/스포츠/러닝 & 유산소"),
                // MARK: 스포츠 - 스포츠 - 웨이트(헬스)
                CategoryResponse(categoryId: 40, name: "스쿼트 자세",          path: "/스포츠/스포츠/웨이트(헬스)"),
                CategoryResponse(categoryId: 41, name: "데드리프트",           path: "/스포츠/스포츠/웨이트(헬스)"),
                CategoryResponse(categoryId: 42, name: "벤치프레스",           path: "/스포츠/스포츠/웨이트(헬스)"),
                // MARK: 교양 - 시사 교양 - 국제 사회
                CategoryResponse(categoryId: 43, name: "UN과 국제기구",        path: "/교양/시사 교양/국제 사회"),
                CategoryResponse(categoryId: 44, name: "G7과 글로벌 이슈",     path: "/교양/시사 교양/국제 사회"),
                // MARK: 교양 - 시사 교양 - 지리와 문화
                CategoryResponse(categoryId: 45, name: "세계 지리",           path: "/교양/시사 교양/지리와 문화"),
                CategoryResponse(categoryId: 46, name: "각국의 문화",          path: "/교양/시사 교양/지리와 문화"),
                // MARK: 교양 - 건강 - 질환과 안전
                CategoryResponse(categoryId: 47, name: "생활 속 응급처치",      path: "/교양/건강/질환과 안전"),
                CategoryResponse(categoryId: 48, name: "만성질환 예방",         path: "/교양/건강/질환과 안전"),
                // MARK: 교양 - 건강 - 식품과 영양
                CategoryResponse(categoryId: 49, name: "영양소 기초",          path: "/교양/건강/식품과 영양"),
                CategoryResponse(categoryId: 50, name: "건강한 식단 구성",      path: "/교양/건강/식품과 영양"),
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
