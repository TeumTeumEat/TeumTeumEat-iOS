//
//  TermsAgreementFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct TermsAgreementFeature {
    @ObservableState
    struct State: Equatable {
        var allAgreed = false
        var serviceTermsAgreed = false      // 서비스 이용약관 (필수)
        var privacyPolicyAgreed = false     // 개인정보 처리방침 (필수)
        var ageConfirmationAgreed = false   // 만 14세 이상 (필수)
        var marketingAgreed = false         // 마케팅 수신 동의 (선택)
        
        var idToken: String  // 로그인 재시도용 idToken
        var isLoading = false
        var errorMessage: String?
        
        var canProceed: Bool {
            serviceTermsAgreed && privacyPolicyAgreed && ageConfirmationAgreed
        }
        
        init(idToken: String) {
            self.idToken = idToken
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case allAgreeTapped
        case serviceTermsTapped
        case privacyPolicyTapped
        case ageConfirmationTapped
        case marketingTapped
        
        case showTermsDetail(TermType)
        case agreeTapped  // 동의하고 시작하기 버튼
        
        case signUpResponse(Result<SocialLoginResponse, Error>)
        case delegate(Delegate)
        
        enum TermType {
            case service
            case privacy
        }
        
        enum Delegate {
            case signUpSuccess(accessToken: String, refreshToken: String)
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(\.allAgreed):
                // 전체 동의 토글
                state.serviceTermsAgreed = state.allAgreed
                state.privacyPolicyAgreed = state.allAgreed
                state.ageConfirmationAgreed = state.allAgreed
                state.marketingAgreed = state.allAgreed
                return .none
                
            case .binding(\.serviceTermsAgreed),
                 .binding(\.privacyPolicyAgreed),
                 .binding(\.ageConfirmationAgreed),
                 .binding(\.marketingAgreed):
                // 개별 항목 변경 시 전체 동의 상태 업데이트
                state.allAgreed = state.serviceTermsAgreed &&
                                  state.privacyPolicyAgreed &&
                                  state.ageConfirmationAgreed &&
                                  state.marketingAgreed
                return .none
                
            case .binding:
                return .none
                
            case .allAgreeTapped:
                state.allAgreed.toggle()
                return .send(.binding(.set(\.allAgreed, state.allAgreed)))
                
            case .serviceTermsTapped:
                state.serviceTermsAgreed.toggle()
                return .send(.binding(.set(\.serviceTermsAgreed, state.serviceTermsAgreed)))
                
            case .privacyPolicyTapped:
                state.privacyPolicyAgreed.toggle()
                return .send(.binding(.set(\.privacyPolicyAgreed, state.privacyPolicyAgreed)))
                
            case .ageConfirmationTapped:
                state.ageConfirmationAgreed.toggle()
                return .send(.binding(.set(\.ageConfirmationAgreed, state.ageConfirmationAgreed)))
                
            case .marketingTapped:
                state.marketingAgreed.toggle()
                return .send(.binding(.set(\.marketingAgreed, state.marketingAgreed)))
                
            case .showTermsDetail(let termType):
                // TODO: Safari나 WebView로 약관 상세 보기
                print("약관 상세 보기: \(termType)")
                return .none
                
            case .agreeTapped:
                guard state.canProceed else {
                    state.errorMessage = "필수 약관에 동의해주세요."
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [idToken = state.idToken] send in
                    do {
                        // termsAgreed: true로 재시도
                        let response = try await loginToServer(
                            idToken: idToken,
                            termsAgreed: true
                        )
                        await send(.signUpResponse(.success(response)))
                    } catch {
                        await send(.signUpResponse(.failure(error)))
                    }
                }
                
            case .signUpResponse(.success(let response)):
                state.isLoading = false
                
                if response.code == "OK" {
                    guard let data = response.data else {
                        state.errorMessage = "응답 데이터가 없습니다."
                        return .none
                    }
                    
                    // 토큰 저장
                    KeyChainManager.shared.saveAccessToken(data.accessToken)
                    KeyChainManager.shared.saveRefreshToken(data.refreshToken)
                    
                    return .send(.delegate(.signUpSuccess(
                        accessToken: data.accessToken,
                        refreshToken: data.refreshToken
                    )))
                } else {
                    state.errorMessage = response.message
                    return .none
                }
                
            case .signUpResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

extension TermsAgreementFeature {
    private func loginToServer(idToken: String, termsAgreed: Bool) async throws -> SocialLoginResponse {
        let baseURL = Config.baseURL
        let endPoint = "/api/v1/auth/oauth/register?provider=KAKAO"
        let fullURL = baseURL + endPoint
        
        let url = URL(string: fullURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SocialLoginRequest(idToken: idToken, termsAgreed: termsAgreed, name: "testUser")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SocialLoginResponse.self, from: data)
        
        return response
    }
}
