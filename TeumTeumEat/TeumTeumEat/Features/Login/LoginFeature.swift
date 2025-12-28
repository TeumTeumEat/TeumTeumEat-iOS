//
//  LoginFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
        var pendingIdToken: String?
    }
    
    enum Action {
        case kakaoLoginTapped
        case appleLoginTapped

        case loginAttempt(idToken: String, termsAgreed: Bool)
        case loginResponse(Result<SocialLoginResponse, Error>)
        
        case delegate(Delegate)
        
        enum Delegate {
            case loginSuccess(accessToken: String, refreshToken: String, isOnboardingCompleted: Bool)
            case needsTermsAgreement(idToken: String)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .kakaoLoginTapped:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let idToken = try await loginWithKakaoSDK()
                        await send(.loginAttempt(idToken: idToken, termsAgreed: false))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case .appleLoginTapped:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let idToken = try await loginWithAppleSDK()
                        await send(.loginAttempt(idToken: idToken, termsAgreed: false))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case .loginAttempt(let idToken, let termsAgreed):
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let response = try await loginToServer(
                            idToken: idToken,
                            termsAgreed: termsAgreed
                        )
                        await send(.loginResponse(.success(response)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case .loginResponse(.success(let response)):
                state.isLoading = false
                
                if response.code == "OK" {
                    // 로그인 성공 (기존 유저 또는 약관 동의 완료한 신규 유저)
                    guard let data = response.data else {
                        state.errorMessage = "응답 데이터가 없습니다."
                        return .none
                    }
                    
                    // 토큰 저장
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    
                    return .send(.delegate(.loginSuccess(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken,
                        isOnboardingCompleted: data.isOnboardingCompleted
                    )))
                    
                } else if response.code == "NEED_TERMS_AGREEMENT" {
                    // 신규 유저 → 약관 동의 필요
                    // pendingIdToken은 이미 state에 저장되어 있음
                    return .send(.delegate(.needsTermsAgreement(idToken: state.pendingIdToken ?? "")))
                    
                } else {
                    // 기타 에러
                    state.errorMessage = response.message
                    return .none
                }
                
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

extension LoginFeature {
    private func loginWithKakaoSDK() async throws -> String {
        // TODO: 카카오 SDK 연동
        fatalError("카카오 SDK 연동 필요")
    }
    
    private func loginWithAppleSDK() async throws -> String {
        // TODO: Apple SDK 연동
        fatalError("Apple SDK 연동 필요")
    }
    
    private func loginToServer(idToken: String, termsAgreed: Bool) async throws -> SocialLoginResponse {
        let url = URL(string: "")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SocialLoginRequest(termsAgreed: termsAgreed)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SocialLoginResponse.self, from: data)
        
        return response
    }
}
