//
//  HistoryFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct HistoryFeatureTests {
    @Test("첫 진입 시 이번 달 캘린더와 주제별 기록, 진행 중인 주제를 조회한다")
    func onAppear_loadsCalendarAndTopics() async {
        let store = TestStore(initialState: HistoryFeature.State(currentYear: 2026, currentMonth: 10)) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.historyClient.fetchHistoryTopics = { Fixture.topicCategories }
            $0.goalClient.fetchGoals = { [Fixture.goal(id: 1), Fixture.goal(id: 2, isCompleted: true)] }
        }
        // 병렬 조회라 응답 순서가 보장되지 않으므로 최종 상태만 검증
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.calendarData = Fixture.calendar
            $0.fireCount = 2
            $0.stampCount = 3
            $0.topicCategories = Fixture.topicCategories
            $0.activeGoals = [Fixture.goal(id: 1)]  // 완료된 주제는 제외
            $0.isLoadingTopics = false
        }
    }

    @Test("주제별 탭을 처음 선택하면 주제별 기록을 조회하고 탭 선택을 기록한다")
    func selectTopicTab_firstTime_fetchesTopics() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchHistoryTopics = { Fixture.topicCategories }
            $0.goalClient.fetchGoals = { [] }
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.tabSelected(1)) {
            $0.selectedTab = 1
        }
        await store.receive(\.fetchTopicHistories)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.topicCategories = Fixture.topicCategories
            $0.isLoadingTopics = false
        }
        #expect(events.value == [.historyTabSelect(tab: "topic")])
    }

    @Test("주제별 기록이 이미 있으면 탭 전환 시 다시 조회하지 않는다")
    func selectTab_withLoadedTopics_doesNotRefetch() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = HistoryFeature.State()
        state.topicCategories = Fixture.topicCategories
        let store = TestStore(initialState: state) {
            HistoryFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.tabSelected(1)) {
            $0.selectedTab = 1
        }
        await store.send(.tabSelected(0)) {
            $0.selectedTab = 0
        }

        #expect(events.value == [.historyTabSelect(tab: "topic"), .historyTabSelect(tab: "date")])
    }

    @Test("월을 바꾸면 날짜 선택을 초기화하고 해당 월 캘린더를 조회한다")
    func monthChanged_resetsSelectionAndLoadsCalendar() async {
        var state = HistoryFeature.State(currentYear: 2026, currentMonth: 10)
        state.selectedDateString = "2026-10-01"
        state.selectedDateHistoryItems = Fixture.historyItems
        let requested = LockIsolated<[Int]>([])
        let store = TestStore(initialState: state) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { year, month in
                requested.withValue { $0 = [year, month] }
                return Fixture.calendar
            }
        }

        await store.send(.monthChanged(year: 2026, month: 9)) {
            $0.currentMonth = 9
            $0.selectedDateString = nil
            $0.selectedDateHistoryItems = []
        }
        await store.receive(\.calendarDataLoaded.success) {
            $0.calendarData = Fixture.calendar
            $0.fireCount = 2
            $0.stampCount = 3
        }

        #expect(requested.value == [2026, 9])
    }

    @Test("날짜를 선택하면 그 날의 기록을 조회하고, 선택 해제하면 비운다")
    func dateSelected_loadsAndClearsItems() async {
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchHistoryByDate = { _ in Fixture.historyItems }
        }

        await store.send(.dateSelected("2026-10-01")) {
            $0.selectedDateString = "2026-10-01"
        }
        await store.receive(\.historyItemsLoaded.success) {
            $0.selectedDateHistoryItems = Fixture.historyItems
        }

        await store.send(.dateSelected(nil)) {
            $0.selectedDateString = nil
            $0.selectedDateHistoryItems = []
        }
    }

    @Test("캘린더 조회 실패 시 에러를 표시하고, 재시도하면 다시 조회한다")
    func calendarFailure_thenRetry() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: HistoryFeature.State(currentYear: 2026, currentMonth: 10)) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchCalendarHistory = { _, _ in
                if shouldFail.value { throw URLError(.notConnectedToInternet) }
                return Fixture.calendar
            }
        }

        await store.send(.monthChanged(year: 2026, month: 10))
        await store.receive(\.calendarDataLoaded.failure) {
            $0.calendarError = "에러가 발생했습니다."
        }

        shouldFail.setValue(false)
        await store.send(.retryCalendar) {
            $0.calendarError = nil
        }
        await store.receive(\.calendarDataLoaded.success) {
            $0.calendarData = Fixture.calendar
            $0.fireCount = 2
            $0.stampCount = 3
        }
    }

    @Test("주제별 기록 조회 실패 시 에러를 표시하고, 재시도하면 다시 조회한다")
    func topicFailure_thenRetry() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        } withDependencies: {
            $0.historyClient.fetchHistoryTopics = {
                if shouldFail.value { throw URLError(.notConnectedToInternet) }
                return Fixture.topicCategories
            }
            $0.goalClient.fetchGoals = { [] }
        }
        store.exhaustivity = .off

        await store.send(.fetchTopicHistories)
        await store.finish()
        await store.skipReceivedActions()
        store.assert {
            $0.isLoadingTopics = false
            $0.topicError = "에러가 발생했습니다."
        }

        shouldFail.setValue(false)
        await store.send(.retryTopicHistories) {
            $0.topicError = nil
        }
        await store.finish()
        await store.skipReceivedActions()
        store.assert {
            $0.isLoadingTopics = false
            $0.topicCategories = Fixture.topicCategories
        }
    }

    @Test("진행 중 필터를 켜면 진행 중인 주제의 기록만 보여준다")
    func filterToggled_showsOnlyActiveTopics() async {
        var state = HistoryFeature.State()
        state.topicCategories = Fixture.topicCategories
        state.activeGoals = [Fixture.goal()]  // 카테고리 이름: SwiftUI
        let store = TestStore(initialState: state) {
            HistoryFeature()
        }

        #expect(store.state.filteredTopicCategories == Fixture.topicCategories)

        await store.send(.filterToggled) {
            $0.showOnlyActive = true
        }
        #expect(store.state.filteredTopicCategories.map(\.categoryName) == ["SwiftUI"])
    }

    @Test("기록을 누르면 상세 요약을 열고, 상세에서 닫으면 해제한다")
    func historyItemTapped_presentsAndDismissesDetail() async {
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        }

        await store.send(.historyItemTapped(id: 2, type: "DOCUMENT", date: "2026-10-01")) {
            $0.historyDetailSummary = HistoryDetailSummaryFeature.State(
                historyId: 2,
                documentType: .document,
                date: "2026-10-01"
            )
        }
        await store.send(.historyDetailSummary(.presented(.delegate(.dismissed)))) {
            $0.historyDetailSummary = nil
        }
    }

    @Test("설정 버튼을 누르면 마이페이지 이동을 요청한다")
    func settingTapped_requestsMyPage() async {
        let store = TestStore(initialState: HistoryFeature.State()) {
            HistoryFeature()
        }

        await store.send(.settingTapped)
        await store.receive(\.delegate)  // Delegate는 openMyPageRequested 하나뿐
    }
}
