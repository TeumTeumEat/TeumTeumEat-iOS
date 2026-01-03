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
        var quiz: HistoryFeature.State = .init()
        var register: RegisterFeature.State = .init()
        
        var addSubject: AddSubjectFeature.State?
        var addSubjectFile: AddSubjectFileFeature.State?
        var quizFlow: QuizFlowFeature.State?
        var myPage: MyPageFeature.State?
        
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
        case quiz(HistoryFeature.Action)
        case register(RegisterFeature.Action)
        case addSubject(AddSubjectFeature.Action)
        case addSubjectFile(AddSubjectFileFeature.Action)
        case quizFlow(QuizFlowFeature.Action)
        case myPage(MyPageFeature.Action)
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
            HistoryFeature()
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
                
            case .toggleRegisterMenu:
                state.isRegisterMenuExpanded.toggle()
                return .none
                
            case .registerMenuItemTapped(let item):
                print("메뉴 아이템 선택: \(item)")
                state.isRegisterMenuExpanded = false
                if item == .category {
                     state.addSubject = AddSubjectFeature.State()
                 } else if item == .fileUpload {
                     state.addSubjectFile = AddSubjectFileFeature.State()
                 }
                return .none
                
            case .home(.delegate(.openMyPageRequested)):
                        state.myPage = MyPageFeature.State()
                        print("Home에서 MyPage 열기")
                        return .none
                
            case .home(.delegate(.startQuizFlow)):
                state.quizFlow = QuizFlowFeature.State()
                print("퀴즈 플로우 시작")
                return .none
                
            case .myPage(.delegate(.dismissed)):
                        state.myPage = nil
                        print("MyPage 닫힘")
                        return .none
                
            case .quiz(.delegate(.openMyPageRequested)):
                        state.myPage = MyPageFeature.State()
                        print("History에서 MyPage 열기")
                        return .none
                
            case .quizFlow(.delegate(.completed(let destination))):
                state.quizFlow = nil
                print("퀴즈 플로우 완료 - 이동: \(destination)")
                if destination == .history {
                    state.selectedTab = .quiz
                }
                return .none
                
            case .quizFlow(.delegate(.cancelled)):
                state.quizFlow = nil
                print("퀴즈 플로우 취소")
                return .none
                
            case .addSubject(.delegate(.completed)):
                 state.addSubject = nil
                 print("주제 추가 완료 - Sheet 닫힘")
                 return .none
                 
             case .addSubject(.delegate(.cancelled)):
                 state.addSubject = nil
                 print("주제 추가 취소 - Sheet 닫힘")
                 return .none
                
            case .addSubjectFile(.delegate(.completed)):
                print("파일 주제 추가 완료 - Sheet 닫힘")
                state.addSubjectFile = nil
                return .none
                
            case .addSubjectFile(.delegate(.cancelled)):
                print("파일 주제 추가 취소 - Sheet 닫힘")
                state.addSubjectFile = nil
                return .none
                
            case .home, .quiz, .register, .addSubject, .addSubjectFile, .quizFlow, .myPage:
                return .none
            }
        }
        .ifLet(\.addSubject, action: \.addSubject) {
            AddSubjectFeature()
        }
        .ifLet(\.addSubjectFile, action: \.addSubjectFile) {
            AddSubjectFileFeature()
        }
        .ifLet(\.quizFlow, action: \.quizFlow) {
            QuizFlowFeature()
        }
        .ifLet(\.myPage, action: \.myPage) { 
            MyPageFeature()
        }
    }
}
