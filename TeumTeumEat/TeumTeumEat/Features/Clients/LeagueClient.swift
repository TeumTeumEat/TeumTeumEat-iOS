//
//  LeagueClient.swift
//  TeumTeumEat
//

import ComposableArchitecture

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
            return .mock
        }
    )

    static let previewValue = LeagueClient(
        fetchLeague: { .mock }
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
