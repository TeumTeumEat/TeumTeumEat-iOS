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
        var mainTab: MainTabFeature.State?
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case splashCompleted
        case onboarding(OnboardingFeature.Action)
        case mainTab(MainTabFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .splash(.authenticationChecked(let authState)):
                state.isShowingSplash = false
                
                switch authState {
                case .authenticated:
                    // 토큰 있음 → 메인 화면
                    state.mainTab = MainTabFeature.State()
                    
                case .unauthenticated:
                    // 토큰 없음 → 로그인 화면
                    state.login = LoginFeature.State()
                }
                return .none
                
            case .splash, .login, .onboarding, .mainTab:
                return .none
            }
        }
        .ifLet(\.login, action: \.login) {
            LoginFeature()
        }
        .ifLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
    }
}
