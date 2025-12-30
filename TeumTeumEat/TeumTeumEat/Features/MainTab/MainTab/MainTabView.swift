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
        ZStack(alignment: .bottom) {
            // 메인 콘텐츠 영역
            Group {
                switch store.selectedTab {
                case .home:
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .transition(.opacity)
                case .quiz:
                    QuizView(store: store.scope(state: \.quiz, action: \.quiz))
                        .transition(.opacity)
                case .register:
                    RegisterView(store: store.scope(state: \.register, action: \.register))
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: store.selectedTab)
            
            // 커스텀 TabBar
            CustomTabBar(
                selectedTab: store.selectedTab,
                onTabSelected: { tab in
                    store.send(.tabSelected(tab))
                }
            )
            .padding(.horizontal, 60)
            .padding(.bottom, 34)
        }
        .ignoresSafeArea(.keyboard)
    }
}


struct CustomTabBar: View {
    let selectedTab: MainTabFeature.State.Tab
    let onTabSelected: (MainTabFeature.State.Tab) -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            TTETabButton(
                icon: Image("plus"),
                size: .small,
                isSelected: selectedTab == .register
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTabSelected(.register)
                }
            }
                        
            TTETabButton(
                icon: Image("home"),
                size: .large,
                isSelected: selectedTab == .home
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTabSelected(.home)
                }
            }
            
            TTETabButton(
                icon: Image("library"),
                size: .small,
                isSelected: selectedTab == .quiz
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTabSelected(.quiz)
                }
            }
        }
    }
}

   
