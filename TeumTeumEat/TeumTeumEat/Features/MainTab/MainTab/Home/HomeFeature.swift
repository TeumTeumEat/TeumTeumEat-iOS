//
//  HomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        var isTodayQuizCompleted: Bool = false
        var myPage: MyPageFeature.State?
    }
    
    enum Action {
        case settingTapped
        case toggleQuizStatus
        case myPage(MyPageFeature.Action)
        case characterEatTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuizFlow  // 퀴즈 플로우 시작 요청
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingTapped:
                state.myPage = MyPageFeature.State()
                return .none
                
            case .toggleQuizStatus:
                state.isTodayQuizCompleted.toggle()
                return .none
                
            case .characterEatTapped:
                // MainTab에게 퀴즈 플로우 시작하라고 알림
                return .send(.delegate(.startQuizFlow))
                
            case .myPage(.delegate(.dismissed)):
                state.myPage = nil
                return .none
                
            case .myPage, .delegate:
                return .none
            }
        }
        .ifLet(\.myPage, action: \.myPage) {
            MyPageFeature()
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                        store.send(.settingTapped)
                    }
                )
                
                Spacer()
                    .frame(height: store.isTodayQuizCompleted ? 5 : 11)
                
                CharacterImageView(
                    isTodayQuizCompleted: store.isTodayQuizCompleted,
                    onCharacterTapped: {
                        print("HomeView: 캐릭터 탭!")
                        store.send(.characterEatTapped)
                    }
                )
                                
                ScrollView {
                    VStack {
                        // TODO: 홈 콘텐츠
                    }
                }
            }
            .navigationBarHidden(true)
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
        }
    }
}

// MARK: - Character Image View
struct CharacterImageView: View {
    let isTodayQuizCompleted: Bool
    let onCharacterTapped: () -> Void  
    
    var body: some View {
        if isTodayQuizCompleted {
            Image("character_eat")
                .resizable()
                .scaledToFit()
                .frame(height: 554)
                .padding(.leading, 30)
                .padding(.trailing, 8.47)

        } else {
            Image("character_hamburger")
                .resizable()
                .scaledToFit()
                .frame(height: 548)
                .padding(.leading, 30)
                .padding(.trailing, 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCharacterTapped()
                }
        }
    }
}

struct HomeNavigationBar: View {
    let fireCount: Int
    let stampCount: Int
    let onSettingTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 로고
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 22)
                

            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("fire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(fireCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("stamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(stampCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 설정 버튼
            Button(action: onSettingTapped) {
                Image("setting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

enum SocialLoginType: String, Equatable {
    case apple = "Apple"
    case kakao = "Kakao"
    
    var icon: String {
        switch self {
        case .apple:
            return "apple.logo"
        case .kakao:
            return "message.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .apple:
            return .black
        case .kakao:
            return .yellow
        }
    }
}
