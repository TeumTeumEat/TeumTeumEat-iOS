//
//  LeagueFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct LeagueFeatureTests {
    /// LeagueResponse.mock의 마감 시각 (2026-10-12T00:00:00+09:00)
    private static let weekEnd = DateFormatters.iso8601.date(from: LeagueResponse.mock.weekEndAt)!

    @Test("첫 진입 시 리그 랭킹을 조회하고 리셋까지 남은 시간을 계산한다")
    func onAppear_loadsLeague() async {
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { .mock }
            $0.date.now = Self.weekEnd.addingTimeInterval(-(2 * 86400 + 61))
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mock
            $0.remainingSeconds = 2 * 86400 + 61
        }
        // 하루 이상 남아도 일 단위로 바꾸지 않고 시간을 누적해서 표시
        #expect(store.state.remainingTimeText == "48 : 01 : 01")

        await store.skipCountdownTimer()
    }

    @Test("이미 조회한 리그가 있으면 다시 진입해도 조회하지 않는다")
    func onAppear_withLoadedLeague_doesNotRefetch() async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        }

        await store.send(.onAppear)
    }

    @Test("1초마다 남은 시간을 갱신하고, 리셋 시각이 되면 새 주차 리그를 다시 조회한다")
    func timer_countsDown_thenRefetchesAtReset() async {
        let clock = TestClock()
        let now = LockIsolated(Self.weekEnd.addingTimeInterval(-2))
        let nextWeek = LeagueResponse(
            isActive: true,
            weekEndAt: "2026-10-19T00:00:00+09:00",
            myRank: nil,
            rankers: []
        )
        let fetchCount = LockIsolated(0)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = {
                fetchCount.withValue { $0 += 1 }
                return fetchCount.value == 1 ? .mock : nextWeek
            }
            $0.date = DateGenerator { now.value }
            $0.continuousClock = clock
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mock
            $0.remainingSeconds = 2
        }

        now.withValue { $0.addTimeInterval(1) }
        await clock.advance(by: .seconds(1))
        await store.receive(\.timerTicked) {
            $0.remainingSeconds = 1
        }

        now.withValue { $0.addTimeInterval(1) }
        await clock.advance(by: .seconds(1))
        await store.receive(\.timerTicked) {
            $0.remainingSeconds = 0
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = nextWeek
            $0.remainingSeconds = 7 * 86400
        }

        await store.skipCountdownTimer()
    }

    @Test("조회에 실패하면 에러 메시지를 보여주고, 다시 시도하면 에러를 지우고 다시 조회한다")
    func loadFailure_thenRetry_loadsLeague() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = {
                if shouldFail.value {
                    throw APIError.networkError(URLError(.notConnectedToInternet))
                }
                return .mockInactive
            }
            $0.date.now = Self.weekEnd.addingTimeInterval(-10)
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }

        shouldFail.setValue(false)
        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mockInactive
            $0.remainingSeconds = 10
        }

        await store.skipCountdownTimer()
    }

    @Test("새 주차의 지난주 결과를 아직 보지 않았으면 결과 모달을 띄우고 본 주차로 기록한다")
    func lastWeekResult_unseen_showsModalAndMarksSeen() async {
        var league = LeagueResponse.mock
        league.lastWeekResult = LeagueWeekResult.mock
        let seenWeek = LockIsolated<String?>("2026-09-21")
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { league }
            $0.leagueClient.lastSeenResultWeek = { seenWeek.value }
            $0.leagueClient.setLastSeenResultWeek = { seenWeek.setValue($0) }
            $0.date.now = Self.weekEnd.addingTimeInterval(-10)
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = league
            $0.remainingSeconds = 10
            $0.weekResult = LeagueWeekResult.mock
        }
        #expect(seenWeek.value == "2026-09-28")

        await store.send(.weekResultDismissed) {
            $0.weekResult = nil
        }
        await store.skipCountdownTimer()
    }

    @Test("이미 본 주차이거나 지난주에 참여하지 않았으면 결과 모달을 띄우지 않는다", arguments: [
        (seenWeek: "2026-09-28", rank: 2 as Int?),
        (seenWeek: "2026-09-21", rank: nil as Int?)
    ])
    func lastWeekResult_seenOrNotParticipated_doesNotShowModal(seenWeek: String, rank: Int?) async {
        var league = LeagueResponse.mock
        league.lastWeekResult = LeagueWeekResult(weekStartDate: "2026-09-28", month: 9, weekOfMonth: 5, rank: rank)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { league }
            $0.leagueClient.lastSeenResultWeek = { seenWeek }
            $0.date.now = Self.weekEnd.addingTimeInterval(-10)
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = league
            $0.remainingSeconds = 10
        }
        await store.skipCountdownTimer()
    }

    @Test("i 버튼을 누르면 리그 안내를 띄우고, 딤을 탭하면 닫는다")
    func infoTapped_presentsAndDismissesInfo() async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        }

        await store.send(.infoTapped) {
            $0.isInfoPresented = true
        }
        await store.send(.infoDismissed) {
            $0.isInfoPresented = false
        }
    }

    @Test("순위 올리기를 누르면 클릭을 기록하고 상위 화면에 이동을 요청한다")
    func rankUpTapped_logsAndSendsDelegate() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }

        await store.send(.rankUpTapped)
        await store.receive(\.delegate.rankUpRequested)
        #expect(events.value == [.leagueRankUpClick])
    }

    @Test("뒤로가기를 누르면 화면을 닫는다")
    func backTapped_dismisses() async {
        let isDismissed = LockIsolated(false)
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect { isDismissed.setValue(true) }
        }

        await store.send(.backTapped)
        #expect(isDismissed.value)
    }
}

struct LeagueNicknameTests {
    @Test("리스트에서는 첫 글자와 마지막 글자만 남기고 가운데를 글자 수만큼 가린다", arguments: [
        ("가나다라마", "가***마"),
        ("이서민", "이*민"),
        ("이준", "이*"),
        ("윤", "윤"),
        ("", "")
    ])
    func masked(nickname: String, expected: String) {
        #expect(LeagueNickname.masked(nickname) == expected)
    }

    @Test("시상대에서는 가운데를 * 하나로 줄인다", arguments: [
        ("가나다라마", "가*마"),
        ("이서민", "이*민"),
        ("이준", "이*"),
        ("윤", "윤")
    ])
    func shortMasked(nickname: String, expected: String) {
        #expect(LeagueNickname.shortMasked(nickname) == expected)
    }

    @Test("이미 마스킹된 닉네임이 와도 같은 결과로 표시한다")
    func alreadyMasked() {
        #expect(LeagueNickname.masked("가***마") == "가***마")
        #expect(LeagueNickname.shortMasked("가***마") == "가*마")
    }
}

private extension TestStoreOf<LeagueFeature> {
    /// 타이머는 화면이 닫힐 때 MainTab의 @Presents가 취소하므로 단독 테스트에서는 건너뜀
    /// (skipInFlightEffects는 건너뛴 effect를 known issue로 남겨 결과가 "expected failure"로 표시되므로 기록을 끔)
    func skipCountdownTimer() async {
        await withExhaustivity(.off(showSkippedAssertions: false)) {
            await skipInFlightEffects()
        }
    }
}
