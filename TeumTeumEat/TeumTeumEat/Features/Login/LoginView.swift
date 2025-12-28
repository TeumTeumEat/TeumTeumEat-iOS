//
//  LoginView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import SwiftUI
import ComposableArchitecture

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
                
                // 애플 로그인
                Button {
                    store.send(.appleLoginTapped)
                } label: {
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
            }
            .padding(.horizontal, 20)
            .disabled(store.isLoading)
            
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            if store.isLoading {
                ProgressView()
                    .padding(.top, 20)
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
}
struct TermsAgreementBottomSheet: View {
    let onAgree: () -> Void
    let onDismiss: () -> Void
    
    @State private var allAgreed = false
    @State private var serviceTermsAgreed = false
    @State private var privacyPolicyAgreed = false
    @State private var ageConfirmationAgreed = false
    @State private var marketingAgreed = false
    
    private var canProceed: Bool {
        serviceTermsAgreed && privacyPolicyAgreed && ageConfirmationAgreed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("서비스 이용 약관")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 전체 동의
                    HStack {
                        Button {
                            allAgreed.toggle()
                            serviceTermsAgreed = allAgreed
                            privacyPolicyAgreed = allAgreed
                            ageConfirmationAgreed = allAgreed
                            marketingAgreed = allAgreed
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: allAgreed ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(allAgreed ? .blue : .gray)
                                
                                Text("전체 동의")
                                    .font(.headline)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 개별 약관
                    VStack(spacing: 16) {
                        TermRow(
                            isAgreed: $serviceTermsAgreed,
                            title: "(필수) 서비스 이용약관"
                        )
                        
                        TermRow(
                            isAgreed: $privacyPolicyAgreed,
                            title: "(필수) 개인정보 처리방침"
                        )
                        
                        TermRow(
                            isAgreed: $ageConfirmationAgreed,
                            title: "(필수) 만 14세 이상입니다"
                        )
                        
                        TermRow(
                            isAgreed: $marketingAgreed,
                            title: "(선택) 마케팅 정보 수신 동의"
                        )
                    }
                }
                .padding()
            }
            
            // 동의 버튼
            Button {
                onAgree()
            } label: {
                Text("동의하고 시작하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canProceed ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canProceed)
            .padding()
        }
    }
}

struct TermRow: View {
    @Binding var isAgreed: Bool
    let title: String
    
    var body: some View {
        Button {
            isAgreed.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isAgreed ? .blue : .gray)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
}
