//
//  TermsAgreementBottomSheet.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/9/26.
//

import SwiftUI

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
                    .foregroundStyle(.black)
                
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
                                    .foregroundColor(.black)
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 4)
                    .padding(.top, 24)
                }
                .padding()
            }
        }
        .background(.white)
    }
    
    private func updateAllAgreed() {
        allAgreed = ageConfirmationAgreed && serviceTermsAgreed && privacyPolicyAgreed
    }
}
