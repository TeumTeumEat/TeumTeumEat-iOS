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
                Text("매일 소모되는 이동 시간,")
                    .titleSemibold18()
                
                Text("틈틈잇과 함께 성장하는 시간으로 바꿔봐요!")
                    .titleSemibold18()
            }
            .multilineTextAlignment(.center)
            .padding(.top, 70)
            
            
            Image("logo_login")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.black)
                .frame(width: 177,height: 54)
                .padding(.top, 21)

            
            Image("pose=front")
                .frame(maxWidth: .infinity)
                .frame(height: 244)
                .padding(.horizontal, 30)
                .padding(.top, 25)
            
            Spacer()
                
            TTEButton(title: "시작하기", size: .large) {
                store.send(.startOnboardingTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
