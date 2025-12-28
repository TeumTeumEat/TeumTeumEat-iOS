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
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
        var pendingIdToken: String?
        var showTermsSheet = false
    }
    
    enum Action {
        case kakaoLoginTapped
        case appleLoginTapped

        case loginAttempt(idToken: String, termsAgreed: Bool)
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
                print("카카오 로그인 버튼 탭")
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        print("카카오 SDK 로그인 시작...")
                        let kakaoIdToken = try await loginWithKakaoSDK()
                        print("카카오 SDK 로그인 성공!")
                        print("ID Token: \(kakaoIdToken)")
                        print("Token Length: \(kakaoIdToken.count)")
                        print("서버 로그인 시도 (termsAgreed: false)")
                        await send(.loginAttempt(idToken: kakaoIdToken, termsAgreed: false))
                    } catch {
                        print("카카오 로그인 전체 실패:", error)
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
                state.pendingIdToken = idToken
                
                print("서버 로그인 요청")
                print("idToken: \(String(idToken.prefix(20)))...")
                print("termsAgreed: \(termsAgreed)")
                
                return .run { send in
                    do {
                        let response = try await loginToServer(
                            idToken: idToken,
                            termsAgreed: termsAgreed
                        )
                        
                        print("서버 응답 수신")
                        print("Response Code: \(response.code)")
                        print("Message: \(response.message)")
                        
                        if let data = response.data {
                            print("AccessToken: \(String(data.accessToken))...")
                            print("RefreshToken: \(String(data.refreshToken))...")
                            print("isOnboardingCompleted: \(data.isOnboardingCompleted)")
                        }
                        await send(.loginResponse(.success(response)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                        print("서버 로그인 실패")
                        print("Error: \(error.localizedDescription)")
                    }
                }
                
            case .loginResponse(.success(let response)):
                state.isLoading = false
                print("응답 처리")
                if response.code == "OK" {
                    // 로그인 성공 (기존 유저 또는 약관 동의 완료한 신규 유저)
                    guard let data = response.data else {
                        state.errorMessage = "응답 데이터가 없습니다."
                        return .none
                    }
                    
                    // 토큰 저장
                    print("토큰 저장 중...")
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    print("토큰 저장 완료")
                    
                    print("다음 화면 분기:")
                    if data.isOnboardingCompleted {
                        print("   → 메인 화면 (온보딩 완료)")
                    } else {
                        print("   → 온보딩 화면 (온보딩 미완료)")
                    }
                    
                    return .send(.delegate(.loginSuccess(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken,
                        isOnboardingCompleted: data.isOnboardingCompleted
                    )))
                    
                } else if response.code == "AUTH-006" {
                    // 신규 유저 → 약관 동의 필요
                    // pendingIdToken은 이미 state에 저장되어 있음
                    print("약관 동의 필요 (신규 유저)")
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
                print("서버 로그인 실패: \(error)")
                return .none
                
            case .dismissTermsSheet:
                state.showTermsSheet = false
                return .none
                
            case .agreeTermsTapped:
                 print("약관 동의 확인 - 재로그인 시도")
                 state.showTermsSheet = false
                 
                 guard let idToken = state.pendingIdToken else {
                     state.errorMessage = "토큰 정보가 없습니다."
                     return .none
                 }
                 
                 // termsAgreed: true로 재시도
                 return .send(.loginAttempt(idToken: idToken, termsAgreed: true))
                
            case .delegate:
                return .none
            }
        }
    }
}

extension LoginFeature {

    private func loginWithAppleSDK() async throws -> String {
        // TODO: Apple SDK 연동
        fatalError("Apple SDK 연동 필요")
    }
    
    private func loginWithKakaoSDK() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        print("카카오톡 로그인 성공")
                        print("\(String(describing: token.idToken))")
                        continuation.resume(returning: token.idToken ?? "")
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        print("카카오 계정 로그인 성공")
                        print("\(String(describing: token.idToken))")
                        continuation.resume(returning: token.idToken ?? "")
                    }
                }
            }
        }
    }
    
    private func loginToServer(idToken: String, termsAgreed: Bool) async throws -> SocialLoginResponse {
        print("서버 API 호출 시작")
        let baseURL = Config.baseURL
        let endPoint = "/api/v1/auth/oauth/register?provider=KAKAO"
        let fullPath = baseURL + endPoint
        print("fullpath: \(fullPath)")
        
        let url = URL(string: "\(fullPath)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SocialLoginRequest(
            idToken: idToken,
            termsAgreed: termsAgreed,
            name: "TestUser"
        )
        request.httpBody = try JSONEncoder().encode(body)
        

        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                print("   \(key): \(value)")
            }
        } else {
            print("헤더 없음")
        }
        
        print("Request Body:")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("   Raw Data: \(bodyString)")
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: bodyData),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n   Formatted JSON:")
                print(prettyString.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n"))
            }
        } else {
            print("바디 없음")
        }
        
        print("Request Body 구조:")
        print("   idToken: \(String(idToken.prefix(30)))... (길이: \(idToken.count))")
        print("   termsAgreed: \(termsAgreed)")
        print("   name: TestUser")
        
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        print("서버 응답 수신")
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            print("Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("   \(key): \(value)")
            }
        }
        
        print("Response Body:")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n   Raw JSON:")
            print("   \(jsonString)")
            
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n   Formatted JSON:")
                print(prettyString.split(separator: "\n").map { "   \($0)" }.joined(separator: "\n"))
            }
        }

    
        print("JSON Decoding")
        let response = try JSONDecoder().decode(SocialLoginResponse.self, from: data)
        
        print("Decode 성공!")
        print("   code: \(response.code)")
        print("   message: \(response.message)")
        if let data = response.data {
            print("   data.accessToken: \(String(data.accessToken.prefix(20)))...")
            print("   data.refreshToken: \(String(data.refreshToken.prefix(20)))...")
            print("   data.isOnboardingCompleted: \(data.isOnboardingCompleted)")
        }
        return response
    }
}
