//
//  LeagueClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import CoreNetwork
import Foundation

/// 주간 리그 API
@DependencyClient
struct LeagueClient {
    var fetchLeague: @Sendable () async throws -> LeagueResponse
    var fetchMyRank: @Sendable () async throws -> LeagueMyRank
    var fetchLatestResult: @Sendable () async throws -> LeagueWeekResult
    /// 마지막으로 결과 모달을 보여준 주차
    var lastSeenResultWeek: @Sendable () -> String? = { nil }
    var setLastSeenResultWeek: @Sendable (_ weekStartDate: String) -> Void
}

extension LeagueClient: DependencyKey {
    static let liveValue: LeagueClient = {
        let api = APIClient.liveValue
        return LeagueClient(
            fetchLeague: { try await api.fetchLeague() },
            fetchMyRank: { try await api.fetchLeagueMyRank() },
            fetchLatestResult: { try await api.fetchLatestLeagueResult() },
            lastSeenResultWeek: { UserDefaultsManager.leagueLastSeenResultWeek },
            setLastSeenResultWeek: { UserDefaultsManager.leagueLastSeenResultWeek = $0 }
        )
    }()

    static let previewValue = LeagueClient(
        fetchLeague: { .mock },
        fetchMyRank: { LeagueResponse.mock.me },
        fetchLatestResult: { .mock },
        lastSeenResultWeek: { nil },
        setLastSeenResultWeek: { _ in }
    )

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = LeagueClient()
}

extension DependencyValues {
    var leagueClient: LeagueClient {
        get { self[LeagueClient.self] }
        set { self[LeagueClient.self] = newValue }
    }
}
