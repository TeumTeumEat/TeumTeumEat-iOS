//
//  OnboardingCompleteView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingCompleteView: View {
    let store: StoreOf<OnboardingCompleteFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            Image("character_complete")
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
                size: .large,
                isEnabled: true
            ) {
                store.send(.startButtonTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
        .colorScheme(.light)
    }
}
