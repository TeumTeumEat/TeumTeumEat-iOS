//
//  MainTabFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Testing
@testable import TeumTeumEat

@MainActor
struct MainTabFeatureTests {
    @Test("+ 메뉴에서 주제찾기 / 자료올리기를 고르면 해당 주제 추가 흐름을 띄운다")
    func registerMenuItem_presentsAddSubject() async {
        var state = MainTabFeature.State()
        state.isRegisterMenuExpanded = true
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.registerMenuItemTapped(.category)) {
            $0.isRegisterMenuExpanded = false
            $0.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
        }
        await store.send(.destination(.presented(.addSubject(.delegate(.cancelled))))) {
            $0.destination = nil
        }
        await store.send(.registerMenuItemTapped(.fileUpload)) {
            $0.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .fileUpload))
        }
    }

    @Test("홈 / 히스토리에서 리그 진입을 요청하면 리그 화면을 띄운다")
    func openLeagueRequested_presentsLeague() async {
        let store = TestStore(initialState: MainTabFeature.State()) {
            MainTabFeature()
        }

        await store.send(.home(.delegate(.openLeagueRequested))) {
            $0.destination = .league(LeagueFeature.State())
        }
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
        await store.send(.quiz(.delegate(.openLeagueRequested))) {
            $0.destination = .league(LeagueFeature.State())
        }
    }

    @Test("리그에서 순위 올리기를 누르면 리그를 닫고 홈 탭으로 이동한다")
    func leagueRankUpRequested_goesToHome() async {
        var state = MainTabFeature.State()
        state.selectedTab = .quiz
        state.destination = .league(LeagueFeature.State(league: .mock))
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.destination(.presented(.league(.delegate(.rankUpRequested))))) {
            $0.destination = nil
            $0.selectedTab = .home
        }
    }

    @Test("주제 완료 상태에서 마이페이지를 스와이프로 닫으면 홈을 재조회하고, 여전히 완료면 알럿을 다시 띄운다")
    func swipeDismissMyPage_whenGoalStillCompleted_showsAlert() async {
        var state = MainTabFeature.State()
        state.home.isGoalCompleted = true
        state.destination = .myPage(MyPageFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal() }
            $0.quizClient.fetchUserQuizStatus = {
                throw APIError.serverError(code: "GOAL-002", message: "목표 완료", details: nil)
            }
            $0.goalClient.fetchGoals = { [] }
        }
        store.exhaustivity = .off

        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
        await store.receive(\.home.goalMayHaveChanged) {
            $0.home.isLoading = true
            $0.home.isPreparingSnack = true
        }
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.home.isGoalCompleted = true
            $0.home.showGoalCompletedAlert = true
            $0.home.isLoading = false
        }
    }

    @Test("마이페이지에서 다른 목표로 전환 후 닫으면 주제 완료 상태가 해제된다")
    func swipeDismissMyPage_afterGoalSwitch_clearsCompletedState() async {
        var state = MainTabFeature.State()
        state.home.isGoalCompleted = true
        state.destination = .myPage(MyPageFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal(id: 2, categoryId: 20) }
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus() }
        }
        store.exhaustivity = .off

        await store.send(.destination(.dismiss))
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.destination = nil
            $0.home.isGoalCompleted = false
            $0.home.showGoalCompletedAlert = false
            $0.home.isLoading = false
        }
    }

    @Test("주제 완료 상태에서는 탭 전환과 + 메뉴가 동작하지 않는다")
    func goalCompleted_blocksTabAndMenu() async {
        var state = MainTabFeature.State()
        state.home.isGoalCompleted = true
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.tabSelected(.quiz))
        await store.send(.toggleRegisterMenu)
        await store.send(.registerMenuItemTapped(.category))
    }
}
