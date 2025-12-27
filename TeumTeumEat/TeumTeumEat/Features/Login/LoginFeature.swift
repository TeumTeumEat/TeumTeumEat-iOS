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
    }
    
    enum Action {
        case kakaoLoginTapped
        case appleLoginTapped
        
        case loginResponse(Result<SocialLoginResponse, Error>)
        case delegate(Delegate)
        
        enum Delegate {
            case loginSuccess(accessToken: String, refreshToken: String)
            case signUpRequired(isNewUser: Bool)
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
                        // 1. 카카오 SDK로 로그인 → idToken 받기
                        let idToken = try await loginWithKakaoSDK()
                        
                        // 2. 서버에 idToken 전달
                        let response = try await loginToServer(
                            provider: "kakao",
                            idToken: idToken
                        )
                        
                        await send(.loginResponse(.success(response)))
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
                        let response = try await loginToServer(
                            provider: "apple",
                            idToken: idToken
                        )
                        await send(.loginResponse(.success(response)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                

            case .loginResponse(.success(let response)):
                state.isLoading = false
                
                guard let data = response.data else {
                    state.errorMessage = "로그인 응답 데이터가 없습니다."
                    return .none
                }
                
                // 신규 유저 체크
                if data.isNewUser == true {
                    // 토큰은 우선 저장 (약관 동의 후 회원가입에 사용)
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    
                    return .send(.delegate(.signUpRequired(isNewUser: true)))
                } else {
                    // 기존 유저 → 토큰 저장
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    
                    return .send(.delegate(.loginSuccess(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken
                    )))
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
}
