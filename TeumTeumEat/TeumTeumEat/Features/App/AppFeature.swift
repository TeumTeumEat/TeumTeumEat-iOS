//
//  AppFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var splash: SplashFeature.State = .init()
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case splashCompleted
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splash(.checkAuthenticationComplete):
                state.isShowingSplash = false
                return .send(.splashCompleted)
            case .splashCompleted:
                return .none
            case .splash:
                return .none
            }
        }
    }
}
