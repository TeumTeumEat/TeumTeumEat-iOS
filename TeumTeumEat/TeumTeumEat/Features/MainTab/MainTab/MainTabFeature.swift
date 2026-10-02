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

        var newGoalFlow: NewGoalFlowFeature.State?
        var addSubject: AddSubjectFeature.State?
        var addSubjectFile: AddSubjectFileFeature.State?
        var quizFlow: QuizFlowFeature.State?
        var myPage: MyPageFeature.State?
        enum Tab {
            case home
            case quiz
        }
    }
    
    enum Action {
        case tabSelected(State.Tab)
        case toggleRegisterMenu
        case registerMenuItemTapped(RegisterMenuItem)
        case home(HomeFeature.Action)
        case quiz(HistoryFeature.Action)
        case newGoalFlow(NewGoalFlowFeature.Action)
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
        
            Reduce { state, action in
                switch action {
                case .tabSelected(let tab):
                    guard !state.home.isGoalCompleted else { return .none }
                    let previousTab = state.selectedTab
                    state.selectedTab = tab

                    state.isRegisterMenuExpanded = false

                    // 홈 탭 새로고침은 HomeView.onAppear가 담당 (여기서도 보내면 API가 중복 호출됨)

                    // 히스토리 탭으로 전환될 때 새로고침
                    if tab == .quiz && previousTab != .quiz {
                        return .send(.quiz(.onAppear))
                    }

                    return .none

                case .toggleRegisterMenu:
                    guard !state.home.isGoalCompleted else { return .none }
                    state.isRegisterMenuExpanded.toggle()
                    return .none

                case .registerMenuItemTapped(let item):
                    guard !state.home.isGoalCompleted else { return .none }
                    Log.app.debug("메뉴 아이템 선택: \(item)")
                    state.isRegisterMenuExpanded = false
                    if item == .category {
                        state.addSubject = AddSubjectFeature.State()
                    } else if item == .fileUpload {
                        state.addSubjectFile = AddSubjectFileFeature.State()
                    }
                    return .none
                    
                case .home(.delegate(.startNewGoalTapped)):
                    state.newGoalFlow = NewGoalFlowFeature.State()
                    return .none

                case .newGoalFlow(.delegate(.completed)):
                    state.newGoalFlow = nil
                    return .send(.home(.onAppear))

                case .newGoalFlow(.delegate(.cancelled)):
                    state.newGoalFlow = nil
                    if state.home.isGoalCompleted {
                        state.home.showGoalCompletedAlert = true
                    }
                    return .none

                case .home(.delegate(.openMyPageRequested)):
                    state.myPage = MyPageFeature.State()
                    Log.app.debug("Home에서 MyPage 열기")
                    return .none

                // Home에서 QuizFlow 시작 (summaryData 포함)
                case .home(.delegate(.startQuizFlow(let quizzes, let summaryData, let isQuizGuideSeen))):
                    state.quizFlow = QuizFlowFeature.State(
                        quizzes: quizzes,
                        summaryData: summaryData,
                        isQuizGuideSeen: isQuizGuideSeen
                    )
                    Log.app.debug("퀴즈 플로우 시작 - 요약부터 표시")
                    return .none
                    
                case .quiz(.delegate(.openMyPageRequested)):
                    state.myPage = MyPageFeature.State()
                    Log.app.debug("History에서 MyPage 열기")
                    return .none
                    
                case .myPage(.delegate(.dismissed)):
                    state.myPage = nil
                    if state.home.isGoalCompleted {
                        state.home.showGoalCompletedAlert = true
                    }
                    Log.app.debug("MyPage 닫힘")
                    return .none
                    
                case .myPage(.delegate(.logout)):
                    Log.app.debug("MainTab: MyPage에서 로그아웃 요청 받음")
                    return .send(.delegate(.logout))
                    
                case .quizFlow(.delegate(.completed(let destination))):
                    state.quizFlow = nil
                    Log.app.debug("퀴즈 플로우 완료 - 이동: \(destination)")

                    switch destination {
                    case .home:
                        state.selectedTab = .home
                        return .send(.home(.onAppear))

                    case .history:
                        state.selectedTab = .quiz
                        return .send(.quiz(.onAppear))
                    }
                    
                case .quizFlow(.delegate(.cancelled)):
                    state.quizFlow = nil
                    Log.app.debug("퀴즈 플로우 취소")
                    return .send(.home(.onAppear))
                    
                case .addSubject(.delegate(.completed)):
                    state.addSubject = nil
                    Log.app.debug("주제 추가 완료 - 홈 새로고침")
                    state.selectedTab = .home
                    return .send(.home(.onAppear))

                case .addSubject(.delegate(.cancelled)):
                    state.addSubject = nil
                    Log.app.debug("주제 추가 취소 - Sheet 닫힘")
                    return .none

                case .addSubjectFile(.delegate(.completed)):
                    state.addSubjectFile = nil
                    Log.app.debug("파일 주제 추가 완료 - 홈 새로고침")
                    state.selectedTab = .home
                    return .send(.home(.onAppear))

                case .addSubjectFile(.delegate(.cancelled)):
                    Log.app.debug("파일 주제 추가 취소 - Sheet 닫힘")
                    state.addSubjectFile = nil
                    return .none
                    
                case .myPage(.delegate(.withdrawal)):
                    Log.app.debug("MainTabFeature: 회원탈퇴 요청 받음")
                    return .send(.delegate(.withdrawal))

                case .home, .quiz, .newGoalFlow, .addSubject, .addSubjectFile, .quizFlow, .myPage, .delegate:
                    return .none
                }
            }
        .ifLet(\.newGoalFlow, action: \.newGoalFlow) {
            NewGoalFlowFeature()
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
