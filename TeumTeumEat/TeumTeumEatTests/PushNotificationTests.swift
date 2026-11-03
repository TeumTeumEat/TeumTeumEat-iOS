//
//  PushNotificationTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
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

    @Test("이미 리그 화면이면 리그 알림을 눌러도 그대로 두고 알림 열림만 기록한다")
    func leaguePush_onLeague_staysAndLogsOnlyPushOpen() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = MainTabFeature.State()
        state.destination = .league(LeagueFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(pushType: "LEAGUE_RESULT"))
        #expect(events.value == [.pushOpen(pushType: "LEAGUE_RESULT", destination: "league")])
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
