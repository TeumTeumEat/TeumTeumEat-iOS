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
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
            
            VStack(spacing: 12) {
                Text("\(store.userName)님,")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("틈틈잇 준비가 완료되었어요!")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("이제 퀴즈를 시작해볼까요?")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            
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
    }
}
