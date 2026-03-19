//
//  SplashFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI
import ComposableArchitecture
import FirebaseRemoteConfig

@Reducer
struct SplashFeature {
    struct State: Equatable {
        var isActive = false
        var showForceUpdateAlert = false
    }

    enum Action {
        case onAppear
        case checkAppVersion
        case appVersionChecked(Bool)
        case openAppStore
        case checkAuthentication
        case onboardingStatusResponse(Result<Bool, Error>)
        case authenticationChecked(AuthState)

        enum AuthState {
            case authenticated(isOnboardingCompleted: Bool)
            case unauthenticated
        }
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.openURL) var openURL

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.checkAppVersion)
                }

            case .checkAppVersion:
                return .run { send in
                    let remoteConfig = RemoteConfig.remoteConfig()
                    let settings = RemoteConfigSettings()
                    settings.minimumFetchInterval = 0 // TODO: 출시 전 3600으로 변경
                    remoteConfig.configSettings = settings
                    remoteConfig.setDefaults(["minimum_required_version": "1.0.0" as NSObject])

                    let status = try? await remoteConfig.fetchAndActivate()
                    print("[RemoteConfig] fetchAndActivate status: \(String(describing: status))")

                    let minVersion = remoteConfig["minimum_required_version"].stringValue ?? "1.0.0"
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

                    print("[RemoteConfig] minVersion: \(minVersion), currentVersion: \(currentVersion)")

                    let needsUpdate = currentVersion.compare(minVersion, options: .numeric) == .orderedAscending
                    print("[RemoteConfig] needsUpdate: \(needsUpdate)")
                    await send(.appVersionChecked(needsUpdate))
                }

            case .appVersionChecked(let needsUpdate):
                if needsUpdate {
                    state.showForceUpdateAlert = true
                    return .none
                }
                return .send(.checkAuthentication)

            case .openAppStore:
                return .run { _ in
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id YOUR_APP_ID") {
                        await openURL(url)
                    }
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
