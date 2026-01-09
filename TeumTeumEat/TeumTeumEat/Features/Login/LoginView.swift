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
            
            Text("TeumTeumEat")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("간편하게 로그인하고 시작하세요")
                .font(.subheadline)
                .foregroundColor(.gray)
            
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
                    .frame(height: 50)
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
                    .frame(height: 50)
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
            
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
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
struct TermsAgreementBottomSheet: View {
    let onAgree: () -> Void
    let onDismiss: () -> Void
    
    @State private var allAgreed = false
    @State private var serviceTermsAgreed = false
    @State private var privacyPolicyAgreed = false
    @State private var ageConfirmationAgreed = false
    
    private var canProceed: Bool {
        serviceTermsAgreed && privacyPolicyAgreed && ageConfirmationAgreed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("이용 약관")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button {
                    if canProceed {
                        onAgree()
                    }
                } label: {
                    Text("완료")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(canProceed ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!canProceed)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 개별 약관 (순서 변경)
                    VStack(spacing: 16) {
                        TermRow(
                            isAgreed: $ageConfirmationAgreed,
                            title: "만 14세 이상 가입 동의 (필수)",
                            link: nil
                        )
                        
                        TermRow(
                            isAgreed: $serviceTermsAgreed,
                            title: "이용약관 (필수)",
                            link: "https://resolute-flier-02d.notion.site/2d8151abb62e80cbaefde6ddcef603cc"
                        )
                        
                        TermRow(
                            isAgreed: $privacyPolicyAgreed,
                            title: "개인정보처리방침 (필수)",
                            link: "https://resolute-flier-02d.notion.site/2d8151abb62e8099bfd6d881256a6b4a"
                        )
                    }
                    .onChange(of: ageConfirmationAgreed) { _, _ in updateAllAgreed() }
                    .onChange(of: serviceTermsAgreed) { _, _ in updateAllAgreed() }
                    .onChange(of: privacyPolicyAgreed) { _, _ in updateAllAgreed() }
                    
                    HStack(spacing: 12) {
                        Button {
                            allAgreed.toggle()
                            serviceTermsAgreed = allAgreed
                            privacyPolicyAgreed = allAgreed
                            ageConfirmationAgreed = allAgreed
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: allAgreed ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(allAgreed ? .blue : .gray)
                                
                                Text("전체 동의")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 4)
                }
                .padding()
            }
        }
    }
    
    private func updateAllAgreed() {
        allAgreed = ageConfirmationAgreed && serviceTermsAgreed && privacyPolicyAgreed
    }
}

struct TermRow: View {
    @Binding var isAgreed: Bool
    let title: String
    let link: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isAgreed ? .blue : .gray)
            }
            
            // 텍스트 (링크가 있으면 Link, 없으면 일반 Text)
            if let urlString = link, let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .underline()
                }
            } else {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.leading, 4)
    }
}
