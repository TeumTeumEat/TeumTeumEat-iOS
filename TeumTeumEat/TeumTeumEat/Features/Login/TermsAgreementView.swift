//
//  TermsAgreementView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import SwiftUI
import ComposableArchitecture

struct TermsAgreementView: View {
    @Bindable var store: StoreOf<TermsAgreementFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 12) {
                Text("서비스 이용을 위해")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("약관 동의가 필요해요")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            HStack {
                Button {
                    store.send(.allAgreeTapped)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: store.allAgreed ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(store.allAgreed ? .blue : .gray)
                        
                        Text("전체 동의")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // 개별 약관
            VStack(spacing: 16) {
                TermRow(
                    isAgreed: $store.serviceTermsAgreed,
                    title: "(필수) 서비스 이용약관",
                    onTap: { store.send(.serviceTermsTapped) },
                    onDetailTap: { store.send(.showTermsDetail(.service)) }
                )
                
                TermRow(
                    isAgreed: $store.privacyPolicyAgreed,
                    title: "(필수) 개인정보 처리방침",
                    onTap: { store.send(.privacyPolicyTapped) },
                    onDetailTap: { store.send(.showTermsDetail(.privacy)) }
                )
                
                TermRow(
                    isAgreed: $store.ageConfirmationAgreed,
                    title: "(필수) 만 14세 이상입니다",
                    onTap: { store.send(.ageConfirmationTapped) },
                    onDetailTap: nil
                )
                
                TermRow(
                    isAgreed: $store.marketingAgreed,
                    title: "(선택) 마케팅 정보 수신 동의",
                    onTap: { store.send(.marketingTapped) },
                    onDetailTap: nil
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }
            
            Button {
                store.send(.agreeTapped)
            } label: {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("동의하고 시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(store.canProceed ? Color.blue : Color.gray)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .disabled(!store.canProceed || store.isLoading)
        }
    }
}


struct TermRow: View {
    @Binding var isAgreed: Bool
    let title: String
    let onTap: () -> Void
    let onDetailTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isAgreed ? .blue : .gray)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let onDetailTap = onDetailTap {
                Button(action: onDetailTap) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
