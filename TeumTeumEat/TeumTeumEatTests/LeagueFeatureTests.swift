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
    private static let now = Date(timeIntervalSince1970: 1_800_000_000)
    /// 지난주 미참여 결과 (모달 표시 안 함)
    private static let notParticipatedResult = LeagueWeekResult(weekStartDate: "2026-09-28", rank: nil, weeklySnackCount: 0)

    @Test("첫 진입 시 리그 랭킹과 지난주 결과를 조회하고 리셋까지 남은 시간을 계산한다")
    func onAppear_loadsLeagueAndLatestResult() async {
        let league = LeagueResponse.mock.remaining(2 * 86400 + 61)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { league }
            $0.leagueClient.fetchLatestResult = { Self.notParticipatedResult }
            $0.date.now = Self.now
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = league
            $0.resetDate = Self.now.addingTimeInterval(2 * 86400 + 61)
            $0.remainingSeconds = 2 * 86400 + 61
        }
        await store.receive(\.latestResultLoaded.success)
        #expect(store.state.remainingTimeText == "2일 00 : 01 : 01")

        await store.skipCountdownTimer()
    }

    @Test("이미 조회한 리그가 있으면 다시 진입해도 조회하지 않는다")
    func onAppear_withLoadedLeague_doesNotRefetch() async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        }

        await store.send(.onAppear)
    }

    @Test("1초마다 남은 시간을 갱신하고, 리셋 시각이 되면 새 주차 리그와 지난주 결과를 다시 조회한다")
    func timer_countsDown_thenRefetchesAtReset() async {
        let clock = TestClock()
        let now = LockIsolated(Self.now)
        let nextWeek = LeagueResponse.mockNotParticipating.remaining(7 * 86400)
        let fetchCount = LockIsolated(0)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = {
                fetchCount.withValue { $0 += 1 }
                return fetchCount.value == 1 ? LeagueResponse.mock.remaining(2) : nextWeek
            }
            $0.leagueClient.fetchLatestResult = { Self.notParticipatedResult }
            $0.date = DateGenerator { now.value }
            $0.continuousClock = clock
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = LeagueResponse.mock.remaining(2)
            $0.resetDate = Self.now.addingTimeInterval(2)
            $0.remainingSeconds = 2
        }
        await store.receive(\.latestResultLoaded.success)

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
            $0.resetDate = Self.now.addingTimeInterval(2 + 7 * 86400)
            $0.remainingSeconds = 7 * 86400
        }
        await store.receive(\.latestResultLoaded.success)

        await store.skipCountdownTimer()
    }

    @Test("랭킹 조회에 실패하면 에러 메시지를 보여주고, 다시 시도하면 에러를 지우고 다시 조회한다")
    func loadFailure_thenRetry_loadsLeague() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = {
                if shouldFail.value {
                    throw APIError.networkError(URLError(.notConnectedToInternet))
                }
                return .mockNotParticipating
            }
            $0.leagueClient.fetchLatestResult = { Self.notParticipatedResult }
            $0.date.now = Self.now
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }
        await store.receive(\.latestResultLoaded.success)

        shouldFail.setValue(false)
        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mockNotParticipating
            $0.resetDate = Self.now.addingTimeInterval(86400)
            $0.remainingSeconds = 86400
        }
        await store.receive(\.latestResultLoaded.success)

        await store.skipCountdownTimer()
    }

    @Test("지난주 결과 조회에 실패해도 랭킹 화면은 그대로 보여준다")
    func latestResultFailure_keepsLeague() async {
        let store = TestStore(initialState: LeagueFeature.State()) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.fetchLeague = { .mock }
            $0.leagueClient.fetchLatestResult = { throw APIError.networkError(URLError(.timedOut)) }
            $0.date.now = Self.now
            $0.continuousClock = TestClock()
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.leagueLoaded.success) {
            $0.isLoading = false
            $0.league = .mock
            $0.resetDate = Self.now.addingTimeInterval(86400)
            $0.remainingSeconds = 86400
        }
        await store.receive(\.latestResultLoaded.failure)

        await store.skipCountdownTimer()
    }

    @Test("새 주차의 지난주 결과를 아직 보지 않았으면 결과 모달을 띄우고 본 주차로 기록한다")
    func latestResult_unseen_showsModalAndMarksSeen() async {
        let seenWeek = LockIsolated<String?>("2026-09-21")
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.lastSeenResultWeek = { seenWeek.value }
            $0.leagueClient.setLastSeenResultWeek = { seenWeek.setValue($0) }
        }

        await store.send(.latestResultLoaded(.success(LeagueWeekResult.mock))) {
            $0.weekResult = LeagueWeekResult.mock
        }
        #expect(seenWeek.value == "2026-09-28")

        await store.send(.weekResultDismissed) {
            $0.weekResult = nil
        }
    }

    @Test("이미 본 주차이거나 지난주에 참여하지 않았으면 결과 모달을 띄우지 않는다", arguments: [
        (seenWeek: "2026-09-28", rank: 2 as Int?),
        (seenWeek: "2026-09-21", rank: nil as Int?)
    ])
    func latestResult_seenOrNotParticipated_doesNotShowModal(seenWeek: String, rank: Int?) async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.leagueClient.lastSeenResultWeek = { seenWeek }
        }

        await store.send(.latestResultLoaded(.success(
            LeagueWeekResult(weekStartDate: "2026-09-28", rank: rank, weeklySnackCount: 3)
        )))
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

    @Test("공유 버튼 → 다른 앱으로 공유를 고르면 클릭을 기록하고, 시트가 닫힌 뒤 초대 링크를 기본 공유 시트로 공유한다")
    func shareTapped_selectSystem_sharesInviteAfterSheetDismissed() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let shared = LockIsolated<[ShareContent]>([])
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
            $0.shareClient.shareToSystem = { content in shared.withValue { $0.append(content) } }
        }

        await store.send(.shareTapped) {
            $0.shareSheet = .league
        }
        await store.send(.shareChannelSelected(.system)) {
            $0.shareSheet = nil
            $0.pendingShare = .init(channel: .system, content: .invite)
        }
        // 시트가 완전히 닫히기 전에는 공유하지 않음
        #expect(shared.value.isEmpty)

        await store.send(.shareSheetDismissed) {
            $0.pendingShare = nil
        }
        await store.finish()

        #expect(shared.value == [.invite])
        #expect(events.value == [.shareClick(channel: "system", source: "league")])
    }

    @Test("결과 모달에서 공유하기 → 카카오톡을 고르면 모달을 닫고 순위 문구로 카카오톡 공유한다")
    func weekResultShare_selectKakao_sharesResult() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let shared = LockIsolated<[ShareContent]>([])
        var state = LeagueFeature.State(league: .mock)
        state.weekResult = LeagueWeekResult.mock
        let store = TestStore(initialState: state) {
            LeagueFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
            $0.shareClient.shareToKakao = { content in shared.withValue { $0.append(content) } }
        }

        await store.send(.weekResultShareTapped) {
            $0.weekResult = nil
            $0.shareSheet = .weekResult(LeagueWeekResult.mock)
        }
        await store.send(.shareChannelSelected(.kakao)) {
            $0.shareSheet = nil
            $0.pendingShare = .init(channel: .kakao, content: .leagueResult(LeagueWeekResult.mock))
        }
        await store.send(.shareSheetDismissed) {
            $0.pendingShare = nil
        }
        await store.finish()

        #expect(shared.value.map(\.text) == ["틈틈잇 9월 4주 리그에서 2위를 했어요! 같이 도전해 보세요."])
        #expect(events.value == [.shareClick(channel: "kakao", source: "league_result")])
    }

    @Test("공유 채널을 고르지 않고 시트를 닫으면 공유하지 않는다")
    func shareSheetClosedWithoutSelection_doesNotShare() async {
        let store = TestStore(initialState: LeagueFeature.State(league: .mock)) {
            LeagueFeature()
        }

        await store.send(.shareTapped) {
            $0.shareSheet = .league
        }
        await store.send(.shareSheetClosed) {
            $0.shareSheet = nil
        }
        await store.send(.shareSheetDismissed)
    }

    @Test("안내 모달에서 참여하기를 누르면 모달을 닫고 홈으로 이동을 요청한다")
    func infoJoinTapped_closesInfoAndRequestsHome() async {
        var state = LeagueFeature.State(league: .mock)
        state.isInfoPresented = true
        let store = TestStore(initialState: state) {
            LeagueFeature()
        }

        await store.send(.infoJoinTapped) {
            $0.isInfoPresented = false
        }
        await store.receive(\.delegate.rankUpRequested)
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

struct LeagueStateTests {
    @Test("리셋까지 하루 이상 남으면 일 + 시:분:초, 하루 미만이면 시:분:초로 표시한다", arguments: [
        (86399, "23 : 59 : 59"),
        (86400, "1일 00 : 00 : 00"),
        (4 * 86400 + 1304, "4일 00 : 21 : 44"),
        (0, "00 : 00 : 00")
    ])
    func remainingTimeText(seconds: Int, expected: String) {
        var state = LeagueFeature.State()
        state.remainingSeconds = seconds
        #expect(state.remainingTimeText == expected)
    }

    @Test("랭커가 10명 미만이면 4위부터 10위까지 남은 자리를 빈 순위로 채운다", arguments: [
        (0, Array(4...10)),
        (2, Array(4...10)),
        (6, Array(7...10)),
        (10, [Int]())
    ])
    func placeholderRanks(rankerCount: Int, expected: [Int]) {
        let rankers = (0..<rankerCount).map {
            LeagueRanker(rank: $0 + 1, name: "김*민", weeklySnackCount: 10 - $0, isMe: false)
        }
        let league = LeagueResponse(
            weekStartDate: "2026-10-05", resetAt: "2026-10-12T00:00:00", remainingSeconds: 100,
            rankers: rankers, me: LeagueMyRank(rank: nil, name: "크", weeklySnackCount: 0, todaySnackCount: 0)
        )
        #expect(LeagueFeature.State(league: league).placeholderRanks == expected)
    }
}

struct LeagueWeekResultTests {
    @Test("주차 표기는 주 시작일(월요일)이 그 달의 몇 번째 월요일인지 기준이다", arguments: [
        ("2026-09-28", "9월 4주"),
        ("2026-09-07", "9월 1주"),
        ("2026-08-31", "8월 5주"),
        ("2026-10-05", "10월 1주")
    ])
    func weekLabel(weekStartDate: String, expected: String) {
        let result = LeagueWeekResult(weekStartDate: weekStartDate, rank: 1, weeklySnackCount: 1)
        #expect(result.weekLabel == expected)
    }
}

struct LeagueShareContentTests {
    @Test("지난주 순위권 밖이면 순위 대신 초대 문구로 공유한다")
    func leagueResult_outOfRank_sharesInvite() {
        let result = LeagueWeekResult(weekStartDate: "2026-09-28", rank: 7, weeklySnackCount: 3)
        #expect(ShareContent.leagueResult(result) == .invite)
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

private extension LeagueResponse {
    func remaining(_ seconds: Int) -> LeagueResponse {
        LeagueResponse(weekStartDate: weekStartDate, resetAt: resetAt, remainingSeconds: seconds, rankers: rankers, me: me)
    }
}
