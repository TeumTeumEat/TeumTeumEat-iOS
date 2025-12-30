//
//  MainTabView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

struct MainTabView: View {
    let store: StoreOf<MainTabFeature>
    
    var body: some View {
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { store.send(.tabSelected($0)) }
        )) {
            HomeView(store: store.scope(state: \.home, action: \.home))
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(MainTabFeature.State.Tab.home)
            
            QuizView(store: store.scope(state: \.quiz, action: \.quiz))
                .tabItem {
                    Label("퀴즈", systemImage: "questionmark.circle.fill")
                }
                .tag(MainTabFeature.State.Tab.quiz)
            
            RegisterView(store: store.scope(state: \.register, action: \.register))
                .tabItem {
                    Label("등록", systemImage: "plus.circle.fill")
                }
                .tag(MainTabFeature.State.Tab.register) 
        }
    }
}
