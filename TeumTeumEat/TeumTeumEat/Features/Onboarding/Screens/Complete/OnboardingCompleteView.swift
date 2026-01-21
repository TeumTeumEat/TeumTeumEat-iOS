//
//  OnboardingCompleteView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import Lottie

struct OnboardingCompleteView: View {
    let store: StoreOf<OnboardingCompleteFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            LottieView(animation: .named("onboarding_comp"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(height: 293)
                .padding(.horizontal, 32)
                .padding(.top, 119)
            
            Text("'\(store.userName)'님 환영합니다")
                .titleSemibold18()
                .foregroundColor(.gray900)
                .padding(.top, 20)
            
            Spacer()
            
            TTEButton(
                title: "시작하기",
                size: .largeFull,
                isEnabled: true
            ) {
                store.send(.startButtonTapped)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
        .colorScheme(.light)
    }
}
