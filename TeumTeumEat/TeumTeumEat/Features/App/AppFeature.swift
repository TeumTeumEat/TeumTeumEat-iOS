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
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case login(LoginFeature.Action)
        case termsAgreement(TermsAgreementFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case logout
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        
        Reduce { state, action in
            switch action {
                
            case .logout:
                // 토큰 삭제
                KeyChainManager.shared.deleteAll()
                
                state.login = nil
                state.termsAgreement = nil
                state.onboarding = nil
                
                // 로그인 화면으로
                state.login = LoginFeature.State()
                
                print("로그아웃 완료 - 로그인 화면으로 이동")
                
                return .none
            // Splash
            case .splash(.authenticationChecked(let authState)):
                state.isShowingSplash = false
                
                switch authState {
                case .authenticated:
                    // 토큰 있음 → TODO: 메인 화면
                    print("인증됨 - 메인 화면으로 이동 예정")
                    
                case .unauthenticated:
                    // 토큰 없음 → 로그인 화면
                    state.login = LoginFeature.State()
                }
                return .none
                
            // Login Delegate
            case .login(.delegate(.loginSuccess(let accessToken, let refreshToken, let isOnboardingCompleted))):
                state.login = nil
                
                if isOnboardingCompleted {
                    // 온보딩 완료 → TODO: 메인 화면
                    print("로그인 성공 & 온보딩 완료 - 메인 화면으로 이동 예정")
                } else {
                    // 온보딩 미완료 → 온보딩 화면
                    state.onboarding = OnboardingFeature.State()
                }
                return .none
                
            case .login(.delegate(.needsTermsAgreement(let idToken))):
                // 신규 유저 → 약관 동의 화면
                state.login = nil
                state.termsAgreement = TermsAgreementFeature.State(idToken: idToken)
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
                return .none
                
            case .splash, .login, .termsAgreement, .onboarding:
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
    }
}
