//
//  HistoryClient.swift
//  TeumTeumEat
//

import ComposableArchitecture

/// 학습 기록(캘린더 / 히스토리) API
@DependencyClient
struct HistoryClient {
    var fetchCalendarHistory: @Sendable (_ year: Int, _ month: Int) async throws -> CalendarHistoryData
    var fetchHistoryByDate: @Sendable (String) async throws -> [HistoryItemResponse]
    var fetchHistoryTopics: @Sendable () async throws -> [HistoryCategoryResponse]
    var fetchQuizHistoryDetails: @Sendable (_ type: DocumentType, _ id: Int, _ date: String) async throws -> QuizHistoryDetailData
    var fetchHistorySummaryDetail: @Sendable (_ type: DocumentType, _ id: Int, _ date: String) async throws -> HistorySummaryDetailData
}

extension HistoryClient: DependencyKey {
    static let liveValue: HistoryClient = {
        let api = APIClient.liveValue
        return HistoryClient(
            fetchCalendarHistory: { try await api.fetchCalendarHistory(year: $0, month: $1) },
            fetchHistoryByDate: { try await api.fetchHistoryByDate($0) },
            fetchHistoryTopics: { try await api.fetchHistoryTopics() },
            fetchQuizHistoryDetails: { try await api.fetchQuizHistoryDetails(type: $0, id: $1, date: $2) },
            fetchHistorySummaryDetail: { try await api.fetchHistorySummaryDetail(type: $0, id: $1, date: $2) }
        )
    }()

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = HistoryClient()
}

extension DependencyValues {
    var historyClient: HistoryClient {
        get { self[HistoryClient.self] }
        set { self[HistoryClient.self] = newValue }
    }
}
