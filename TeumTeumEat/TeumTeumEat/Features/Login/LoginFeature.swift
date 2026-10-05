//
//  LoginFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation
import ComposableArchitecture
import KakaoSDKUser

@Reducer
struct LoginFeature {
    @Dependency(\.analyticsClient) var analyticsClient
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
        var pendingIdToken: String?
        var pendingAuthCode: String?
        var pendingProvider: SocialProvider?
        var pendingName: String?
        var showTermsSheet = false
        var isNewUser = false
    }
    
    enum SocialProvider: String {
        case kakao = "KAKAO"
        case appleProvider = "APPLE"
    }
    
    enum Action {
        case kakaoLoginTapped
        
        case appleLoginSuccess(idToken: String, authCode: String?, name: String?)
        case appleLoginFailure(Error)

        case loginAttempt(idToken: String, authCode: String?, provider: SocialProvider, termsAgreed: Bool, name: String?)
        case loginResponse(Result<SocialLoginResponse, Error>)
        
        case dismissTermsSheet
        case agreeTermsTapped
        
        case delegate(Delegate)
        
        enum Delegate {
            case loginSuccess(accessToken: String, refreshToken: String, isOnboardingCompleted: Bool)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .kakaoLoginTapped:
                Log.auth.debug("카카오 로그인 버튼 탭")
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        Log.auth.debug("카카오 SDK 로그인 시작...")
                        let kakaoIdToken = try await loginWithKakaoSDK()
                        Log.auth.debug("카카오 SDK 로그인 성공!")
                        Log.auth.debug("Token Length: \(kakaoIdToken.count)")
                        Log.auth.debug("서버 로그인 시도 (termsAgreed: false)")
                        await send(.loginAttempt(idToken: kakaoIdToken, authCode: nil, provider: .kakao, termsAgreed: false, name: nil))
                    } catch {
                        Log.auth.error("카카오 로그인 전체 실패: \(error)")
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case .appleLoginSuccess(let idToken, let authCode, let name):
                Log.auth.debug("애플 로그인 성공 - 서버 로그인 시도")
                return .send(.loginAttempt(
                    idToken: idToken,
                    authCode: authCode,
                    provider: .appleProvider,
                    termsAgreed: false,
                    name: name
                ))
                
            case .appleLoginFailure(let error):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                Log.auth.error("애플 로그인 실패: \(error)")
                return .none
                
            case .loginAttempt(let idToken, let authCode, let provider, let termsAgreed, let name):
                state.isLoading = true
                state.errorMessage = nil
                state.pendingIdToken = idToken
                state.pendingAuthCode = authCode
                state.pendingProvider = provider
                state.pendingName = name
                
                Log.auth.debug("서버 로그인 요청")
                Log.auth.debug("idToken: \(String(idToken.prefix(20)))...")
                Log.auth.debug("termsAgreed: \(termsAgreed)")
                
                return .run { send in
                    do {
                        let response = try await loginToServer(
                            idToken: idToken,
                            authCode: authCode,
                            provider: provider,
                            termsAgreed: termsAgreed,
                            name: name
                        )
                        
                        Log.auth.debug("서버 응답 수신")
                        Log.auth.debug("Response Code: \(response.code)")
                        Log.auth.debug("Message: \(response.message)")
                        
                        if let data = response.data {
                            Log.auth.debug("isOnboardingCompleted: \(data.isOnboardingCompleted)")
                        }
                        await send(.loginResponse(.success(response)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                        Log.auth.error("서버 로그인 실패")
                        Log.auth.error("Error: \(error.localizedDescription)")
                    }
                }
                
            case .loginResponse(.success(let response)):
                state.isLoading = false
                Log.auth.debug("응답 처리")
                if response.code == "OK" {
                    // 로그인 성공 (기존 유저 또는 약관 동의 완료한 신규 유저)
                    guard let data = response.data else {
                        state.errorMessage = "응답 데이터가 없습니다."
                        return .none
                    }

                    // 토큰 저장
                    Log.auth.debug("토큰 저장 중...")
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    Log.auth.debug("토큰 저장 완료")

                    // Analytics
                    let method = state.pendingProvider?.rawValue.lowercased() ?? "unknown"
                    analyticsClient.setUserProperty(.loginMethod(method))
                    if state.isNewUser {
                        analyticsClient.log(.signUp(method: method))
                    } else {
                        analyticsClient.log(.login(method: method))
                    }

                    Log.auth.debug("다음 화면 분기:")
                    if data.isOnboardingCompleted {
                        Log.auth.debug("   → 메인 화면 (온보딩 완료)")
                    } else {
                        Log.auth.debug("   → 온보딩 화면 (온보딩 미완료)")
                    }

                    return .send(.delegate(.loginSuccess(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken,
                        isOnboardingCompleted: data.isOnboardingCompleted
                    )))

                } else if response.code == "AUTH-006" {
                    // 신규 유저 → 약관 동의 필요
                    Log.auth.debug("약관 동의 필요 (신규 유저)")
                    state.isNewUser = true
                    state.showTermsSheet = true
                    return .none

                } else {
                    // 기타 에러
                    state.errorMessage = response.message
                    return .none
                }
                
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                Log.auth.error("서버 로그인 실패: \(error)")
                return .none
                
            case .dismissTermsSheet:
                state.showTermsSheet = false
                return .none
                
            case .agreeTermsTapped:
                Log.auth.debug("약관 동의 확인 - 재로그인 시도")
                state.showTermsSheet = false
                
                guard let idToken = state.pendingIdToken,
                      let provider = state.pendingProvider else {
                    state.errorMessage = "토큰 또는 Provider 정보가 없습니다."
                    return .none
                }
                
                let authCode = state.pendingAuthCode
                
                return .send(.loginAttempt(
                    idToken: idToken,
                    authCode: authCode,
                    provider: provider,
                    termsAgreed: true,
                    name: state.pendingName
                ))
            case .delegate:
                return .none
            }
        }
    }
}

extension LoginFeature {

    private func loginWithKakaoSDK() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        Log.auth.debug("카카오톡 로그인 성공")
                        continuation.resume(returning: token.idToken ?? "")
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        Log.auth.debug("카카오 계정 로그인 성공")
                        continuation.resume(returning: token.idToken ?? "")
                    }
                }
            }
        }
    }
    
    private func loginToServer(idToken: String, authCode: String?, provider: SocialProvider, termsAgreed: Bool, name: String?) async throws -> SocialLoginResponse {
        Log.auth.debug("서버 API 호출 시작")
        let baseURL = Config.baseURL
        let endPoint = "/api/v1/auth/oauth/register?provider=\(provider.rawValue)"
        let fullPath = baseURL + endPoint
        Log.auth.debug("fullpath: \(fullPath)")
        
        let url = URL(string: "\(fullPath)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SocialLoginRequest(
            idToken: idToken,
            authCode: authCode,
            termsAgreed: termsAgreed,
            name: name ?? "TestUser"
        )
        request.httpBody = try JSONEncoder().encode(body)
        

        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                Log.auth.debug("   \(key): \(value)")
            }
        } else {
            Log.auth.debug("헤더 없음")
        }
        
        Log.auth.debug("Request Body:")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            Log.auth.debug("   Raw Data: \(bodyString)")
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: bodyData),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Log.auth.debug("\n   Formatted JSON:")
                Log.auth.debug(prettyString.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n"))
            }
        } else {
            Log.auth.debug("바디 없음")
        }
        
        Log.auth.debug("Request Body 구조:")
        Log.auth.debug("   idToken: \(String(idToken.prefix(30)))... (길이: \(idToken.count))")
        Log.auth.debug("   authCode: \(authCode != nil ? "\(String(authCode!.prefix(30)))... (길이: \(authCode!.count))" : "nil")")
        Log.auth.debug("   termsAgreed: \(termsAgreed)")
        Log.auth.debug("   name: \(name ?? "nil")")
        
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        Log.auth.debug("서버 응답 수신")
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            Log.auth.debug("HTTP Status Code: \(httpResponse.statusCode)")
            
            Log.auth.debug("Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                Log.auth.debug("   \(key): \(value)")
            }
        }
        
        Log.auth.debug("Response Body:")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            Log.auth.debug("\n   Raw JSON:")
            Log.auth.debug("   \(jsonString)")
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                Log.auth.debug("\n   Formatted JSON:")
                Log.auth.debug(prettyString.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n"))
            }
        }

        Log.auth.debug("JSON Decoding")
        let response = try JSONDecoder().decode(SocialLoginResponse.self, from: data)
        
        Log.auth.debug("Decode 성공!")
        Log.auth.debug("   code: \(response.code)")
        Log.auth.debug("   message: \(response.message)")
        if let data = response.data {
            Log.auth.debug("   data.isOnboardingCompleted: \(data.isOnboardingCompleted)")
        }
        return response
    }
}
