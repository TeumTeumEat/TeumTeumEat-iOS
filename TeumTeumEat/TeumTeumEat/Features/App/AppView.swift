//
//  AppView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        if store.isShowingSplash {
            SplashView(store: store.scope(state: \.splash, action: \.splash))
        } else if let loginStore = store.scope(state: \.login, action: \.login) {
            LoginView(store: loginStore)
        } else if let termsStore = store.scope(state: \.termsAgreement, action: \.termsAgreement) {
            TermsAgreementView(store: termsStore)
        } else if let onboardingStore = store.scope(state: \.onboarding, action: \.onboarding) {
            OnboardingView(store: onboardingStore)
        } else {
            // TODO: MainTab 구현 전 임시 화면
            VStack {
                Text("메인 화면")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("MainTab 구현 예정")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                
                Button {
                     store.send(.logout)
                 } label: {
                     HStack {
                         Image(systemName: "rectangle.portrait.and.arrow.right")
                         Text("로그아웃")
                     }
                     .foregroundColor(.white)
                     .padding(.horizontal, 30)
                     .padding(.vertical, 12)
                     .background(Color.red)
                     .cornerRadius(10)
                 }
                 .padding(.top, 40)
            }
        }
    }
}

