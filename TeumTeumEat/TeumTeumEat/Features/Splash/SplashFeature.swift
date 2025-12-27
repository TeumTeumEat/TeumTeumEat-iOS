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
        case authenticationChecked(AuthState)
        
        enum AuthState {
            case authenticated // 토큰 있음 + 유효
            case unauthenticated // 토근 없음 or 만료
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce {state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.checkAuthentication)
                }
                
            case .checkAuthentication:
                return .run { send in
                    // KeyChain에서 토큰 조회
                    if let accessToken = KeyChainManager.shared.getAccessToken() {
                        // TODO: 토큰 유효성 검증 API 호출
                        // 일단은 토큰 있으면 유효하다고 가정
                        await send(.authenticationChecked(.authenticated))
                    } else {
                        await send(.authenticationChecked(.unauthenticated))
                    }
                }
                
            case .authenticationChecked:
                state.isActive = true
                return .none
            }
        }
    }
}
