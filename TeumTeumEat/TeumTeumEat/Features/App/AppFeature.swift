//
//  AppFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture
import OnboardingFeature
import FirebaseMessaging

@Reducer
struct AppFeature {
    @Dependency(\.apiClient) var apiClient

    @ObservableState
    struct State: Equatable {
        var splash: SplashFeature.State = .init()
        var login: LoginFeature.State?
        var onboarding: OnboardingFeature.State?
        var mainTab: MainTabFeature.State?
        var isShowingSplash = true
    }
    
    enum Action {
        case splash(SplashFeature.Action)
        case login(LoginFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case mainTab(MainTabFeature.Action)
        case logout
        case logoutFinalize
        case withdrawal
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
                // 디바이스 토큰 삭제 후 KeyChain 삭제 (순서 중요: 인증 토큰이 있어야 API 호출 가능)
                return .run { [apiClient] send in
                    await deleteCurrentDeviceToken(apiClient: apiClient)
                    await send(.logoutFinalize)
                }

            case .logoutFinalize:
                KeyChainManager.shared.deleteAll()

                state.login = nil
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
                    // 온보딩 완료 → 메인 화면
                    print("로그인 성공 & 온보딩 완료 - 메인 화면으로 이동")
                    state.mainTab = MainTabFeature.State()
                } else {
                    // 온보딩 미완료 → 온보딩 화면
                    state.onboarding = OnboardingFeature.State()
                }

                // 로그인 성공 직후 디바이스 토큰 등록 (로그아웃 후 재로그인 포함)
                return .run { [apiClient] _ in
                    await registerCurrentFCMToken(apiClient: apiClient)
                }
                
            // Onboarding Delegate
            case .onboarding(.complete(.startButtonTapped)):
                state.onboarding = nil
                print("온보딩 완료 - 메인 화면으로 이동 예정")
                UserDefaultsManager.isOnboardingCompleted = true
                AnalyticsManager.logOnboardingComplete()
                state.mainTab = MainTabFeature.State()

                // 온보딩 완료 직후 디바이스 토큰 등록 (신규 유저 푸시 알림 누락 방지)
                return .run { [apiClient] _ in
                    await registerCurrentFCMToken(apiClient: apiClient)
                }
                
            case .mainTab(.delegate(.withdrawal)):
                print("AppFeature: 회원탈퇴 요청 받음")
                return .send(.withdrawal)
                
            case .withdrawal:
                print("회원탈퇴 처리 시작")
                
                // 토큰 삭제
                KeyChainManager.shared.deleteAll()
                
                // 모든 상태 초기화
                state.login = nil
                state.onboarding = nil
                state.mainTab = nil
                
                // 로그인 화면으로
                state.login = LoginFeature.State()
                
                print("회원탈퇴 완료 - 로그인 화면으로 이동")
                
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

// MARK: - Private Helpers

private func currentFCMToken() async -> String? {
    await MainActor.run(resultType: String?.self) {
        Messaging.messaging().fcmToken
    }
}

private func registerCurrentFCMToken(apiClient: APIClient) async {
    guard let fcmToken = await currentFCMToken() else {
        print("FCM 토큰 없음 - 디바이스 토큰 등록 스킵")
        return
    }

    do {
        try await apiClient.registerDeviceToken(token: fcmToken, deviceType: "IOS")
        print("디바이스 토큰 등록 완료")
    } catch {
        print("디바이스 토큰 등록 실패: \(error)")
    }
}

private func deleteCurrentDeviceToken(apiClient: APIClient) async {
    guard let fcmToken = await currentFCMToken() else {
        print("FCM 토큰 없음 - 디바이스 토큰 삭제 스킵")
        return
    }

    do {
        try await apiClient.deleteDeviceToken(token: fcmToken, deviceType: "IOS")
        print("디바이스 토큰 삭제 완료")
    } catch {
        // 삭제 실패해도 로그아웃은 계속 진행
        print("디바이스 토큰 삭제 실패 (로그아웃 계속 진행): \(error)")
    }
}
