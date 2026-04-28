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
            Image("character_onboarding")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
                .padding(.top, 70)

            Image("logo_login")
                .resizable()
                .frame(width: 131, height: 40)
                .padding(.top, 21)
            
            Spacer()
            
            TTEButton(title: "시작하기", size: .largeFull) {
                store.send(.startOnboardingTapped)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(.white)
    }
}
