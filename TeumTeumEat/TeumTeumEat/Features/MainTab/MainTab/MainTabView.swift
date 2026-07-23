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
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 메인 콘텐츠 영역
                Group {
                    switch store.selectedTab {
                    case .home:
                        HomeView(store: store.scope(state: \.home, action: \.home))
                            .transition(.opacity)
                    case .quiz:
                        HistoryView(store: store.scope(state: \.quiz, action: \.quiz))
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

                if store.myPage == nil {
                    CustomTabBar(
                        selectedTab: store.selectedTab,
                        isRegisterMenuExpanded: store.isRegisterMenuExpanded,
                        onTabSelected: { tab in
                            store.send(.tabSelected(tab))
                        },
                        onRegisterTapped: {
                            store.send(.toggleRegisterMenu)
                        },
                        onFileUploadTapped: {
                            store.send(.registerMenuItemTapped(.fileUpload))
                        },
                        onCategoryTapped: {
                            store.send(.registerMenuItemTapped(.category))
                        }
                    )
                    .padding(.horizontal, 60)
                    .padding(.bottom, store.selectedTab == .quiz ? 0 : 20)
                }
            }
            .ignoresSafeArea(.keyboard)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.isRegisterMenuExpanded)
            .navigationDestination(
                isPresented: Binding(
                    get: { store.myPage != nil },
                    set: { if !$0 { store.send(.myPage(.delegate(.dismissed))) } }
                )
            ) {
                if let myPageStore = store.scope(state: \.myPage, action: \.myPage) {
                    MyPageView(store: myPageStore)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.newGoalFlow != nil },
                set: { _ in }
            )
        ) {
            if let newGoalFlowStore = store.scope(state: \.newGoalFlow, action: \.newGoalFlow) {
                NewGoalFlowView(store: newGoalFlowStore)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.addSubject != nil },
                set: { _ in }
            )
        ) {
            if let addSubjectStore = store.scope(state: \.addSubject, action: \.addSubject) {
                AddSubjectView(store: addSubjectStore)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.addSubjectFile != nil },
                set: { _ in }
            )
        ) {
            if let addSubjectFileStore = store.scope(state: \.addSubjectFile, action: \.addSubjectFile) {
                AddSubjectFileView(store: addSubjectFileStore)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.quizFlow != nil },
                set: { _ in }
            )
        ) {
            if let quizFlowStore = store.scope(state: \.quizFlow, action: \.quizFlow) {
                QuizFlowView(store: quizFlowStore)
            }
        }
    }
}



struct CustomTabBar: View {
    let selectedTab: MainTabFeature.State.Tab
    let isRegisterMenuExpanded: Bool
    let onTabSelected: (MainTabFeature.State.Tab) -> Void
    let onRegisterTapped: () -> Void
    let onFileUploadTapped: () -> Void
    let onCategoryTapped: () -> Void

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
            .overlay(alignment: .bottom) {
                if isRegisterMenuExpanded {
                    RegisterFloatingMenu(
                        onFileUploadTapped: onFileUploadTapped,
                        onCategoryTapped: onCategoryTapped
                    )
                    .fixedSize()
                    .offset(y: -(50 + 12))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            TTETabButton(
                icon: Image("home"),
                size: (selectedTab == .quiz || isRegisterMenuExpanded) ? .small : .large,
                isSelected: !isRegisterMenuExpanded && selectedTab == .home
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTabSelected(.home)
                }
            }

            TTETabButton(
                icon: Image("library"),
                size: .small,
                isSelected: selectedTab == .quiz,
                customIconSize: 30
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onTabSelected(.quiz)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRegisterMenuExpanded)
    }
}

struct RegisterFloatingMenu: View {
    let onFileUploadTapped: () -> Void
    let onCategoryTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {

            FloatingMenuButton(
                icon: Image("category 1"),
                label: "주제찾기",
                action: onCategoryTapped
            )

            FloatingMenuButton(
                icon: Image("upload"),
                label: "자료올리기",
                action: onFileUploadTapped
            )
        }
    }
}

struct FloatingMenuButton: View {
    let icon: Image
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 65, height: 65)
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)

                VStack(spacing: 3) {
                    icon
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color._2690_FB)
                        .frame(width: 31.2, height: 31.2)

                    Text(label)
                        .font(Font.custom("Pretendard-Bold", size: 12))
                        .foregroundColor(Color._2690_FB)
                }
            }
        }
    }
}
