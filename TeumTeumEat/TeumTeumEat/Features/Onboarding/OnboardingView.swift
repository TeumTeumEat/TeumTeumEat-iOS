//
//  OnboardingView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
        if let welcomeStore = store.scope(state: \.welcome, action: \.welcome) {
            WelcomeView(store: welcomeStore)
        } else if let nameStore = store.scope(state: \.nameInput, action: \.nameInput) {
            NameInputView(store: nameStore)
        }
    }
}

