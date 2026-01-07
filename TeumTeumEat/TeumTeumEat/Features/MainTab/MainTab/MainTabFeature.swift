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
        case delegate(Delegate)
    }
    
    enum Delegate {
        case logout
        case withdrawal
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
                    let previousTab = state.selectedTab
                    state.selectedTab = tab
                    
                    if tab != .register {
                        state.isRegisterMenuExpanded = false
                    }
                    
                    // ✅ 홈 탭으로 전환될 때 새로고침
                    if tab == .home && previousTab != .home {
                        return .send(.home(.onAppear))
                    }
                    
                    // ✅ 히스토리 탭으로 전환될 때 새로고침
                    if tab == .quiz && previousTab != .quiz {
                        return .send(.quiz(.onAppear))
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
                    
                // Home에서 QuizFlow 시작 (summaryData 포함)
                case .home(.delegate(.startQuizFlow(let quizzes, let summaryData, let isFirstTime))):
                    state.quizFlow = QuizFlowFeature.State(
                        quizzes: quizzes,
                        summaryData: summaryData,
                        isFirstTime: isFirstTime
                    )
                    print("퀴즈 플로우 시작 - 요약부터 표시")
                    return .none
                    
                case .quiz(.delegate(.openMyPageRequested)):
                    state.myPage = MyPageFeature.State()
                    print("History에서 MyPage 열기")
                    return .none
                    
                case .myPage(.delegate(.dismissed)):
                    state.myPage = nil
                    print("MyPage 닫힘")
                    return .none
                    
                case .myPage(.delegate(.logout)):
                    print("MainTab: MyPage에서 로그아웃 요청 받음")
                    return .send(.delegate(.logout))
                    
                case .quizFlow(.delegate(.completed(let destination))):
                    state.quizFlow = nil
                    print("퀴즈 플로우 완료 - 이동: \(destination)")
                    
                    switch destination {
                    case .home:
                        state.selectedTab = .home
                        // ✅ 홈으로 이동하면서 새로고침
                        return .send(.home(.onAppear))
                        
                    case .history:
                        state.selectedTab = .quiz
                        // ✅ 히스토리로 이동하면서 새로고침
                        return .send(.quiz(.onAppear))
                    }
                    
                case .quizFlow(.delegate(.cancelled)):
                    state.quizFlow = nil
                    print("퀴즈 플로우 취소")
                    return .none
                    
                case .addSubject(.delegate(.completed)):
                    state.addSubject = nil
                    print("주제 추가 완료 - 홈 새로고침")
                    return .send(.home(.onAppear))
                     
                case .addSubject(.delegate(.cancelled)):
                    state.addSubject = nil
                    print("주제 추가 취소 - Sheet 닫힘")
                    return .none
                    
                case .addSubjectFile(.delegate(.completed)):
                    state.addSubjectFile = nil
                    print("파일 주제 추가 완료 - 홈 새로고침")
                    return .send(.home(.onAppear))
                    
                case .addSubjectFile(.delegate(.cancelled)):
                    print("파일 주제 추가 취소 - Sheet 닫힘")
                    state.addSubjectFile = nil
                    return .none
                    
                case .myPage(.delegate(.withdrawal)):
                    print("MainTabFeature: 회원탈퇴 요청 받음")
                    return .send(.delegate(.withdrawal))
                    
                case .home, .quiz, .register, .addSubject, .addSubjectFile, .quizFlow, .myPage, .delegate:
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
