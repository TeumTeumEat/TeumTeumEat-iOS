//
//  OnboardingAPIClient.swift
//  OnboardingFeature
//

import Foundation
import Dependencies
import CoreNetwork

// MARK: - Empty Response Placeholder
struct EmptyData: Decodable {}

// MARK: - SSE Internal Types
private struct SSEDataPayload: Decodable {
    let status: String
    let remain: Int?
    let reason: String?
}

private struct SSEErrorResponse: Decodable {
    let code: String
    let message: String
}

// MARK: - OnboardingAPIClient

public struct OnboardingAPIClient {
    public var updateCommuteInfo: @Sendable (String, String, Int) async throws -> Void
    public var getPresignedURL: @Sendable (String, Int64) async throws -> PresignedURLData
    public var uploadFileToS3: @Sendable (URL, String) async throws -> Void
    public var createGoal: @Sendable (CreateGoalRequest.GoalType, String, CreateGoalRequest.Difficulty, String?, Int?) async throws -> Void
    public var fetchGoals: @Sendable () async throws -> [GoalResponse]
    public var registerDocument: @Sendable (Int, String, String) async throws -> Void
    public var fetchCurrentGoal: @Sendable () async throws -> GoalResponse
    public var connectDocumentSSE: @Sendable (Int, Int, String?) -> AsyncThrowingStream<SSEDocumentStatus, Error>

    public init(
        updateCommuteInfo: @escaping @Sendable (String, String, Int) async throws -> Void,
        getPresignedURL: @escaping @Sendable (String, Int64) async throws -> PresignedURLData,
        uploadFileToS3: @escaping @Sendable (URL, String) async throws -> Void,
        createGoal: @escaping @Sendable (CreateGoalRequest.GoalType, String, CreateGoalRequest.Difficulty, String?, Int?) async throws -> Void,
        fetchGoals: @escaping @Sendable () async throws -> [GoalResponse],
        registerDocument: @escaping @Sendable (Int, String, String) async throws -> Void,
        fetchCurrentGoal: @escaping @Sendable () async throws -> GoalResponse,
        connectDocumentSSE: @escaping @Sendable (Int, Int, String?) -> AsyncThrowingStream<SSEDocumentStatus, Error>
    ) {
        self.updateCommuteInfo = updateCommuteInfo
        self.getPresignedURL = getPresignedURL
        self.uploadFileToS3 = uploadFileToS3
        self.createGoal = createGoal
        self.fetchGoals = fetchGoals
        self.registerDocument = registerDocument
        self.fetchCurrentGoal = fetchCurrentGoal
        self.connectDocumentSSE = connectDocumentSSE
    }
}

// MARK: - DependencyKey

extension OnboardingAPIClient: DependencyKey {
    public static let liveValue: OnboardingAPIClient = {
        let client = APIClient()

        return OnboardingAPIClient(
            updateCommuteInfo: { startTime, endTime, usageTime in
                let response: APIResponse<EmptyData> = try await client.request(
                    endpoint: "/api/v1/users/commute-info",
                    method: .patch,
                    body: UpdateCommuteInfoRequest(startTime: startTime, endTime: endTime, usageTime: usageTime)
                )
                guard response.code == "OK" else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
            },
            getPresignedURL: { fileName, fileSize in
                let response: APIResponse<PresignedURLData> = try await client.request(
                    endpoint: "/api/v1/s3/presigned",
                    method: .post,
                    body: PresignedURLRequest(fileName: fileName, fileSize: fileSize)
                )
                guard response.code == "OK", let data = response.data else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
                return data
            },
            uploadFileToS3: { fileURL, presignedURL in
                guard let url = URL(string: presignedURL) else {
                    throw APIError.invalidURL
                }
                let fileData = try Data(contentsOf: fileURL)
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
                request.httpBody = fileData
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
            },
            createGoal: { type, studyPeriod, difficulty, prompt, categoryId in
                let response: APIResponse<EmptyData> = try await client.request(
                    endpoint: "/api/v1/goals",
                    method: .post,
                    body: CreateGoalRequest(
                        type: type,
                        studyPeriod: studyPeriod,
                        difficulty: difficulty,
                        prompt: prompt,
                        categoryId: categoryId
                    )
                )
                guard response.code == "OK" else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
            },
            fetchGoals: {
                let response: APIResponse<GoalListData> = try await client.request(
                    endpoint: "/api/v1/goals",
                    method: .get
                )
                guard response.code == "OK", let data = response.data else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
                return data.goalResponses
            },
            registerDocument: { goalId, fileName, fileKey in
                let response: APIResponse<EmptyData> = try await client.request(
                    endpoint: "/api/v1/goals/\(goalId)/documents",
                    method: .post,
                    body: RegisterDocumentRequest(fileName: fileName, fileKey: fileKey)
                )
                guard response.code == "OK" else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
            },
            fetchCurrentGoal: {
                let response: APIResponse<GoalResponse> = try await client.request(
                    endpoint: "/api/v1/users/goal",
                    method: .get
                )
                guard response.code == "OK", let goal = response.data else {
                    throw APIError.serverError(code: response.code, message: response.message, details: response.details)
                }
                return goal
            },
            connectDocumentSSE: { goalId, documentId, lastEventId in
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
                        if let lastEventId {
                            request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-ID")
                        }
                        do {
                            let config = URLSessionConfiguration.default
                            config.timeoutIntervalForRequest = 600
                            config.timeoutIntervalForResource = 600
                            let session = URLSession(configuration: config)
                            let (bytes, response) = try await session.bytes(for: request)
                            guard let http = response as? HTTPURLResponse else {
                                continuation.finish(throwing: APIError.invalidResponse)
                                return
                            }
                            if http.statusCode != 200 {
                                continuation.finish(throwing: APIError.serverError(
                                    code: "SSE-\(http.statusCode)",
                                    message: "SSE 연결 실패",
                                    details: nil
                                ))
                                return
                            }
                            var eventType = ""
                            var eventData = ""
                            for try await line in bytes.lines {
                                if line.isEmpty || line.hasPrefix("id:") {
                                    if !eventData.isEmpty,
                                       let event = parseSSEEvent(type: eventType, data: eventData) {
                                        continuation.yield(event)
                                        if case .completed = event { continuation.finish(); return }
                                        if case .failed = event { continuation.finish(); return }
                                    }
                                    eventType = ""; eventData = ""
                                } else if line.hasPrefix("event:") {
                                    eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                                } else if line.hasPrefix("data:") {
                                    let value = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                                    eventData = eventData.isEmpty ? value : eventData + "\n" + value
                                    if let event = parseSSEEvent(type: eventType, data: eventData) {
                                        if case .completed = event {
                                            continuation.yield(event); continuation.finish(); return
                                        }
                                        if case .failed = event {
                                            continuation.yield(event); continuation.finish(); return
                                        }
                                    }
                                }
                            }
                            if !eventData.isEmpty,
                               let event = parseSSEEvent(type: eventType, data: eventData) {
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
        )
    }()

    public static let testValue = OnboardingAPIClient(
        updateCommuteInfo: { _, _, _ in },
        getPresignedURL: { _, _ in PresignedURLData(presignedUrl: "https://mock.s3.url", key: "mock-key") },
        uploadFileToS3: { _, _ in },
        createGoal: { _, _, _, _, _ in },
        fetchGoals: { [] },
        registerDocument: { _, _, _ in },
        fetchCurrentGoal: {
            GoalResponse(
                goalId: 1, type: "CATEGORY",
                startDate: "2025-01-01", endDate: "2025-01-08",
                studyPeriod: "1주", difficulty: "MEDIUM",
                prompt: nil, fileName: nil, category: nil,
                documentId: nil, isExpired: false, isCompleted: false
            )
        },
        connectDocumentSSE: { _, _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed)
                continuation.finish()
            }
        }
    )
}

public extension DependencyValues {
    var onboardingAPIClient: OnboardingAPIClient {
        get { self[OnboardingAPIClient.self] }
        set { self[OnboardingAPIClient.self] = newValue }
    }
}

// MARK: - SSE Parser
private func parseSSEEvent(type: String, data: String) -> SSEDocumentStatus? {
    guard let jsonData = data.data(using: .utf8),
          let payload = try? JSONDecoder().decode(SSEDataPayload.self, from: jsonData) else {
        return nil
    }
    switch payload.status {
    case "CONNECTED":  return .connected
    case "PENDING":    return .pending
    case "PROCESSING": return .processing(remainMs: payload.remain ?? 0)
    case "COMPLETED":  return .completed
    case "FAILED":
        let reason = SSEFailureReason(rawValue: payload.reason ?? "") ?? .serverError
        return .failed(reason: reason)
    default: return nil
    }
}
