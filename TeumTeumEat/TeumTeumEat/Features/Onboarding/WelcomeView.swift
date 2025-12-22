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
        VStack {
            Spacer()
                .frame(height: 100)
            
            Text("서비스 소개애애애애")
                .titleSemibold18()
            
            Spacer()
            
            Image("pose=front")
                .frame(height: 244)
                .padding(.horizontal, 30)
            
            Spacer() 
            
            Button {
                store.send(.startOnboardingTapped)
            } label: {
                Text("시작하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
