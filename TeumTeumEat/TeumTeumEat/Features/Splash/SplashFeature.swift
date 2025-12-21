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
        case checkAuthenticationComplete
    }
    
    var body: some ReducerOf<Self> {
        Reduce {state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.checkAuthenticationComplete)
                }
            case .checkAuthenticationComplete:
                state.isActive = true
                return .none
            }
        }
    }
}
