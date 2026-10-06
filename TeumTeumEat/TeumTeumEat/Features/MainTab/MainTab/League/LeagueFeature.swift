//
//  LeagueFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture

/// 주간 리그 랭킹 화면 (Home / History에서 push로 진입)
@Reducer
struct LeagueFeature {
    @ObservableState
    struct State: Equatable {
        var league: LeagueResponse?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case retryTapped
        case backTapped
        case leagueLoaded(Result<LeagueResponse, Error>)
    }

    @Dependency(\.leagueClient) var leagueClient
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 하위 화면에서 돌아올 때 다시 조회하지 않도록 첫 진입에만 조회
                guard state.league == nil, !state.isLoading else { return .none }
                return fetchLeague(&state)

            case .retryTapped:
                return fetchLeague(&state)

            case .backTapped:
                return .run { _ in await dismiss() }

            case .leagueLoaded(.success(let league)):
                state.isLoading = false
                state.league = league
                Log.league.debug("League loaded: active=\(league.isActive), rankers=\(league.rankers.count)")
                return .none

            case .leagueLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                Log.league.error("Failed to load league: \(error)")
                return .none
            }
        }
    }

    private func fetchLeague(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            await send(.leagueLoaded(Result { try await leagueClient.fetchLeague() }))
        }
    }
}
