//
//  MainTabFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

@Reducer
struct MainTabFeature {
    /// MainTab에서 띄우는 화면 (한 번에 하나만 표시)
    /// destination이 nil이 되면 해당 화면의 effect(SSE, 타이머 등)가 자동으로 취소됨
    @Reducer
    enum Destination {
        case newGoalFlow(NewGoalFlowFeature)
        case addSubject(AddSubjectFlowFeature)
        case quizFlow(QuizFlowFeature)
        case myPage(MyPageFeature)
        case league(LeagueFeature)
    }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .home
        var isRegisterMenuExpanded: Bool = false

        // 각 탭의 Feature State
        var home: HomeFeature.State = .init()
        var quiz: HistoryFeature.State = .init()

        @Presents var destination: Destination.State?

        var isMyPagePresented: Bool {
            if case .myPage = destination { return true }
            return false
        }

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
        case destination(PresentationAction<Destination.Action>)
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

    @Dependency(\.analyticsClient) var analyticsClient
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
                let contentType: OnboardingData.ContentType = item == .category ? .category : .fileUpload
                state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: contentType))
                analyticsClient.log(.subjectAddStart(contentType: contentType.analyticsValue, source: "home_menu"))
                return .none

            // MARK: - Home / History → 화면 표시
            case .home(.delegate(.startNewGoalTapped)):
                state.destination = .newGoalFlow(NewGoalFlowFeature.State())
                return .none

            case .home(.delegate(.openMyPageRequested)):
                state.destination = .myPage(MyPageFeature.State())
                Log.app.debug("Home에서 MyPage 열기")
                return .none

            // Home에서 QuizFlow 시작 (summaryData 포함)
            case .home(.delegate(.startQuizFlow(let quizzes, let summaryData, let isQuizGuideSeen))):
                state.destination = .quizFlow(QuizFlowFeature.State(
                    quizzes: quizzes,
                    summaryData: summaryData,
                    isQuizGuideSeen: isQuizGuideSeen
                ))
                analyticsClient.log(.summaryView(
                    contentType: summaryData.documentType.analyticsValue,
                    isFirstTime: summaryData.isFirstTime
                ))
                Log.app.debug("퀴즈 플로우 시작 - 요약부터 표시")
                return .none

            case .quiz(.delegate(.openMyPageRequested)):
                state.destination = .myPage(MyPageFeature.State())
                Log.app.debug("History에서 MyPage 열기")
                return .none

            case .home(.delegate(.openLeagueRequested)),
                 .quiz(.delegate(.openLeagueRequested)):
                state.destination = .league(LeagueFeature.State())
                return .none

            // MARK: - League
            // TODO: 순위 올리기 이동 화면 기획 확정 후 수정 (현재는 홈 탭으로 이동)
            case .destination(.presented(.league(.delegate(.rankUpRequested)))):
                state.destination = nil
                state.selectedTab = .home
                return .none

            // MARK: - NewGoalFlow
            case .destination(.presented(.newGoalFlow(.delegate(.completed)))):
                state.destination = nil
                return .send(.home(.onAppear))

            case .destination(.presented(.newGoalFlow(.delegate(.cancelled)))):
                state.destination = nil
                showGoalCompletedAlertIfNeeded(&state)
                return .none

            // MARK: - MyPage
            case .destination(.presented(.myPage(.delegate(.dismissed)))):
                state.destination = nil
                Log.app.debug("MyPage 닫힘")
                return refreshHomeIfGoalCompleted(state)

            // 스와이프 뒤로가기로 MyPage가 닫힌 경우 (dismiss 처리 전이라 destination은 아직 myPage)
            case .destination(.dismiss):
                if state.isMyPagePresented {
                    Log.app.debug("MyPage 닫힘 (스와이프)")
                    return refreshHomeIfGoalCompleted(state)
                }
                return .none

            case .destination(.presented(.myPage(.delegate(.logout)))):
                Log.app.debug("MainTab: MyPage에서 로그아웃 요청 받음")
                return .send(.delegate(.logout))

            case .destination(.presented(.myPage(.delegate(.withdrawal)))):
                Log.app.debug("MainTabFeature: 회원탈퇴 요청 받음")
                return .send(.delegate(.withdrawal))

            // MARK: - QuizFlow
            case .destination(.presented(.quizFlow(.delegate(.completed(let destination))))):
                state.destination = nil
                Log.app.debug("퀴즈 플로우 완료 - 이동: \(destination)")

                switch destination {
                case .home:
                    state.selectedTab = .home
                    return .send(.home(.onAppear))

                case .history:
                    state.selectedTab = .quiz
                    return .send(.quiz(.onAppear))
                }

            case .destination(.presented(.quizFlow(.delegate(.cancelled)))):
                state.destination = nil
                Log.app.debug("퀴즈 플로우 취소")
                return .send(.home(.onAppear))

            // MARK: - AddSubject
            case .destination(.presented(.addSubject(.delegate(.completed)))):
                state.destination = nil
                Log.app.debug("주제 추가 완료 - 홈 새로고침")
                state.selectedTab = .home
                return .send(.home(.onAppear))

            case .destination(.presented(.addSubject(.delegate(.cancelled)))):
                state.destination = nil
                Log.app.debug("주제 추가 취소 - 화면 닫힘")
                return .none

            case .home, .quiz, .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func showGoalCompletedAlertIfNeeded(_ state: inout State) {
        if state.home.isGoalCompleted {
            state.home.showGoalCompletedAlert = true
        }
    }

    /// MyPage에서 다른 목표로 전환했을 수 있으므로 알럿을 바로 띄우지 않고 서버 상태를 다시 조회
    /// 여전히 완료된 목표라면 fetchQuizStatusResponse에서 알럿이 다시 표시됨
    private func refreshHomeIfGoalCompleted(_ state: State) -> Effect<Action> {
        guard state.home.isGoalCompleted else { return .none }
        return .send(.home(.goalMayHaveChanged))
    }
}

extension MainTabFeature.Destination.State: Equatable {}
