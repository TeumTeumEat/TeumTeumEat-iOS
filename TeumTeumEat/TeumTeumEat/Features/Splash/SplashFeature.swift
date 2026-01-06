//
//  SplashFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct SplashFeature {
    struct State: Equatable {
        var isActive = false
    }
    
    enum Action {
        case onAppear
        case checkAuthentication
        case onboardingStatusResponse(Result<Bool, Error>)
        case authenticationChecked(AuthState)
        
        enum AuthState {
            case authenticated(isOnboardingCompleted: Bool)
            case unauthenticated
        }
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.checkAuthentication)
                }
                
            case .checkAuthentication:
                return .run { send in
                    // KeyChain에서 토큰 조회
                    if KeyChainManager.shared.getAccessToken() != nil {
                        // 토큰 있음 → 서버에서 온보딩 상태 조회
                        print("토큰 있음 - 온보딩 상태 조회 시작")
                        await send(.onboardingStatusResponse(
                            Result { try await apiClient.fetchOnboardingStatus() }
                        ))
                    } else {
                        // 토큰 없음
                        print("토큰 없음 - 로그인 화면으로")
                        await send(.authenticationChecked(.unauthenticated))
                    }
                }
                
            case .onboardingStatusResponse(.success(let isCompleted)):
                print("온보딩 상태 조회 성공: \(isCompleted)")
                return .send(.authenticationChecked(.authenticated(isOnboardingCompleted: isCompleted)))
                
            case .onboardingStatusResponse(.failure(let error)):
                print("온보딩 상태 조회 실패: \(error)")
                // API 실패 시 토큰 삭제하고 로그인 화면으로
                KeyChainManager.shared.deleteAll()
                return .send(.authenticationChecked(.unauthenticated))
                
            case .authenticationChecked:
                state.isActive = true
                return .none
            }
        }
    }
}
