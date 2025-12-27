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
        var onboarding: OnboardingFeature.State?
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case splashCompleted
        case onboarding(OnboardingFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splash(.checkAuthenticationComplete):
                state.isShowingSplash = false
                state.onboarding = OnboardingFeature.State()
                return .send(.splashCompleted)
            case .splashCompleted:
                return .none
            case .splash, .onboarding:
                return .none
            }
        }
        .ifLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
