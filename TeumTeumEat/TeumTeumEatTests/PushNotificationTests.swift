//
//  PushNotificationTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import OnboardingFeature
import Testing
@testable import TeumTeumEat

@MainActor
struct PushNotificationTests {
    @Test("리그 알림을 누르면 리그 화면을 띄우고 진입 위치와 알림 열림을 기록한다", arguments: [
        PushNotificationType.leagueDeadline, .leagueResult
    ])
    func leaguePush_presentsLeague(type: PushNotificationType) async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: MainTabFeature.State()) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(pushType: type.rawValue)) {
            $0.destination = .league(LeagueFeature.State())
        }
        #expect(events.value == [
            .leagueView(source: "push"),
            .pushOpen(pushType: type.rawValue, destination: "league")
        ])
    }

    @Test("기존 리그에서 알림을 누르면 최신 순위와 결과를 조회하고, 이미 본 결과는 다시 띄우지 않는다", arguments: [
        PushNotificationType.leagueDeadline, .leagueResult
    ], [false, true])
    func leaguePush_onLeague_refreshes(type: PushNotificationType, hasSeenResult: Bool) async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let requests = LockIsolated<[String]>([])
        let result = LeagueWeekResult(weekStartDate: "2026-10-05", rank: 2, weeklySnackCount: 20)
        let seenWeek = LockIsolated<String?>(hasSeenResult ? result.weekStartDate : nil)
        let mock = LeagueResponse.mock
        let updated = LeagueResponse(
            weekStartDate: mock.weekStartDate, resetAt: mock.resetAt,
            remainingSeconds: 0, rankers: mock.rankers, me: mock.me
        )
        var state = MainTabFeature.State()
        state.selectedTab = .quiz
        state.destination = .league(LeagueFeature.State(league: .mockNotParticipating))
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
            $0.leagueClient.fetchLeague = {
                requests.withValue { $0.append("league") }
                return updated
            }
            $0.leagueClient.fetchLatestResult = {
                requests.withValue { $0.append("result") }
                return result
            }
            $0.leagueClient.lastSeenResultWeek = { seenWeek.value }
            $0.leagueClient.setLastSeenResultWeek = { week in seenWeek.setValue(week) }
            $0.date.now = Date(timeIntervalSince1970: 1_800_000_000)
        }
        // 두 API의 응답 순서는 보장되지 않으므로 최종 데이터와 호출 횟수를 검증한다.
        store.exhaustivity = .off

        await store.send(.pushNotificationOpened(pushType: type.rawValue))
        await store.finish()
        await store.skipReceivedActions()

        guard case let .league(league) = store.state.destination else {
            Issue.record("리그 화면이 유지되어야 한다")
            return
        }
        #expect(store.state.selectedTab == .quiz)
        #expect(league.league == updated)
        #expect(!league.isLoading)
        #expect(league.weekResult == (hasSeenResult ? nil : result))
        #expect(seenWeek.value == result.weekStartDate)
        #expect(requests.value.sorted() == ["league", "result"])
        #expect(events.value == [.pushOpen(pushType: type.rawValue, destination: "league")])
    }

    @Test("홈에서 다음 날 학습 알림을 누르면 이전 완료 상태를 최신 퀴즈 상태로 갱신한다")
    func dailyQuizPush_onHome_refreshesCompletedQuiz() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let statusRequests = LockIsolated(0)
        var state = MainTabFeature.State()
        state.home.currentGoal = Fixture.goal()
        state.home.quizStatus = Fixture.quizStatus(hasSolvedToday: true, availableQuizCount: 0)
        state.home.isTodayQuizCompleted = true
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
            $0.historyClient.fetchCalendarHistory = { _, _ in Fixture.calendar }
            $0.goalClient.fetchCurrentGoal = { Fixture.goal() }
            $0.quizClient.fetchUserQuizStatus = {
                statusRequests.withValue { $0 += 1 }
                return Fixture.quizStatus()
            }
        }
        store.exhaustivity = .off

        await store.send(.pushNotificationOpened(pushType: "DAILY_QUIZ"))
        await store.finish()
        await store.skipReceivedActions()

        #expect(store.state.selectedTab == .home)
        #expect(store.state.destination == nil)
        #expect(store.state.home.quizStatus == Fixture.quizStatus())
        #expect(!store.state.home.isTodayQuizCompleted)
        #expect(store.state.home.availableQuizCount == 1)
        #expect(statusRequests.value == 1)
        #expect(events.value == [.pushOpen(pushType: "DAILY_QUIZ", destination: "home")])
    }

    @Test("학습 알림을 누르면 열려 있던 마이페이지를 닫고 홈 탭으로 이동한다")
    func dailyQuizPush_goesHome() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = MainTabFeature.State()
        state.selectedTab = .quiz
        state.destination = .myPage(MyPageFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(pushType: "DAILY_QUIZ")) {
            $0.destination = nil
            $0.selectedTab = .home
        }
        #expect(events.value == [.pushOpen(pushType: "DAILY_QUIZ", destination: "home")])
    }

    @Test("주제 추가 같은 진행 중인 흐름이 열려 있으면 알림을 눌러도 이동하지 않고 none으로 기록한다")
    func push_duringFlow_doesNotNavigate() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = MainTabFeature.State()
        state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(pushType: "LEAGUE_RESULT"))
        await store.send(.pushNotificationOpened(pushType: "DAILY_QUIZ"))
        #expect(events.value == [
            .pushOpen(pushType: "LEAGUE_RESULT", destination: "none"),
            .pushOpen(pushType: "DAILY_QUIZ", destination: "none")
        ])
    }

    @Test("모르는 알림 종류는 이동하지 않고 받은 값 그대로 none으로 기록한다")
    func unknownPush_doesNotNavigate() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: MainTabFeature.State()) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(pushType: "NEW_TYPE"))
        #expect(events.value == [.pushOpen(pushType: "NEW_TYPE", destination: "none")])
    }

    @Test("앱이 꺼져 있다가 알림으로 실행되면 메인 화면이 뜬 뒤 리그 화면으로 이동한다")
    func coldLaunchPush_opensAfterMainTabAppears() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.analyticsClient.log = { _ in }
        }
        // 메인 화면 상태는 탭 항목 UUID 등 매번 새로 만들어지는 값이 있어 필요한 값만 검증
        store.exhaustivity = .off

        await store.send(.pushNotificationTapped(pushType: "LEAGUE_RESULT")) {
            $0.pendingPushType = "LEAGUE_RESULT"
        }
        #expect(store.state.mainTab == nil)

        await store.send(.splash(.authenticationChecked(.authenticated(isOnboardingCompleted: true))))
        await store.receive(\.mainTab.pushNotificationOpened)

        #expect(store.state.pendingPushType == nil)
        #expect(store.state.mainTab?.destination == .league(LeagueFeature.State()))
    }

    @Test("앱이 꺼져 있다가 알림으로 실행됐는데 로그인이 필요하면 login으로 한 번만 기록한다")
    func coldLaunchPush_unauthenticated_logsLogin() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.pushNotificationTapped(pushType: "DAILY_QUIZ"))
        #expect(events.value.isEmpty)

        await store.send(.splash(.authenticationChecked(.unauthenticated)))
        #expect(store.state.pendingPushType == nil)
        #expect(events.value == [.pushOpen(pushType: "DAILY_QUIZ", destination: "login")])
    }

    @Test("온보딩 화면에서 알림을 누르면 이동하지 않고 onboarding으로 기록한다")
    func push_duringOnboarding_logsOnboarding() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = AppFeature.State()
        state.isShowingSplash = false
        state.onboarding = OnboardingFeature.State()
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.pushNotificationTapped(pushType: "LEAGUE_DEADLINE"))
        #expect(store.state.pendingPushType == nil)
        #expect(events.value.contains(.pushOpen(pushType: "LEAGUE_DEADLINE", destination: "onboarding")))
    }

    @Test("메인 화면이 떠 있으면 알림을 누르자마자 이동한다")
    func warmPush_opensImmediately() async {
        var state = AppFeature.State()
        state.isShowingSplash = false
        state.mainTab = MainTabFeature.State()
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.analyticsClient.log = { _ in }
        }

        await store.send(.pushNotificationTapped(pushType: "LEAGUE_DEADLINE"))
        await store.receive(\.mainTab.pushNotificationOpened) {
            $0.mainTab?.destination = .league(LeagueFeature.State())
        }
    }
}
