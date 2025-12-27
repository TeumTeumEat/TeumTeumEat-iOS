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
            } else if let contentStore = store.scope(state: \.contentSelection, action: \.contentSelection) {
                ContentSelectionView(store: contentStore)
            } else if let fileUploadStore = store.scope(state: \.fileUpload, action: \.fileUpload) {
                FileUploadView(store: fileUploadStore)
            } else if let categoryStore = store.scope(state: \.categorySelection, action: \.categorySelection) {
                CategorySelectionView(store: categoryStore)
            } else if let difficultyStore = store.scope(state: \.difficultySelection, action: \.difficultySelection) {
                DifficultySelectionView(store: difficultyStore)
            } else if let durationSelectionStore = store.scope(state: \.durationSelection, action: \.durationSelection) {
                DurationSelectionView(store: durationSelectionStore)
            } else if let summaryStore = store.scope(state: \.summary, action: \.summary) {
                OnboardingSummaryView(store: summaryStore)
            } else if let loadingStore = store.scope(state: \.loading, action: \.loading) {
                OnboardingLoadingView(store: loadingStore)
            } else if let completeStore = store.scope(state: \.complete, action: \.complete) {
                OnboardingCompleteView(store: completeStore)
            }
        }
    }
}
