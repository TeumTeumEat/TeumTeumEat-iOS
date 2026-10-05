//
//  APIClient+Endpoints.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import Foundation
import Dependencies
import CoreNetwork
import OnboardingFeature

// 공통 request / 토큰 재발급 / DependencyKey는 CoreNetwork.APIClient에 있음
// 이 파일은 앱 기능별 엔드포인트만 정의


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
        Log.network.debug("User name updated successfully: \(name)")
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
           
           Log.network.debug("Commute info updated successfully - Start: \(startTime), End: \(endTime), Usage: \(usageTime)분")
       }
}

extension APIClient {
    /// 전체 목표 목록 조회
    func fetchGoals() async throws -> [GoalResponse] {
        let response: APIResponse<GoalListData> = try await request(
            endpoint: "/api/v1/goals",
            method: .get,
            requiresAuth: true
        )
        
        Log.network.debug("Response code: \(response.code)")
        Log.network.debug("Response data: \(String(describing: response.data))")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        Log.network.debug("Goals fetched - Count: \(data.goalResponses.count)")
        data.goalResponses.forEach { goal in
            Log.network.debug("[Goal] id:\(goal.goalId) type:\(goal.type) isExpired:\(goal.isExpired) isCompleted:\(goal.isCompleted) period:\(goal.studyPeriod) difficulty:\(goal.difficulty) start:\(goal.startDate) end:\(goal.endDate)")
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
        
        Log.network.debug("fetchCurrentGoal - Response code: \(response.code)")
        Log.network.debug("fetchCurrentGoal - Response data: \(String(describing: response.data))")
        
        guard response.code == "OK",
              let goal = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        Log.network.debug("Current Goal - ID: \(goal.goalId), Type: \(goal.type)")
        if let category = goal.category {
            Log.network.debug("CategoryId: \(category.categoryId), Name: \(category.name)")
        }
        
        return goal
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
        
        Log.network.debug("User account info fetched - Provider: \(data.socialProvider), Email: \(data.email)")
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
        
        Log.network.debug("Notification settings fetched - pushEnabled: \(data.pushEnabled)")
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
        
        Log.network.debug("Notification setting updated - pushEnabled: \(pushEnabled)")
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

        Log.network.debug("[QuizStatus] hasSolvedToday: \(statusData.hasSolvedToday), hasCreatedToday: \(statusData.hasCreatedToday), availableCount: \(statusData.availableQuizCount)")
        
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

    /// PDF 요약글 GET only (이미 생성된 것만 반환, 없으면 에러)
    func fetchPDFSummaryOnly(goalId: Int, documentId: Int) async throws -> PDFSummaryData {
        return try await fetchPDFSummaryGET(endpoint: "/api/v1/goals/\(goalId)/documents/\(documentId)/summary")
    }

    /// PDF SSE 이후 퀴즈 생성 보장 후 조회
    /// SSE는 요약글 텍스트만 스트리밍하고 퀴즈는 생성하지 않으므로
    /// POST /summary 로 퀴즈 생성을 트리거한 뒤 GET quizzes 반환
    func createAndFetchPDFQuizzes(goalId: Int, documentId: Int) async throws -> [UserQuiz] {
        let endpoint = "/api/v1/goals/\(goalId)/documents/\(documentId)/summary"
        do {
            let _: APIResponse<EmptyData> = try await request(
                endpoint: endpoint, method: .post, requiresAuth: true
            )
            Log.network.debug("[PDFQuizzes] POST 성공 - 퀴즈 생성 완료")
        } catch let apiError as APIError {
            if case .serverError(let code, _, _) = apiError, code == "QUIZ-003" {
                // 이미 생성됨
                Log.network.debug("[PDFQuizzes] QUIZ-003 - 기존 요약/퀴즈 존재")
            } else {
                throw apiError
            }
        }
        return try await fetchUserQuizzes(documentId: documentId, documentType: .document)
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

        Log.network.debug("[UserQuizzes] count: \(quizzes.count)")
        
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
        
        Log.network.debug(" submitQuizAnswer - Response code: \(response.code)")
        Log.network.debug(" submitQuizAnswer - QuizId: \(quizId), Answer: \(userAnswer)")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        Log.network.debug(" Quiz Answer Submitted - isCorrect: \(data.isCorrect)")
        Log.network.debug("   Correct Answer: \(data.correctAnswer)")
        Log.network.debug("   Explanation: \(data.explanation)")
        
        return data
    }
    
    /// 주제별 히스토리 내역 확인
    func fetchHistoryTopics() async throws -> [HistoryCategoryResponse] {
        let response: APIResponse<[HistoryCategoryResponse]> = try await request(
            endpoint: "/api/v1/history/topics",
            method: .get,
            requiresAuth: true
        )
        
        Log.network.debug("Response code: \(response.code)")
        
        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }
        
        Log.network.debug("History topics fetched successfully - Category Count: \(data.count)")
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
        
        Log.network.debug(" Calendar history fetched: \(data.stampedDates.count) stamps found.")
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
        
        Log.network.debug("History for \(date) fetched: \(data.count) items found.")
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
        
        Log.network.debug("\(typePath) (ID: \(id)) 퀴즈 내역 조회 성공: \(data.quizzes.count)문항")
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
        
        Log.network.debug("Summary fetched: \(data.title) (Date: \(date))")
        return data
    }
    
    /// 현재 목표 업데이트 (선택한 목표로 변경)
        func updateCurrentGoal(goalId: Int) async throws {
            let response: APIResponse<EmptyData> = try await request(
                endpoint: "/api/v1/users/goal?goalId=\(goalId)",
                method: .patch,
                requiresAuth: true
            )
            
            Log.network.debug("updateCurrentGoal - Response code: \(response.code)")
            
            guard response.code == "OK" else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            Log.network.debug("Current goal updated successfully - goalId: \(goalId)")
        }
    
    /// 회원탈퇴
        func withdrawUser() async throws {
            let response: APIResponse<EmptyData> = try await request(
                endpoint: "/api/v1/users/withdrawal",
                method: .delete,
                requiresAuth: true
            )
            
            Log.network.debug("withdrawUser - Response code: \(response.code)")
            
            guard response.code == "OK" else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            Log.network.debug("User withdrawal successful")
        }
    
    
    /// 유저 이름 조회
        func fetchUserName() async throws -> String {
            let response: APIResponse<UserNameData> = try await request(
                endpoint: "/api/v1/users/name",
                method: .get,
                requiresAuth: true
            )
            
            Log.network.debug("fetchUserName - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            Log.network.debug("User name fetched successfully: \(data.name)")
            return data.name
        }
        
        /// 출퇴근 정보 조회
        func fetchCommuteInfo() async throws -> CommuteInfoData {
            let response: APIResponse<CommuteInfoData> = try await request(
                endpoint: "/api/v1/users/commute-info",
                method: .get,
                requiresAuth: true
            )
            
            Log.network.debug("fetchCommuteInfo - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            Log.network.debug("Commute info fetched successfully")
            Log.network.debug("   Start: \(data.startTime), End: \(data.endTime), Usage: \(data.usageTime)분")
            return data
        }
    
    /// 온보딩 완료 여부 조회
        func fetchOnboardingStatus() async throws -> Bool {
            let response: APIResponse<OnboardingStatusData> = try await request(
                endpoint: "/api/v1/users/onboarding-completed",
                method: .get,
                requiresAuth: true
            )
            
            Log.network.debug("fetchOnboardingStatus - Response code: \(response.code)")
            
            guard response.code == "OK",
                  let data = response.data else {
                throw APIError.serverError(
                    code: response.code,
                    message: response.message,
                    details: response.details
                )
            }
            
            Log.network.debug("Onboarding status fetched: \(data.completed)")
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

        Log.network.debug("registerDeviceToken - Response code: \(response.code)")

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        Log.network.debug("Device token registered successfully")
    }

    /// 디바이스 토큰 삭제 (로그아웃 시 호출)
    func deleteDeviceToken(token: String, deviceType: String) async throws {
        let response: APIResponse<EmptyData> = try await request(
            endpoint: "/api/v1/notifications/device-tokens",
            method: .delete,
            body: RegisterDeviceTokenRequest(
                token: token,
                deviceType: deviceType
            ),
            requiresAuth: true
        )

        Log.network.debug("deleteDeviceToken - Response code: \(response.code)")

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        Log.network.debug("Device token deleted successfully")
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

        Log.network.debug("postAdReward - Response code: \(response.code)")

        guard response.code == "OK" else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        Log.network.debug("Ad reward processed successfully")
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

        Log.network.debug("[QuizFlow] 퀴즈 세트 차감 완료")
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

        Log.network.debug("updateQuizGuideSeen - Response code: \(response.code)")

        guard response.code == "OK",
              let data = response.data else {
            throw APIError.serverError(
                code: response.code,
                message: response.message,
                details: response.details
            )
        }

        Log.network.debug("Quiz guide seen status updated: \(data.isQuizGuideSeen)")
    }
}

// MARK: - SSE Helpers (file-private)
private struct SSEErrorResponse: Decodable {
    let code: String
    let message: String
}

// SSE 전용 세션 (요청마다 새로 만들면 invalidate되지 않고 메모리에 남으므로 하나를 재사용)
private let sseSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 300
    config.timeoutIntervalForResource = 300
    return URLSession(configuration: config)
}()

extension APIClient {
    func streamCategoryDocument(categoryId: Int) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        streamTextEvents(
            endpoint: "/api/v1/categories/\(categoryId)/documents/daily/stream",
            tag: "[SSE Category]",
            connectionFailureMessage: "카테고리 스트림 연결 실패"
        )
    }

    func streamPDFSummary(goalId: Int, documentId: Int) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        streamTextEvents(
            endpoint: "/api/v1/goals/\(goalId)/documents/\(documentId)/summary/stream",
            tag: "[SSE PDF]",
            connectionFailureMessage: "PDF 스트림 연결 실패"
        )
    }

    /// 요약글 텍스트 SSE 스트림 (POST) 공통 처리
    private func streamTextEvents(
        endpoint: String,
        tag: String,
        connectionFailureMessage: String
    ) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, http) = try await connectSSE(
                        endpoint: endpoint,
                        tag: tag,
                        connectionFailureMessage: connectionFailureMessage
                    )
                    Log.network.debug("\(tag) 연결 성공 (status \(http.statusCode)), 라인 수신 시작")
                    Log.network.debug("\(tag) Response Headers: \(http.allHeaderFields)")
                    try await readSSEEvents(from: bytes, tag: tag, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// SSE 연결 (액세스 토큰 만료(AUTH-002) 시 재발급 후 1회 재연결)
    /// HTTP 200이 아니면 서버 에러 코드(없으면 SSE-<status>)로 throw
    private func connectSSE(
        endpoint: String,
        tag: String,
        connectionFailureMessage: String
    ) async throws -> (bytes: URLSession.AsyncBytes, http: HTTPURLResponse) {
        Log.network.debug("\(tag) POST 요청 시작: \(Config.baseURL + endpoint)")
        guard let url = URL(string: Config.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("0", forHTTPHeaderField: "Content-Length")

        var didRefreshToken = false
        while true {
            guard let token = KeyChainManager.shared.getAccessToken() else {
                throw APIError.noAccessToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (bytes, response) = try await sseSession.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            if http.statusCode == 200 {
                return (bytes, http)
            }

            Log.network.error("\(tag) HTTP 오류: \(http.statusCode)")
            var data = Data()
            for try await byte in bytes { data.append(byte) }
            let err = try? JSONDecoder().decode(SSEErrorResponse.self, from: data)

            if err?.code == "AUTH-002", !didRefreshToken {
                Log.network.debug("\(tag) 액세스 토큰 만료 → 재발급 후 재연결")
                didRefreshToken = true
                try await self.refreshAccessToken()
                continue
            }

            if let err {
                Log.network.error("\(tag) 서버 에러: code=\(err.code) message=\(err.message)")
                throw APIError.serverError(code: err.code, message: err.message, details: nil)
            }
            let rawBody = String(data: data, encoding: .utf8) ?? "(decode fail)"
            Log.network.error("\(tag) 에러 바디 파싱 실패, raw=\(rawBody.prefix(200))")
            throw APIError.serverError(
                code: "SSE-\(http.statusCode)",
                message: connectionFailureMessage, details: nil)
        }
    }

    /// SSE 라인을 읽어 이벤트로 변환해 전달하고, 스트림이 끝나면 .completed 후 종료
    /// (HTTP 200 본문에 JSON 에러가 섞여 오면 서버 에러로 종료)
    private func readSSEEvents(
        from bytes: URLSession.AsyncBytes,
        tag: String,
        continuation: AsyncThrowingStream<CategoryStreamEvent, Error>.Continuation
    ) async throws {
        var eventType = ""
        var eventData = ""
        var rawBuffer: [String] = []
        var lineCount = 0

        for try await line in bytes.lines {
            lineCount += 1
            Log.network.debug("\(tag) RAW #\(lineCount) repr=\(line.debugDescription) bytes=\(line.utf8.count)")
            if line.isEmpty {
                // 표준 SSE 빈줄 구분자
                if !eventType.isEmpty {
                    Log.network.debug("\(tag) dispatch event=\(eventType) data=\(eventData.prefix(120))")
                    if let event = parseCategorySSEEvent(type: eventType, data: eventData) {
                        continuation.yield(event)
                    }
                    eventType = ""; eventData = ""
                }
            } else if line.hasPrefix("event:") {
                // 새 event: 라인 도착 → 이전 이벤트를 먼저 flush
                // 서버가 빈줄 없이 event:/data: 를 연속으로 전송하는 경우 대응
                if !eventType.isEmpty {
                    Log.network.debug("\(tag) flush (no empty line) event=\(eventType) data=\(eventData.prefix(120))")
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
                Log.network.debug("\(tag) non-SSE line: \(line.prefix(200))")
                rawBuffer.append(line)
            }
        }
        Log.network.debug("\(tag) 루프 종료 - 수신된 총 라인 수: \(lineCount)")
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
            Log.network.error("\(tag) 스트림 내 JSON 에러 감지: code=\(err.code) message=\(err.message)")
            continuation.finish(throwing: APIError.serverError(
                code: err.code, message: err.message, details: nil))
        } else {
            Log.network.debug("\(tag) 스트림 EOF → .completed yield")
            continuation.yield(.completed)
            continuation.finish()
        }
    }

    private func parseCategorySSEEvent(type: String, data: String) -> CategoryStreamEvent? {
        switch type.lowercased() {
        case "connect": return .connected
        case "message": return .textChunk(data.isEmpty ? "\n" : data)  // 빈 data = 줄바꿈
        case "title":   return data.isEmpty ? nil : .titleChunk(data)
        default:        return nil
        }
    }
}
