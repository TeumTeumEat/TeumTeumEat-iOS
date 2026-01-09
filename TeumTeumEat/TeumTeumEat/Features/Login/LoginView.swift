//
//  LoginView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import SwiftUI
import ComposableArchitecture
import _AuthenticationServices_SwiftUI

struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("개인 맞춤형 퀴즈 기반 학습 서비스")
                .font(.st_semibold_18)
                .foregroundStyle(.black)
            
            Image("logo_login")
            
            Spacer()
            
            VStack(spacing: 12) {
                // 애플 로그인
                Button(action: {
                    // 빈 액션 (appleLoginButton이 실제 처리)
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Apple로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(store.isLoading)
                .overlay(
                    store.isLoading ? ProgressView().tint(.white) : nil
                )
                .overlay {
                    appleLoginButton
                }
                
                // 카카오 로그인
                Button {
                    store.send(.kakaoLoginTapped)
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("카카오로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(store.isLoading)
                .overlay(
                    store.isLoading ? ProgressView() : nil
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(.white)
        .sheet(isPresented: .init(
            get: { store.showTermsSheet },
            set: { _ in store.send(.dismissTermsSheet) }
        )) {
            TermsAgreementBottomSheet(
                onAgree: { store.send(.agreeTermsTapped) },
                onDismiss: { store.send(.dismissTermsSheet) }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var appleLoginButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                       let identityTokenData = appleIDCredential.identityToken,
                       let identityToken = String(data: identityTokenData, encoding: .utf8) {
                        

                        var authCode: String? = nil
                        if let authCodeData = appleIDCredential.authorizationCode,
                           let code = String(data: authCodeData, encoding: .utf8) {
                            authCode = code
                        }
                        
                        print("애플 로그인 성공")
                        print("Identity Token: \(identityToken)")
                        print("Authorization Code: \(authCode ?? "없음")")
                        
                        // TCA 액션 전송
                        store.send(.appleLoginSuccess(idToken: identityToken, authCode: authCode))
                    }
                    
                case .failure(let error):
                    print("애플 로그인 실패: \(error)")
                    store.send(.appleLoginFailure(error))
                }
            }
        )
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .blendMode(.hue)
    }
}
