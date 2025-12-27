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
        var termsAgreement: TermsAgreementFeature.State?
        var mainTab: MainTabFeature.State?
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case splashCompleted
        case login(LoginFeature.Action)
        case termsAgreement(TermsAgreementFeature.Action)
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
            
            // LoginFeature Delegate 처리 추가
            case .login(.delegate(.loginSuccess)):
                // 기존 유저 로그인 성공 → 메인 화면
                state.login = nil
                state.mainTab = MainTabFeature.State()
                return .none
                
            case .login(.delegate(.signUpRequired)):
                // 신규 유저 → 약관 동의 화면으로
                state.login = nil
                state.termsAgreement = TermsAgreementFeature.State()
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
