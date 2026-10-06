//
//  LeagueClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import Foundation

/// 주간 리그 API
@DependencyClient
struct LeagueClient {
    var fetchLeague: @Sendable () async throws -> LeagueResponse
}

extension LeagueClient: DependencyKey {
    // TODO: API 스펙 확정 후 APIClient endpoint로 교체 (현재는 mock 데이터)
    static let liveValue = LeagueClient(
        fetchLeague: {
            // 로딩 상태 확인용 네트워크 지연
            try await Task.sleep(for: .milliseconds(500))
            return .mock.endingNextSundayMidnight()
        }
    )

    static let previewValue = LeagueClient(
        fetchLeague: { .mock }
    )

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = LeagueClient()
}

private extension LeagueResponse {
    /// mock 카운트다운이 실제처럼 흐르도록 마감 시각을 이번 주 일요일 자정(= 다음 월요일 0시)으로 맞춤
    func endingNextSundayMidnight() -> LeagueResponse {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let nextMonday = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: 2),
            matchingPolicy: .nextTime
        ) ?? Date()
        return LeagueResponse(
            isActive: isActive,
            weekEndAt: DateFormatters.iso8601.string(from: nextMonday),
            myRank: myRank,
            rankers: rankers
        )
    }
}

extension DependencyValues {
    var leagueClient: LeagueClient {
        get { self[LeagueClient.self] }
        set { self[LeagueClient.self] = newValue }
    }
}
