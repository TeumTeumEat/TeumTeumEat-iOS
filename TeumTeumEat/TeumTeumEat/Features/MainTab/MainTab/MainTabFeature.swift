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
        case home(HomeFeature.Action)
        case quiz(QuizFeature.Action)
        case register(RegisterFeature.Action)
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
                return .none
                
            case .home, .quiz, .register:  
                return .none
            }
        }
    }
}
