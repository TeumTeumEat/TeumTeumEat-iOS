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
        Group {
            if let welcomeStore = store.scope(state: \.welcome, action: \.welcome) {
                WelcomeView(store: welcomeStore)
            } else if let nameStore = store.scope(state: \.nameInput, action: \.nameInput) {
                NameInputView(store: nameStore)
            } else if let timeStore = store.scope(state: \.timeSetting, action: \.timeSetting) {
                TimeSettingView(store: timeStore)
            } else if let durationStore = store.scope(state: \.usageDuration, action: \.usageDuration) {
                UsageDurationView(store: durationStore)
            }
        }
    }
}
