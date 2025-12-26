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
            Spacer()
            
            Text("서비스 소개애애애애")
                .titleSemibold18()
                .padding(.bottom, 107)
            
            Image("pose=front")
                .frame(maxWidth: .infinity)
                .frame(height: 244)
                .padding(.horizontal, 30)
            
            Spacer()
                
            TTEButton(title: "시작하기", size: .large) {
                store.send(.startOnboardingTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
