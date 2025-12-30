//
//  MainTabFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isRegisterMenuExpanded: Bool = false
        
        // 각 탭의 Feature State
        var home: HomeFeature.State = .init()
        var quiz: QuizFeature.State = .init()
        var register: RegisterFeature.State = .init()
        
        enum Tab {
            case home
            case quiz
            case register
        }
    }
    
    enum Action {
        case tabSelected(State.Tab)
        case toggleRegisterMenu
        case registerMenuItemTapped(RegisterMenuItem)
        case home(HomeFeature.Action)
        case quiz(QuizFeature.Action)
        case register(RegisterFeature.Action)
    }
    
    enum RegisterMenuItem {
        case fileUpload
        case category
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.quiz, action: \.quiz) {
            QuizFeature()
        }
        Scope(state: \.register, action: \.register) {
            RegisterFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                
                if tab != .register {
                    state.isRegisterMenuExpanded = false
                }
                return .none
                
            case .toggleRegisterMenu:  // ✅ 추가
                state.isRegisterMenuExpanded.toggle()
                return .none
                
            case .registerMenuItemTapped(let item):  // ✅ 추가
                print("메뉴 아이템 선택: \(item)")
                state.isRegisterMenuExpanded = false
                // TODO: 각 아이템에 맞는 화면으로 이동
                return .none
                
            case .home, .quiz, .register:  
                return .none
            }
        }
    }
}
