//
//  HomeFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct HomeFeatureTests {
    @Test("첫 진입 시 캘린더 + 목표를 조회하고, 목표 조회 후 퀴즈 상태를 조회한다")
    func onAppear_loadsHomeData() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal() }
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus() }
        }
        // 캘린더 / 목표 응답 순서는 보장되지 않으므로 최종 상태만 검증
        store.exhaustivity = .off

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.finish()
        await store.skipReceivedActions()  // 받은 응답 액션을 모두 반영

        store.assert {
            $0.fireCount = 2
            $0.stampCount = 3
            $0.calendarData = Fixture.calendar
            $0.currentGoal = Fixture.goal()
            $0.quizStatus = Fixture.quizStatus()
            $0.isTodayQuizCompleted = false
            $0.isLoading = false
            $0.showErrorOverlay = false
        }
    }

    @Test("퀴즈 상태 조회가 GOAL-002면 주제 완료 처리 후 진행 중인 주제가 있는지 조회한다")
    func quizStatusGoal002_marksGoalCompleted() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal() }
            $0.quizClient.fetchUserQuizStatus = {
                throw APIError.serverError(code: "GOAL-002", message: "목표 완료", details: nil)
            }
            $0.goalClient.fetchGoals = { [Fixture.goal(id: 2, categoryId: 20)] }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()  // 받은 응답 액션을 모두 반영

        store.assert {
            $0.isGoalCompleted = true
            $0.showGoalCompletedAlert = true
            $0.hasActiveSubjects = true
            $0.isLoading = false
        }
    }

    @Test("현재 목표 조회가 네트워크 오류로 실패하면 에러 오버레이를 표시한다")
    func currentGoalNetworkError_showsErrorOverlay() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = {
                throw APIError.networkError(URLError(.notConnectedToInternet))
            }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()  // 받은 응답 액션을 모두 반영

        store.assert {
            $0.showErrorOverlay = true
            $0.errorOverlayMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
            $0.isLoading = false
        }
    }

    @Test("이미 목표 데이터가 있으면 재진입 시 로딩 스피너를 띄우지 않는다")
    func onAppearWithExistingGoal_doesNotShowLoading() async {
        var state = HomeFeature.State()
        state.currentGoal = Fixture.goal()
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal() }
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus() }
        }
        store.exhaustivity = .off

        // isLoading이 true로 바뀌지 않아야 함 (상태 변화 없음)
        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()  // 받은 응답 액션을 모두 반영
        #expect(store.state.isLoading == false)
    }
}
