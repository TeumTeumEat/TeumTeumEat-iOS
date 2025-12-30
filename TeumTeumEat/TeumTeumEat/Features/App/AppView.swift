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
        } else if let onboardingStore = store.scope(state: \.onboarding, action: \.onboarding) {
            OnboardingView(store: onboardingStore)
        } else if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) { 
            MainTabView(store: mainTabStore)
        }
    }
}
