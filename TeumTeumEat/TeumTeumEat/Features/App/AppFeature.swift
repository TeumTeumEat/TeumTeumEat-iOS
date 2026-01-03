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
        var login: LoginFeature.State?
        var termsAgreement: TermsAgreementFeature.State?
        var onboarding: OnboardingFeature.State?
        var mainTab: MainTabFeature.State?
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case login(LoginFeature.Action)
        case termsAgreement(TermsAgreementFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case mainTab(MainTabFeature.Action)
        case logout
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
                
            case .mainTab(.delegate(.logout)):
                print("AppFeature: 로그아웃 요청 받음")
                return .send(.logout)
                
            case .logout:
                // 토큰 삭제
                KeyChainManager.shared.deleteAll()
                
                state.login = nil
                state.termsAgreement = nil
                state.onboarding = nil
                state.mainTab = nil
                
                // 로그인 화면으로
                state.login = LoginFeature.State()
                
                print("로그아웃 완료 - 로그인 화면으로 이동")
                
                return .none
            // Splash
            case .splash(.authenticationChecked(let authState)):
                state.isShowingSplash = false
                
                switch authState {
                case .authenticated(let isOnboardingCompleted):
                    if isOnboardingCompleted {
                        // 온보딩 완료 → 메인 화면
                        print("토큰 있음 & 온보딩 완료 → 메인")
                        state.mainTab = MainTabFeature.State()
                    } else {
                        // 온보딩 미완료 → 온보딩 화면
                        print("토큰 있음 & 온보딩 미완료 → 온보딩")
                        state.onboarding = OnboardingFeature.State()
                    }
                    
                case .unauthenticated:
                    // 토큰 없음 → 로그인 화면
                    print("토큰 없음 → 로그인")
                    state.login = LoginFeature.State()
                }
                return .none
                
            // Login Delegate
            case .login(.delegate(.loginSuccess(let accessToken, let refreshToken, let isOnboardingCompleted))):
                state.login = nil
                UserDefaultsManager.isOnboardingCompleted = isOnboardingCompleted
                
                if isOnboardingCompleted {
                    // 온보딩 완료 → TODO: 메인 화면
                    print("로그인 성공 & 온보딩 완료 - 메인 화면으로 이동")
                    state.mainTab = MainTabFeature.State()
                } else {
                    // 온보딩 미완료 → 온보딩 화면
                    state.onboarding = OnboardingFeature.State()
                }
                return .none
                
            // TermsAgreement Delegate
            case .termsAgreement(.delegate(.signUpSuccess)):
                // 약관 동의 & 회원가입 성공 → 온보딩 화면
                state.termsAgreement = nil
                state.onboarding = OnboardingFeature.State()
                return .none
                
            // Onboarding Delegate
            case .onboarding(.complete(.startButtonTapped)):
                // 온보딩 완료 → TODO: 메인 화면 (나중에 구현)
                state.onboarding = nil
                print("온보딩 완료 - 메인 화면으로 이동 예정")
                UserDefaultsManager.isOnboardingCompleted = true
                state.mainTab = MainTabFeature.State()
                return .none
                
            case .splash, .login, .termsAgreement, .onboarding, .mainTab:
                return .none
            }
        }
        .ifLet(\.login, action: \.login) {
            LoginFeature()
        }
        .ifLet(\.termsAgreement, action: \.termsAgreement) {
            TermsAgreementFeature()
        }
        .ifLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifLet(\.mainTab, action: \.mainTab) {  
            MainTabFeature()
        }
    }
}
