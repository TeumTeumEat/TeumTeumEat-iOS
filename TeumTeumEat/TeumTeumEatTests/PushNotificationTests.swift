//
//  PushNotificationTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Testing
@testable import TeumTeumEat

@MainActor
struct PushNotificationTests {
    @Test("푸시 data.type을 알림 종류로 변환하고, 모르는 값이나 없는 값은 무시한다")
    func pushNotificationType_fromUserInfo() {
        #expect(PushNotificationType(userInfo: ["type": "DAILY_QUIZ"]) == .dailyQuiz)
        #expect(PushNotificationType(userInfo: ["type": "LEAGUE_DEADLINE"]) == .leagueDeadline)
        #expect(PushNotificationType(userInfo: ["type": "LEAGUE_RESULT"]) == .leagueResult)
        #expect(PushNotificationType(userInfo: ["type": "UNKNOWN_TYPE"]) == nil)
        #expect(PushNotificationType(userInfo: ["gcm.message_id": "1"]) == nil)
    }

    @Test("리그 알림을 누르면 리그 화면을 띄우고 진입 위치를 push로 기록한다", arguments: [
        PushNotificationType.leagueDeadline, .leagueResult
    ])
    func leaguePush_presentsLeague(type: PushNotificationType) async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: MainTabFeature.State()) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.pushNotificationOpened(type)) {
            $0.destination = .league(LeagueFeature.State())
        }
        #expect(events.value == [.leagueView(source: "push")])
    }

    @Test("학습 알림을 누르면 열려 있던 마이페이지를 닫고 홈 탭으로 이동한다")
    func dailyQuizPush_goesHome() async {
        var state = MainTabFeature.State()
        state.selectedTab = .quiz
        state.destination = .myPage(MyPageFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.pushNotificationOpened(.dailyQuiz)) {
            $0.destination = nil
            $0.selectedTab = .home
        }
    }

    @Test("주제 추가 같은 진행 중인 흐름이 열려 있으면 알림을 눌러도 이동하지 않는다")
    func push_duringFlow_doesNotNavigate() async {
        var state = MainTabFeature.State()
        state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.pushNotificationOpened(.leagueResult))
        await store.send(.pushNotificationOpened(.dailyQuiz))
    }

    @Test("앱이 꺼져 있다가 알림으로 실행되면 메인 화면이 뜬 뒤 리그 화면으로 이동한다")
    func coldLaunchPush_opensAfterMainTabAppears() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        // 메인 화면 상태는 탭 항목 UUID 등 매번 새로 만들어지는 값이 있어 필요한 값만 검증
        store.exhaustivity = .off

        await store.send(.pushNotificationTapped(.leagueResult)) {
            $0.pendingPushNotification = .leagueResult
        }
        #expect(store.state.mainTab == nil)

        await store.send(.splash(.authenticationChecked(.authenticated(isOnboardingCompleted: true))))
        await store.receive(\.mainTab.pushNotificationOpened)

        #expect(store.state.pendingPushNotification == nil)
        #expect(store.state.mainTab?.destination == .league(LeagueFeature.State()))
    }

    @Test("메인 화면이 떠 있으면 알림을 누르자마자 이동한다")
    func warmPush_opensImmediately() async {
        var state = AppFeature.State()
        state.isShowingSplash = false
        state.mainTab = MainTabFeature.State()
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.pushNotificationTapped(.leagueDeadline))
        await store.receive(\.mainTab.pushNotificationOpened) {
            $0.mainTab?.destination = .league(LeagueFeature.State())
        }
    }
}
