//
//  WelcomeView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI
import ComposableArchitecture

struct WelcomeView: View {
    let store: StoreOf<WelcomeFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("나만의 AI 일일 퀴즈 서비스")
                    .btSemiBold18_24()
                    .foregroundStyle(.gray800)

                Text("틈틈잇!")
                    .btSemiBold18_24()
                    .foregroundStyle(.gray800)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 70)
            
            
            Image("logo_login")
                .resizable()
                .frame(width: 177,height: 54)
                .padding(.top, 21)

            
            Image("pose=front")
                .frame(maxWidth: .infinity)
                .frame(height: 244)
                .padding(.horizontal, 30)
                .padding(.top, 25)
            
            Spacer()
            
            TTEButton(title: "시작하기", size: .largeFull) {
                store.send(.startOnboardingTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(.white)
    }
}
