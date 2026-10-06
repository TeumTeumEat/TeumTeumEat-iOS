//
//  LeagueFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct LeagueFeatureTests {
    @Test("첫 진입 시 리그 랭킹을 조회한다")
    func onAppear_loadsLeague() async {
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { .mock }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mock
        }
    }

    @Test("이미 조회한 리그가 있으면 다시 진입해도 조회하지 않는다")
    func onAppear_withLoadedLeague_doesNotRefetch() async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        }

        await store.send(.onAppear)
    }

    @Test("조회에 실패하면 에러 메시지를 보여주고, 다시 시도하면 에러를 지우고 다시 조회한다")
    func loadFailure_thenRetry_loadsLeague() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = {
                if shouldFail.value {
                    throw APIError.networkError(URLError(.notConnectedToInternet))
                }
                return .mockInactive
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }

        shouldFail.setValue(false)
        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mockInactive
        }
    }

    @Test("뒤로가기를 누르면 화면을 닫는다")
    func backTapped_dismisses() async {
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { isDismissed.setValue(true) }
        }

        await store.send(.backTapped)
        #expect(isDismissed.value)
    }
}
