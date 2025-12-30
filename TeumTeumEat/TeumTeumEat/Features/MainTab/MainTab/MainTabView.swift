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
        ZStack(alignment: .bottomLeading) {
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
            
            // 어두운 배경
            if store.isRegisterMenuExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.toggleRegisterMenu)
                    }
                    .transition(.opacity)
            }
            
            // Register 플로팅 메뉴
            if store.isRegisterMenuExpanded {
                RegisterFloatingMenu(
                    onFileUploadTapped: {
                        store.send(.registerMenuItemTapped(.fileUpload))
                    },
                    onCategoryTapped: {
                        store.send(.registerMenuItemTapped(.category))
                    }
                )
                .padding(.leading, 52.5)
                .padding(.bottom, 34 + 50 + 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 커스텀 TabBar
            CustomTabBar(
                selectedTab: store.selectedTab,
                isRegisterMenuExpanded: store.isRegisterMenuExpanded,
                onTabSelected: { tab in
                    store.send(.tabSelected(tab))
                },
                onRegisterTapped: {
                    store.send(.toggleRegisterMenu)
                }
            )
            .padding(.horizontal, 60)
            .padding(.bottom, 34)
        }
        .ignoresSafeArea(.keyboard)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.isRegisterMenuExpanded)
        .fullScreenCover(
            isPresented: Binding(
                get: { store.addSubject != nil },
                set: { isPresented in
                    if !isPresented {
                        store.send(.addSubject(.closeSheet))
                    }
                }
            )
        ) {
            if let addSubjectStore = store.scope(state: \.addSubject, action: \.addSubject) {
                AddSubjectView(store: addSubjectStore)
            }
        }
    }
}



struct CustomTabBar: View {
    let selectedTab: MainTabFeature.State.Tab
    let isRegisterMenuExpanded: Bool
    let onTabSelected: (MainTabFeature.State.Tab) -> Void
    let onRegisterTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            TTETabButton(
                icon: Image("plus"),
                size: .small,
                isSelected: isRegisterMenuExpanded
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onRegisterTapped()
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

struct RegisterFloatingMenu: View {
    let onFileUploadTapped: () -> Void
    let onCategoryTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {

            FloatingMenuButton(
                icon: Image("category 1"),
                action: onCategoryTapped
            )

            FloatingMenuButton(
                icon: Image("upload"),
                action: onFileUploadTapped
            )
        }
    }
}

struct FloatingMenuButton: View {
    let icon: Image
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color._2690_FB)
                    .frame(width: 65, height: 65)
                
                icon
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
            }
        }
    }
}
