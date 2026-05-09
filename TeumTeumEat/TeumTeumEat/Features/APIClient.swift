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

struct APIClient {
    
    func request<T: Decodable>(
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
                // 성공 - 데이터 디코딩
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    return decodedData
                } catch {
                    print("Decoding Error: \(error)")
                    throw APIError.decodingError(error)
                }
                
            case 400...599:
                // 에러 응답 디코딩 (sync only - try await는 이 블록 밖에서 처리)
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

// MARK: - Token Reissue
extension APIClient {
    /// 토큰 재발급 (TokenRefreshCoordinator 내부에서만 호출)
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

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}


extension APIClient {
    func fetchCategories() async throws -> [CategoryResponse] {
        // APIResponse<CategoryData>로 디코딩
        let response: APIResponse<CategoryData> = try await request(
            endpoint: "/api/v1/categories",
            method: .get,
            requiresAuth: true
        )
        
        // 응답 검증
        guard response.code == "OK",
              let categoryData = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Categories loaded: \(categoryData.categoryResponses.count) items")
        return categoryData.categoryResponses
    }
}

extension APIClient {
    /// 유저 이름 수정
    func updateUserName(name: String) async throws {
        // APIResponse<EmptyData> 형태로 받기
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/users/name",
            method: .patch,
            body: UpdateUserNameRequest(name: name),
            requiresAuth: true
        )
        
        // 응답 검증
        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        print("User name updated successfully: \(name)")
    }
    
    /// 출퇴근 정보 수정
       func updateCommuteInfo(
           startTime: String,
           endTime: String,
           usageTime: Int
       ) async throws {
           let response: APIResponse<EmptyData> = try await request(
               endpoint: "/api/v1/users/commute-info",
               method: .patch,
               body: UpdateCommuteInfoRequest(
                   startTime: startTime,
                   endTime: endTime,
                   usageTime: usageTime
               ),
               requiresAuth: true
           )
           
           guard response.code == "OK" else {
               throw APIError.serverError(
                   code: response.code,
                   message: response.message,
                   details: response.details
               )
           }
           
           print("Commute info updated successfully - Start: \(startTime), End: \(endTime), Usage: \(usageTime)분")
       }
}

extension APIClient {
    /// 목표 생성
      func createGoal(
          type: CreateGoalRequest.GoalType,
          studyPeriod: String,
          difficulty: CreateGoalRequest.Difficulty,
          prompt: String?,
          categoryId: Int?
      ) async throws {
          let response: APIResponse<EmptyData> = try await request(
              endpoint: "/api/v1/goals",
              method: .post,
              body: CreateGoalRequest(
                  type: type,
                  studyPeriod: studyPeriod,
                  difficulty: difficulty,
                  prompt: prompt,
                  categoryId: categoryId
              ),
              requiresAuth: true
          )
          
          guard response.code == "OK" else {
              throw APIError.serverError(
                  code: response.code,
                  message: response.message,
                  details: response.details
              )
          }
          
          print("Goal created successfully - Type: \(type.rawValue), Period: \(studyPeriod)")
      }
    
    /// 전체 목표 목록 조회
    func fetchGoals() async throws -> [GoalResponse] {
        let response: APIResponse<GoalListData> = try await request(
            endpoint: "/api/v1/goals",
            method: .get,
            requiresAuth: true
        )
        
        print("Response code: \(response.code)")
        print("Response data: \(String(describing: response.data))")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Goals fetched - Count: \(data.goalResponses.count)")
        data.goalResponses.forEach { goal in
            print("[Goal] id:\(goal.goalId) type:\(goal.type) isExpired:\(goal.isExpired) isCompleted:\(goal.isCompleted) period:\(goal.studyPeriod) difficulty:\(goal.difficulty) start:\(goal.startDate) end:\(goal.endDate)")
        }

        return data.goalResponses
    }
    
    /// 현재  목표 목록 조회
    func fetchCurrentGoal() async throws -> GoalResponse {
        let response: APIResponse<GoalResponse> = try await request(
            endpoint: "/api/v1/users/goal",
            method: .get,
            requiresAuth: true
        )
        
        print("fetchCurrentGoal - Response code: \(response.code)")
        print("fetchCurrentGoal - Response data: \(String(describing: response.data))")
        
        guard response.code == "OK",
              let goal = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Current Goal - ID: \(goal.goalId), Type: \(goal.type)")
        if let category = goal.category {
            print("CategoryId: \(category.categoryId), Name: \(category.name)")
        }
        
        return goal
    }
    
    /// PDF 문서 등록
    func registerDocument(
        goalId: Int,
        fileName: String,
        fileKey: String
    ) async throws {
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/goals/\(goalId)/documents",
            method: .post,
            body: RegisterDocumentRequest(
                fileName: fileName,
                fileKey: fileKey
            ),
            requiresAuth: true
        )

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("Document registered successfully - GoalId: \(goalId), FileName: \(fileName)")
    }
    
    func getPresignedURL(fileName: String, fileSize: Int64) async throws -> PresignedURLData {
         let response: APIResponse<PresignedURLData> = try await request(
             endpoint: "/api/v1/s3/presigned",
             method: .post,
             body: PresignedURLRequest(fileName: fileName, fileSize: fileSize),
             requiresAuth: true
         )
         
         guard response.code == "OK",
               let data = response.data else {
             throw APIError.serverError(
                 code: response.code,
                 message: response.message,
                 details: response.details
             )
         }
         
         print("   PresignedURL received for file: \(fileName)")
         print("   URL: \(data.presignedUrl)")
         print("   Key: \(data.key)")
         
         return data
     }
    
    /// S3에 PDF 파일 업로드
    func uploadFileToS3(fileURL: URL, presignedURL: String) async throws {
        guard let url = URL(string: presignedURL) else {
            throw APIError.invalidURL
        }
        
        // 파일 데이터 읽기
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
            print("File loaded - Size: \(fileData.count) bytes")
        } catch {
            print("Failed to load file: \(error)")
            throw APIError.networkError(error)
        }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData
        
        print("Uploading file to S3...")
        
        // S3에 업로드
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("S3 Upload Status: \(httpResponse.statusCode)")
            
            // S3는 보통 200 또는 204 반환
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(
                    code: "S3-\(httpResponse.statusCode)",
                    message: "S3 업로드 실패 (상태 코드: \(httpResponse.statusCode))",
                    details: nil
                )
            }
            
            print("File uploaded to S3 successfully")
            
        } catch let error as APIError {
            throw error
        } catch {
            print("S3 Upload Error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

extension APIClient {
    /// 유저 계정정보 조회
    func fetchUserAccountInfo() async throws -> UserAccountInfoData {
        let response: APIResponse<UserAccountInfoData> = try await request(
            endpoint: "/api/v1/users/account-info",
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("User account info fetched - Provider: \(data.socialProvider), Email: \(data.email)")
        return data
    }
}

extension APIClient {
    // GET - 알림 설정 조회
    func fetchNotificationSettings() async throws -> UserNotificationSettingsData {
        let response: APIResponse<UserNotificationSettingsData> = try await request(
            endpoint: "/api/v1/users/settings",
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Notification settings fetched - pushEnabled: \(data.pushEnabled)")
        return data
    }
    
    // PATCH - 알림 설정 업데이트
    func updateNotificationSetting(pushEnabled: Bool) async throws {
        let requestBody = UpdateNotificationSettingRequest(pushEnabled: pushEnabled)
        
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/users/settings",
            method: .patch,
            body: requestBody,
            requiresAuth: true
        )
        
        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Notification setting updated - pushEnabled: \(pushEnabled)")
    }
    
    /// 퀴즈풀이, 요약글 생성 여부 확인
    func fetchUserQuizStatus() async throws -> UserQuizStatusData {
        let response: APIResponse<UserQuizStatusData> = try await request(
            endpoint: "/api/v1/user-quizzes/status",
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let statusData = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("[QuizStatus] hasSolvedToday: \(statusData.hasSolvedToday), hasCreatedToday: \(statusData.hasCreatedToday), availableCount: \(statusData.availableQuizCount)")
        
        return statusData
    }
    
    /// 카테고리 요약글 조회 (GET only — 없으면 COMMON-005 throw, 생성하지 않음)
    func fetchCategoryDocumentIfExists(categoryId: Int) async throws -> CategoryDocumentData {
        let response: APIResponse<CategoryDocumentData> = try await request(
            endpoint: "/api/v1/categories/\(categoryId)/documents/daily",
            method: .get,
            requiresAuth: true
        )
        guard response.code == "OK", let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        return data
    }

    /// 오늘의 카테고리 자료(요약글) 조회 (없으면 생성 후 재조회)
    func fetchDailyCategoryDocument(categoryId: Int) async throws -> CategoryDocumentData {
        let dailyEndpoint = "/api/v1/categories/\(categoryId)/documents/daily"

        // Step 1: GET으로 요약글 조회 시도
        do {
            let documentData = try await fetchCategoryDocumentGET(endpoint: dailyEndpoint)
            print("[CategoryDocument] GET 성공 - documentId: \(documentData.documentId), hasSolvedToday: \(documentData.hasSolvedToday)")
            return documentData
        } catch let apiError as APIError {
            if case .serverError(let code, _, _) = apiError, code == "COMMON-005" {
                // 요약글 아직 없음 → 생성 필요
                print("[CategoryDocument] COMMON-005 - 요약글 없음, 생성 시작")
            } else {
                throw apiError
            }
        }

        // Step 2: 문서 없음 → POST로 생성 시도
        do {
            let _: APIResponse<EmptyData> = try await request(
                endpoint: dailyEndpoint,
                method: .post,
                requiresAuth: true
            )
            print("[CategoryDocument] POST 생성 완료")
        } catch let apiError as APIError {
            if case .serverError(let code, _, _) = apiError, code == "QUIZ-003" {
                // 이미 생성된 문서 있음 → GET으로 조회
                print("[CategoryDocument] QUIZ-003 - 기존 문서 존재, GET으로 조회")
            } else {
                throw apiError
            }
        }

        // Step 3: GET으로 최종 조회
        let response: APIResponse<CategoryDocumentData> = try await request(
            endpoint: dailyEndpoint,
            method: .get,
            requiresAuth: true
        )

        guard response.code == "OK", let documentData = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("[CategoryDocument] GET 완료 - documentId: \(documentData.documentId), hasSolvedToday: \(documentData.hasSolvedToday)")
        return documentData
    }

    private func fetchCategoryDocumentGET(endpoint: String) async throws -> CategoryDocumentData {
        let response: APIResponse<CategoryDocumentData> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        guard response.code == "OK", let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        return data
    }
    
    /// PDF 요약글 조회 (없으면 생성 후 재조회)
    func fetchDailyPDFSummary(goalId: Int, documentId: Int) async throws -> PDFSummaryData {
        let endpoint = "/api/v1/goals/\(goalId)/documents/\(documentId)/summary"

        // Step 1: GET으로 요약글 조회 시도
        do {
            let summaryData = try await fetchPDFSummaryGET(endpoint: endpoint)
            print("[PDFSummary] GET 성공 - documentId: \(summaryData.documentId)")
            return summaryData
        } catch let apiError as APIError {
            if case .serverError(let code, _, _) = apiError, code == "COMMON-005" {
                print("[PDFSummary] COMMON-005 - 요약글 없음, 생성 시작")
            } else {
                throw apiError
            }
        }

        // Step 2: 요약글 없음 → POST로 생성
        let _: APIResponse<EmptyData> = try await request(
            endpoint: endpoint,
            method: .post,
            requiresAuth: true
        )
        print("[PDFSummary] POST 생성 완료")

        // Step 3: 생성 후 GET으로 재조회
        let summaryData = try await fetchPDFSummaryGET(endpoint: endpoint)
        print("[PDFSummary] GET 재조회 성공 - documentId: \(summaryData.documentId)")
        return summaryData
    }

    private func fetchPDFSummaryGET(endpoint: String) async throws -> PDFSummaryData {
        let response: APIResponse<PDFSummaryData> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        guard response.code == "OK", let summaryData = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        return summaryData
    }
    
    /// 유저퀴즈 조회
    func fetchUserQuizzes(documentId: Int, documentType: DocumentType) async throws -> [UserQuiz] {
        let response: APIResponse<[UserQuiz]> = try await request(
            endpoint: "/api/v1/user-quizzes?documentId=\(documentId)&documentType=\(documentType.rawValue)",
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let quizzes = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("[UserQuizzes] count: \(quizzes.count)")
        
        return quizzes
    }
    
    func submitQuizAnswer(quizId: Int, userAnswer: String) async throws -> SubmitQuizAnswerData {
        let requestBody = SubmitQuizAnswerRequest(
            quizId: quizId,
            userAnswer: userAnswer
        )
        
        let response: APIResponse<SubmitQuizAnswerData> = try await request(
            endpoint: "/api/v1/user-quizzes/submit",
            method: .post,
            body: requestBody,
            requiresAuth: true
        )
        
        print(" submitQuizAnswer - Response code: \(response.code)")
        print(" submitQuizAnswer - QuizId: \(quizId), Answer: \(userAnswer)")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print(" Quiz Answer Submitted - isCorrect: \(data.isCorrect)")
        print("   Correct Answer: \(data.correctAnswer)")
        print("   Explanation: \(data.explanation)")
        
        return data
    }
    
    /// 주제별 히스토리 내역 확인
    func fetchHistoryTopics() async throws -> [HistoryCategoryResponse] {
        let response: APIResponse<[HistoryCategoryResponse]> = try await request(
            endpoint: "/api/v1/history/topics",
            method: .get,
            requiresAuth: true
        )
        
        print("Response code: \(response.code)")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("History topics fetched successfully - Category Count: \(data.count)")
        return data
    }
    
    /// 히스토리 캘린더 조회
    func fetchCalendarHistory(year: Int, month: Int) async throws -> CalendarHistoryData {
        let monthString = String(format: "%02d", month)
        let endpoint = "/api/v1/history/calendar?year=\(year)&month=\(monthString)"
        
        let response: APIResponse<CalendarHistoryData> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print(" Calendar history fetched: \(data.stampedDates.count) stamps found.")
        return data
    }
    
    /// 날짜별 상세내역 조회
    func fetchHistoryByDate(_ date: String) async throws -> [HistoryItemResponse] {
        let endpoint = "/api/v1/history/date/\(date)"
        
        let response: APIResponse<[HistoryItemResponse]> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("History for \(date) fetched: \(data.count) items found.")
        return data
    }
    
    
    /// 퀴즈목록 상세보기
    func fetchQuizHistoryDetails(type: DocumentType, id: Int, date: String)  async throws -> QuizHistoryDetailData {

        let typePath = type.rawValue
        let endpoint = "/api/v1/history/details/quizzes/\(typePath)/\(id)?date=\(date)"
        
        // 2. 공통 request 함수 호출
        let response: APIResponse<QuizHistoryDetailData> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        
        // 3. 응답 처리
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("\(typePath) (ID: \(id)) 퀴즈 내역 조회 성공: \(data.quizzes.count)문항")
        return data
    }
    
    /// 요약글 상세보기
    func fetchHistorySummaryDetail(type: DocumentType, id: Int, date: String) async throws -> HistorySummaryDetailData {
        let typePath = type.rawValue
        let endpoint = "/api/v1/history/details/summary/\(typePath)/\(id)?date=\(date)"
        
        let response: APIResponse<HistorySummaryDetailData> = try await request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        print("Summary fetched: \(data.title) (Date: \(date))")
        return data
    }
    
    /// 현재 목표 업데이트 (선택한 목표로 변경)
        func updateCurrentGoal(goalId: Int) async throws {
            let response: APIResponse<EmptyData> = try await request(
                endpoint: "/api/v1/users/goal?goalId=\(goalId)",
                method: .patch,
                requiresAuth: true
            )
            
            print("updateCurrentGoal - Response code: \(response.code)")
            
            guard response.code == "OK" else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("Current goal updated successfully - goalId: \(goalId)")
        }
    
    /// 회원탈퇴
        func withdrawUser() async throws {
            let response: APIResponse<EmptyData> = try await request(
                endpoint: "/api/v1/users/withdrawal",
                method: .delete,
                requiresAuth: true
            )
            
            print("withdrawUser - Response code: \(response.code)")
            
            guard response.code == "OK" else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("User withdrawal successful")
        }
    
    
    /// 유저 이름 조회
        func fetchUserName() async throws -> String {
            let response: APIResponse<UserNameData> = try await request(
                endpoint: "/api/v1/users/name",
                method: .get,
                requiresAuth: true
            )
            
            print("fetchUserName - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("User name fetched successfully: \(data.name)")
            return data.name
        }
        
        /// 출퇴근 정보 조회
        func fetchCommuteInfo() async throws -> CommuteInfoData {
            let response: APIResponse<CommuteInfoData> = try await request(
                endpoint: "/api/v1/users/commute-info",
                method: .get,
                requiresAuth: true
            )
            
            print("fetchCommuteInfo - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("Commute info fetched successfully")
            print("   Start: \(data.startTime), End: \(data.endTime), Usage: \(data.usageTime)분")
            return data
        }
    
    /// 온보딩 완료 여부 조회
        func fetchOnboardingStatus() async throws -> Bool {
            let response: APIResponse<OnboardingStatusData> = try await request(
                endpoint: "/api/v1/users/onboarding-completed",
                method: .get,
                requiresAuth: true
            )
            
            print("fetchOnboardingStatus - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("Onboarding status fetched: \(data.completed)")
            return data.completed
        }
    
    /// 디바이스 토큰 등록
        func registerDeviceToken(token: String, deviceType: String) async throws {
            let response: APIResponse<EmptyData> = try await request(
                endpoint: "/api/v1/notifications/device-tokens",
                method: .post,
                body: RegisterDeviceTokenRequest(
                    token: token,
                    deviceType: deviceType
                ),
                requiresAuth: true
            )
            
            print("registerDeviceToken - Response code: \(response.code)")
            
            guard response.code == "OK" else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            print("Device token registered successfully")
        }
}


extension APIClient {
    /// 광고 시청 보상 처리
    func postAdReward() async throws {
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/user-quizzes/ad-reward",
            method: .post,
            requiresAuth: true
        )

        print("postAdReward - Response code: \(response.code)")

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("Ad reward processed successfully")
    }
}

extension APIClient {
    /// 퀴즈 세트 풀이 완료 처리 (일일 퀴즈 횟수 차감)
    func completeQuizSet() async throws {
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/user-quizzes/complete-set",
            method: .post,
            requiresAuth: true
        )

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("[QuizFlow] 퀴즈 세트 차감 완료")
    }
}

extension APIClient {
    /// 퀴즈 가이드 본 것으로 표시
    func updateQuizGuideSeen() async throws {
        let response: APIResponse<QuizGuideSeenData> = try await request(
            endpoint: "/api/v1/user-quizzes/guide",
            method: .post,
            requiresAuth: true
        )

        print("updateQuizGuideSeen - Response code: \(response.code)")

        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        print("Quiz guide seen status updated: \(data.isQuizGuideSeen)")
    }
}

// MARK: - SSE Helpers (file-private)
private struct SSEDataPayload: Decodable {
    let status: String
    let remain: Int?
    let reason: String?
}

private struct SSEErrorResponse: Decodable {
    let code: String
    let message: String
}

extension APIClient {
    func connectDocumentSSE(
        goalId: Int,
        documentId: Int,
        lastEventId: String? = nil
    ) -> AsyncThrowingStream<SSEDocumentStatus, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let endpoint = "/api/v1/goals/\(goalId)/documents/\(documentId)/sse"
                guard let url = URL(string: Config.baseURL + endpoint) else {
                    continuation.finish(throwing: APIError.invalidURL)
                    return
                }

                var request = URLRequest(url: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

                if let token = KeyChainManager.shared.getAccessToken() {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                if let lastEventId = lastEventId {
                    request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-ID")
                }

                do {
                    print("[SSE DEBUG] 요청 시작 - URL: \(url.absoluteString)")
                    let sseConfig = URLSessionConfiguration.default
                    sseConfig.timeoutIntervalForRequest = 600
                    sseConfig.timeoutIntervalForResource = 600
                    let sseSession = URLSession(configuration: sseConfig)
                    let (bytes, response) = try await sseSession.bytes(for: request)
                    print("[SSE DEBUG] 응답 수신 완료")

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    print("[SSE DEBUG] HTTP 상태 코드: \(httpResponse.statusCode)")

                    if httpResponse.statusCode != 200 {
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        if let errorResponse = try? JSONDecoder().decode(SSEErrorResponse.self, from: errorData) {
                            continuation.finish(throwing: APIError.serverError(
                                code: errorResponse.code,
                                message: errorResponse.message,
                                details: nil
                            ))
                        } else {
                            continuation.finish(throwing: APIError.serverError(
                                code: "SSE-\(httpResponse.statusCode)",
                                message: "SSE 연결 실패 (상태 코드: \(httpResponse.statusCode))",
                                details: nil
                            ))
                        }
                        return
                    }

                    var eventType = ""
                    var eventData = ""
                    print("[SSE DEBUG] 이벤트 루프 시작")

                    for try await line in bytes.lines {
                        print("[SSE RAW] \(line)")
                        // 빈 줄 또는 새 id: 가 오면 이전 이벤트 dispatch
                        if line.isEmpty || line.hasPrefix("id:") {
                            if !eventData.isEmpty,
                               let event = parseSSEEvent(type: eventType, data: eventData) {
                                print("[SSE DEBUG] 이벤트 dispatch: \(eventType) / \(eventData.prefix(80))")
                                continuation.yield(event)
                                if case .completed = event { continuation.finish(); return }
                                if case .failed = event { continuation.finish(); return }
                            }
                            eventType = ""
                            eventData = ""
                        } else if line.hasPrefix("event:") {
                            eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let value = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                            if eventData.isEmpty {
                                eventData = value
                            } else {
                                eventData += "\n" + value
                            }
                            // 서버가 COMPLETED/FAILED 후 trailing separator 없이 연결을 유지하는 경우를 대비해
                            // 데이터가 쌓일 때마다 파싱 시도 → 완성된 JSON이면 즉시 dispatch
                            if let event = parseSSEEvent(type: eventType, data: eventData) {
                                if case .completed = event {
                                    print("[SSE DEBUG] 이벤트 dispatch (즉시): \(eventType) COMPLETED")
                                    continuation.yield(event)
                                    continuation.finish()
                                    return
                                }
                                if case .failed = event {
                                    print("[SSE DEBUG] 이벤트 dispatch (즉시): \(eventType) FAILED")
                                    continuation.yield(event)
                                    continuation.finish()
                                    return
                                }
                            }
                        }
                    }
                    // 연결 종료 후 버퍼에 남은 이벤트 dispatch (COMPLETED가 마지막일 때)
                    if !eventData.isEmpty,
                       let event = parseSSEEvent(type: eventType, data: eventData) {
                        print("[SSE DEBUG] 이벤트 dispatch (연결 종료 후): \(eventType) / \(eventData.prefix(80))")
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func streamCategoryDocument(categoryId: Int) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let endpoint = "/api/v1/categories/\(categoryId)/documents/daily/stream"
                print("[SSE Category] POST 요청 시작: \(Config.baseURL + endpoint)")
                guard let url = URL(string: Config.baseURL + endpoint) else {
                    continuation.finish(throwing: APIError.invalidURL); return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.setValue("0", forHTTPHeaderField: "Content-Length")
                guard let token = KeyChainManager.shared.getAccessToken() else {
                    continuation.finish(throwing: APIError.noAccessToken); return
                }
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                do {
                    let config = URLSessionConfiguration.default
                    config.timeoutIntervalForRequest = 300
                    config.timeoutIntervalForResource = 300
                    let session = URLSession(configuration: config)
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse); return
                    }
                    if http.statusCode != 200 {
                        print("[SSE Category] HTTP 오류: \(http.statusCode)")
                        var data = Data()
                        for try await byte in bytes { data.append(byte) }
                        if let err = try? JSONDecoder().decode(SSEErrorResponse.self, from: data) {
                            print("[SSE Category] 서버 에러: code=\(err.code) message=\(err.message)")
                            continuation.finish(throwing: APIError.serverError(
                                code: err.code, message: err.message, details: nil))
                        } else {
                            let rawBody = String(data: data, encoding: .utf8) ?? "(decode fail)"
                            print("[SSE Category] 에러 바디 파싱 실패, raw=\(rawBody.prefix(200))")
                            continuation.finish(throwing: APIError.serverError(
                                code: "SSE-\(http.statusCode)",
                                message: "카테고리 스트림 연결 실패", details: nil))
                        }
                        return
                    }

                    print("[SSE Category] 연결 성공 (status \(http.statusCode)), 라인 수신 시작")
                    var eventType = ""
                    var eventData = ""
                    var rawBuffer: [String] = []

                    for try await line in bytes.lines {
                        if line.isEmpty {
                            // 표준 SSE 빈줄 구분자
                            if !eventType.isEmpty {
                                if let event = parseCategorySSEEvent(type: eventType, data: eventData) {
                                    continuation.yield(event)
                                }
                                eventType = ""; eventData = ""
                            }
                        } else if line.hasPrefix("event:") {
                            // 새 event: 라인 도착 → 이전 이벤트를 먼저 flush
                            // 서버가 빈줄 없이 event:/data: 를 연속으로 전송하는 경우 대응
                            if !eventType.isEmpty {
                                if let event = parseCategorySSEEvent(type: eventType, data: eventData) {
                                    continuation.yield(event)
                                }
                            }
                            eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                            eventData = ""
                        } else if line.hasPrefix("data:") {
                            // leading space 보존: 서버가 단어 앞 공백을 "data: word" 형태로 전송
                            let value = String(line.dropFirst(5))
                            eventData = eventData.isEmpty ? value : eventData + "\n" + value
                        } else {
                            // SSE 형식이 아닌 raw 라인 — JSON 에러 본문일 수 있음
                            rawBuffer.append(line)
                        }
                    }
                    // 마지막 이벤트 처리 (빈줄 없이 스트림이 종료된 경우)
                    if !eventType.isEmpty {
                        if let event = parseCategorySSEEvent(type: eventType, data: eventData) {
                            continuation.yield(event)
                        }
                    }
                    // 스트림 본문에 raw JSON 에러가 섞여있는지 확인 (서버가 HTTP 200으로 에러 반환하는 케이스)
                    let rawBody = rawBuffer.joined(separator: "\n")
                    if !rawBody.isEmpty,
                       let bodyData = rawBody.data(using: .utf8),
                       let err = try? JSONDecoder().decode(SSEErrorResponse.self, from: bodyData) {
                        print("[SSE Category] 스트림 내 JSON 에러 감지: code=\(err.code) message=\(err.message)")
                        continuation.finish(throwing: APIError.serverError(
                            code: err.code, message: err.message, details: nil))
                    } else {
                        print("[SSE Category] 스트림 EOF → .completed yield")
                        continuation.yield(.completed)
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func parseCategorySSEEvent(type: String, data: String) -> CategoryStreamEvent? {
        switch type.lowercased() {
        case "connect": return .connected
        case "message": return data.isEmpty ? nil : .textChunk(data)
        case "title":   return data.isEmpty ? nil : .titleChunk(data)
        default:        return nil
        }
    }

    private func parseSSEEvent(type: String, data: String) -> SSEDocumentStatus? {
        guard let jsonData = data.data(using: .utf8),
              let payload = try? JSONDecoder().decode(SSEDataPayload.self, from: jsonData) else {
            return nil
        }
        switch payload.status {
        case "CONNECTED": return .connected
        case "PENDING":   return .pending
        case "PROCESSING": return .processing(remainMs: payload.remain ?? 0)
        case "COMPLETED":  return .completed
        case "FAILED":
            let reason = SSEFailureReason(rawValue: payload.reason ?? "") ?? .serverError
            return .failed(reason: reason)
        default: return nil
        }
    }
}
