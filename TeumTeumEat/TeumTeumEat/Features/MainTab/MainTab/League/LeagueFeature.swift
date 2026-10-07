//
//  LeagueFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture
import Lottie

/// 주간 리그 랭킹 화면 (Home / History에서 push로 진입)
@Reducer
struct LeagueFeature {
    @ObservableState
    struct State: Equatable {
        var league: LeagueResponse?
        var isLoading: Bool = false
        var errorMessage: String?
        /// 리그 리셋 시각 (응답 받은 시각 + remainingSeconds, 서버 resetAt은 타임존이 없어 사용하지 않음)
        var resetDate: Date?
        /// 리그 리셋까지 남은 시간 (초)
        var remainingSeconds: Int = 0
        /// 지난주 결과 모달 (nil이 아니면 딤 위에 표시)
        var weekResult: LeagueWeekResult?
        /// 리그 안내 모달 (i 버튼)
        var isInfoPresented: Bool = false
        /// 공유 채널 선택 바텀시트 (nil이 아니면 표시)
        var shareSheet: ShareSource?
        /// 바텀시트에서 고른 공유 (시트가 완전히 닫힌 뒤 실행해야 공유 화면이 겹치지 않음)
        var pendingShare: PendingShare?

        enum ShareSource: Equatable {
            /// 리그 화면 네비게이션 바 공유 버튼
            case league
            /// 지난주 결과 모달 "공유하기"
            case weekResult(LeagueWeekResult)

            var analyticsValue: String {
                switch self {
                case .league: "league"
                case .weekResult: "league_result"
                }
            }

            var content: ShareContent {
                switch self {
                case .league: .invite
                case let .weekResult(result): .leagueResult(result)
                }
            }
        }

        struct PendingShare: Equatable {
            let channel: ShareChannel
            let content: ShareContent
        }

        /// 1~3위 시상대
        var podium: [LeagueRanker] { Array(league?.rankers.prefix(3) ?? []) }
        /// 4위 이하 리스트
        var restRankers: [LeagueRanker] { Array(league?.rankers.dropFirst(3) ?? []) }

        /// "23 : 20 : 10" (하루 이상 남으면 시간을 누적해서 "48 : 00 : 00")
        var remainingTimeText: String {
            let hours = remainingSeconds / 3600
            let minutes = remainingSeconds % 3600 / 60
            let seconds = remainingSeconds % 60
            return String(format: "%02d : %02d : %02d", hours, minutes, seconds)
        }
    }

    enum Action {
        case onAppear
        case retryTapped
        case backTapped
        case shareTapped
        case infoTapped
        case rankUpTapped
        case weekResultDismissed
        case infoDismissed
        case weekResultShareTapped
        case shareChannelSelected(ShareChannel)
        case shareSheetClosed
        case shareSheetDismissed
        case leagueLoaded(Result<LeagueResponse, Error>)
        case latestResultLoaded(Result<LeagueWeekResult, Error>)
        case timerTicked
        case delegate(Delegate)
    }

    @CasePathable
    enum Delegate {
        /// "순위 올리기" → 퀴즈를 풀 수 있는 화면으로 이동
        case rankUpRequested
    }

    private enum CancelID { case timer }

    @Dependency(\.leagueClient) var leagueClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now
    @Dependency(\.continuousClock) var clock
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.shareClient) var shareClient
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 하위 화면에서 돌아올 때 다시 조회하지 않도록 첫 진입에만 조회
                guard state.league == nil, !state.isLoading else { return .none }
                return fetchLeague(&state)

            case .retryTapped:
                return fetchLeague(&state)

            case .backTapped:
                return .run { _ in await dismiss() }

            case .shareTapped:
                state.shareSheet = .league
                return .none

            case .infoTapped:
                state.isInfoPresented = true
                return .none

            case .infoDismissed:
                state.isInfoPresented = false
                return .none

            case .rankUpTapped:
                analyticsClient.log(.leagueRankUpClick)
                return .send(.delegate(.rankUpRequested))

            case .weekResultDismissed:
                state.weekResult = nil
                return .none

            case .weekResultShareTapped:
                guard let result = state.weekResult else { return .none }
                state.weekResult = nil
                state.shareSheet = .weekResult(result)
                return .none

            case let .shareChannelSelected(channel):
                guard let source = state.shareSheet else { return .none }
                analyticsClient.log(.shareClick(channel: channel.rawValue, source: source.analyticsValue))
                state.pendingShare = State.PendingShare(channel: channel, content: source.content)
                state.shareSheet = nil
                return .none

            case .shareSheetClosed:
                // 드래그로 닫음 (공유 선택 없음)
                state.shareSheet = nil
                return .none

            case .shareSheetDismissed:
                guard let share = state.pendingShare else { return .none }
                state.pendingShare = nil
                return .run { _ in
                    switch share.channel {
                    case .kakao:
                        do {
                            try await shareClient.shareToKakao(share.content)
                        } catch {
                            Log.league.error("Kakao share failed: \(error)")
                        }
                    case .system:
                        await shareClient.shareToSystem(share.content)
                    }
                }

            case .leagueLoaded(.success(let league)):
                state.isLoading = false
                state.league = league
                Log.league.debug("League loaded: myRank=\(String(describing: league.me.rank)), rankers=\(league.rankers.count)")

                state.resetDate = now.addingTimeInterval(TimeInterval(league.remainingSeconds))
                state.remainingSeconds = max(0, league.remainingSeconds)
                guard state.remainingSeconds > 0 else { return .cancel(id: CancelID.timer) }
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timerTicked)
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)

            case .leagueLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                Log.league.error("Failed to load league: \(error)")
                return .none

            case .latestResultLoaded(.success(let result)):
                showWeekResultIfNeeded(&state, result: result)
                return .none

            case .latestResultLoaded(.failure(let error)):
                // 결과 모달은 부가 기능이라 실패해도 화면에 에러를 띄우지 않음
                Log.league.error("Failed to load latest league result: \(error)")
                return .none

            case .timerTicked:
                // 1초씩 빼지 않고 매번 마감 시각 기준으로 다시 계산 (백그라운드 다녀와도 정확하도록)
                guard let resetDate = state.resetDate else { return .none }
                state.remainingSeconds = remainingSeconds(until: resetDate)
                guard state.remainingSeconds == 0 else { return .none }
                // 리셋 시각이 지나면 새 주차 리그와 방금 끝난 주 결과를 다시 조회
                return .merge(
                    .cancel(id: CancelID.timer),
                    fetchLeague(&state)
                )

            case .delegate:
                return .none
            }
        }
    }

    /// 지난주에 참여했고 아직 보지 않은 주차면 결과 모달을 한 번 띄움
    private func showWeekResultIfNeeded(_ state: inout State, result: LeagueWeekResult) {
        guard result.rank != nil,
              leagueClient.lastSeenResultWeek() != result.weekStartDate else { return }
        state.weekResult = result
        leagueClient.setLastSeenResultWeek(result.weekStartDate)
    }

    private func remainingSeconds(until date: Date) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    /// 랭킹과 지난주 결과를 함께 조회 (결과는 모달 표시 여부 판단용)
    private func fetchLeague(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .merge(
            .run { send in
                await send(.leagueLoaded(Result { try await leagueClient.fetchLeague() }))
            },
            .run { send in
                await send(.latestResultLoaded(Result { try await leagueClient.fetchLatestResult() }))
            }
        )
    }
}

// MARK: - View

private extension Color {
    /// 배경 그라데이션 시작색 (0% #FAFFD2 → 100% #FFFFFF)
    static let leagueBackgroundTop = Color(hex: "#FAFFD2")
    /// 랭킹 리스트에서 내 줄 강조색
    static let leagueMyRow = Color(hex: "#F8FFBA")
}

struct LeagueView: View {
    let store: StoreOf<LeagueFeature>

    var body: some View {
        VStack(spacing: 0) {
            LeagueNavigationBar(
                onBackTapped: { store.send(.backTapped) },
                onShareTapped: { store.send(.shareTapped) },
                onInfoTapped: { store.send(.infoTapped) }
            )
            content
        }
        .background(
            LinearGradient(colors: [.leagueBackgroundTop, .white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .overlay {
            if let result = store.weekResult {
                LeagueModalContainer(onDismiss: { store.send(.weekResultDismissed) }) {
                    LeagueWeekResultView(result: result) {
                        store.send(.weekResultShareTapped)
                    }
                }
            } else if store.isInfoPresented {
                LeagueModalContainer(onDismiss: { store.send(.infoDismissed) }) {
                    LeagueInfoView()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.weekResult)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.isInfoPresented)
        .sheet(
            isPresented: Binding(
                get: { store.shareSheet != nil },
                set: { if !$0 { store.send(.shareSheetClosed) } }
            ),
            onDismiss: { store.send(.shareSheetDismissed) }
        ) {
            LeagueShareSheet { channel in
                store.send(.shareChannelSelected(channel))
            }
        }
        .navigationBarHidden(true)
        .trackScreen(.league)
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if let league = store.league {
            ScrollView {
                VStack(spacing: 0) {
                    LeagueHeaderView()
                        .padding(.top, 24)
                    LeaguePodiumView(rankers: store.podium, isParticipating: league.me.rank != nil)
                        .padding(.top, 28)
                    LazyVStack(spacing: 0) {
                        // 동점이면 순위가 같고 닉네임도 마스킹되어 겹칠 수 있어 위치로 구분
                        ForEach(Array(store.restRankers.enumerated()), id: \.offset) { _, ranker in
                            LeagueRankerRow(ranker: ranker)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    LeagueCountdownBar(remainingTimeText: store.remainingTimeText)
                    LeagueMyRankBar(me: league.me) {
                        store.send(.rankUpTapped)
                    }
                }
            }
        } else if let errorMessage = store.errorMessage {
            InlineErrorView(message: errorMessage) {
                store.send(.retryTapped)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Modal

/// 딤 + 가운데 카드 (딤 영역을 탭하면 닫힘) — 결과 모달 / 리그 안내 공통
private struct LeagueModalContainer<Content: View>: View {
    let onDismiss: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            content
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
                .padding(.horizontal, 40)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
}

private struct LeagueWeekResultView: View {
    let result: LeagueWeekResult
    let onShareTapped: () -> Void

    private enum Kind {
        case first
        case podium(rank: Int)
        case outOfRank

        init(rank: Int?) {
            switch rank {
            case 1: self = .first
            case let rank? where rank <= 3: self = .podium(rank: rank)
            default: self = .outOfRank
            }
        }

        /// 순위권(1~3위)일 때만 "n위" 표시
        var displayRank: Int? {
            switch self {
            case .first: 1
            case let .podium(rank): rank
            case .outOfRank: nil
            }
        }
    }

    private var kind: Kind { Kind(rank: result.rank) }

    var body: some View {
        VStack(spacing: 0) {
            Text("\(result.weekLabel ?? "지난주") 리그 결과")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            image
                .frame(height: 100)
                .padding(.top, 28)

            if let rank = kind.displayRank {
                Text("\(rank)위")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 20)
            }

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray900)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 12)

            Button(action: onShareTapped) {
                Text("공유하기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray500)
                    .padding(.vertical, 6)
            }
            .padding(.top, 8)
        }
    }

    private var image: some View {
        Group {
            switch kind {
            case .first:
                Image("league_trophy_first")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 179, height: 100)
            case .podium:
                Image("league_trophy_podium")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 179, height: 100)
            case .outOfRank:
                Image("league_character_melted")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 143, height: 82)
            }
        }
    }

    private var message: String {
        switch kind {
        case .first:
            "이번주 간식왕은 바로 너!🍿👑\n누구보다 열심히 틈틈이 채웠네요."
        case .podium:
            "이번 주도 틈틈이 잘 먹었어요!🍱\n다음주엔 한입만 더하면 1위를 노릴지도?"
        case .outOfRank:
            "이번주 순위권엔 진입하지 못했어요.😅\n월요일, 다시 1등을 향해 화이팅!"
        }
    }
}

/// 리그 안내 (i 버튼)
private struct LeagueInfoView: View {
    // TODO: 안내 문구 확정되면 교체 (현재는 정해진 리그 규칙으로 만든 초안)
    private let rules = [
        "퀴즈를 풀면 스낵을 모을 수 있어요. 매주 최대 77개까지 모을 수 있어요.",
        "이번 주에 모은 스낵 개수로 순위가 정해져요.",
        "스낵 개수가 같으면 스트릭이 긴 순, 먼저 가입한 순으로 순위가 정해져요.",
        "리그는 매주 일요일 자정에 초기화돼요."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("주간 리그 안내")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rules, id: \.self) { rule in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(rule)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.gray900)
            .padding(.top, 20)
        }
    }
}

// MARK: - Share Sheet

/// 공유 채널 선택 바텀시트
private struct LeagueShareSheet: View {
    let onSelect: (ShareChannel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("공유하기")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            row(title: "카카오톡으로 공유하기", systemImage: "message.fill", iconColor: Color(hex: "#3A1D1D"), iconBackground: Color(hex: "#FEE500")) {
                onSelect(.kakao)
            }
            row(title: "다른 앱으로 공유하기", systemImage: "square.and.arrow.up", iconColor: .gray800, iconBackground: .gray100) {
                onSelect(.system)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }

    private func row(
        title: String,
        systemImage: String,
        iconColor: Color,
        iconBackground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(iconBackground))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray900)
                Spacer()
            }
            .frame(height: 56)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Navigation Bar

private struct LeagueNavigationBar: View {
    let onBackTapped: () -> Void
    let onShareTapped: () -> Void
    let onInfoTapped: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBackTapped) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            Spacer()
            Button(action: onShareTapped) {
                Image("icon_share")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            Button(action: onInfoTapped) {
                Image("icon_info")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }
}

// MARK: - Header

private struct LeagueHeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("주간 리그 OPEN!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.gray900)

            VStack(spacing: 2) {
                Text("다른 유저와 내 기록을 비교해요")
                Text("매주 \(Text("최대 77개").foregroundColor(.blue500))의 스낵을 모을 수 있어요")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray800)
        }
    }
}

// MARK: - Podium

private struct LeaguePodiumView: View {
    let rankers: [LeagueRanker]
    /// 이번 주 리그 참여 여부 (1위 카드 Lottie 분기)
    let isParticipating: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            // 시상대 순서: 2위 - 1위 - 3위
            sideCard(at: 1, crownImage: "icon_crown_second")
            LeagueFirstPlaceCard(
                ranker: rankers.first,
                animation: isParticipating ? .inProgress : .unfilled
            )
            sideCard(at: 2, crownImage: "icon_crown_third")
        }
    }

    @ViewBuilder
    private func sideCard(at index: Int, crownImage: String) -> some View {
        if rankers.indices.contains(index) {
            LeagueSideCard(ranker: rankers[index], crownImage: crownImage)
                // 1위 Lottie 카드 아래쪽 여백만큼 올려 바닥선을 맞춤
                .padding(.bottom, 2)
        } else {
            Color.clear.frame(width: LeagueSideCard.width)
        }
    }
}

/// 2위 / 3위 카드
private struct LeagueSideCard: View {
    static let width: CGFloat = 88

    let ranker: LeagueRanker
    let crownImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(crownImage)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            VStack(spacing: 4) {
                Text(LeagueNickname.shortMasked(ranker.name))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray900)
                LeagueSnackCountText(count: ranker.weeklySnackCount, numberSize: 20)
            }
            .frame(width: Self.width, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray200, lineWidth: 1)
            )
        }
    }
}

/// 1위 카드 (카드 배경 + 캐릭터 + 왕관이 Lottie에 포함되어 있어 텍스트만 카드 영역에 얹음)
private struct LeagueFirstPlaceCard: View {
    enum Animation {
        /// 이번 주 참여함 (스낵을 하나라도 모음)
        case inProgress
        /// 이번 주 미참여
        case unfilled

        var name: String {
            switch self {
            case .inProgress: "lottie_league_rank1_in_progress"
            case .unfilled: "lottie_league_rank1_unfilled"
            }
        }

        /// Lottie 원본 크기 (1pt = 1px로 그려야 카드 폭이 시안의 118과 맞음)
        var size: CGSize {
            switch self {
            case .inProgress: CGSize(width: 123, height: 153)
            case .unfilled: CGSize(width: 130, height: 161)
            }
        }

        /// Lottie 안 league_card 레이어 영역 (118.8 x 98.8)
        var cardFrame: CGRect {
            switch self {
            case .inProgress: CGRect(x: 2, y: 52, width: 119, height: 99)
            case .unfilled: CGRect(x: 2, y: 60, width: 119, height: 99)
            }
        }

        /// in_progress Lottie의 카드에는 테두리가 없어 흰 배경에서 묻히므로 2·3위 카드와 같은 테두리를 덧그림
        var needsCardBorder: Bool { self == .inProgress }
    }

    let ranker: LeagueRanker?
    let animation: Animation

    var body: some View {
        LottieView(animation: .named(animation.name))
            .playing(loopMode: .loop)
            .frame(width: animation.size.width, height: animation.size.height)
            .background(alignment: .topLeading) {
                if animation.needsCardBorder {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray200, lineWidth: 1)
                        )
                        .frame(width: animation.cardFrame.width, height: animation.cardFrame.height)
                        .offset(x: animation.cardFrame.minX, y: animation.cardFrame.minY)
                }
            }
            .overlay(alignment: .topLeading) {
                if let ranker {
                    VStack(spacing: 6) {
                        Text(LeagueNickname.shortMasked(ranker.name))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray900)
                        LeagueSnackCountText(count: ranker.weeklySnackCount, numberSize: 24)
                    }
                    .frame(width: animation.cardFrame.width, height: animation.cardFrame.height)
                    .offset(x: animation.cardFrame.minX, y: animation.cardFrame.minY)
                }
            }
    }
}

// MARK: - Ranker Row

private struct LeagueRankerRow: View {
    let ranker: LeagueRanker

    var body: some View {
        HStack(spacing: 0) {
            Text("\(ranker.rank)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray600)
                .frame(width: 28, alignment: .leading)
            Text(LeagueNickname.masked(ranker.name))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray900)
            Spacer()
            LeagueSnackCountText(count: ranker.weeklySnackCount, numberSize: 20)
        }
        .padding(.horizontal, 24)
        .frame(height: 50)
        .background(ranker.isMe ? Color.leagueMyRow : Color.clear)
    }
}

/// "12스낵" (숫자만 파란색으로 크게)
private struct LeagueSnackCountText: View {
    let count: Int
    let numberSize: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(count)")
                .font(.system(size: numberSize, weight: .semibold))
                .foregroundColor(.blue500)
            Text("스낵")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray700)
        }
    }
}

// MARK: - Bottom

private struct LeagueCountdownBar: View {
    let remainingTimeText: String

    var body: some View {
        HStack(spacing: 12) {
            Text("리그 리셋까지")
                .font(.system(size: 13, weight: .medium))
            Text(remainingTimeText)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                .fill(Color.black)
        )
    }
}

private struct LeagueMyRankBar: View {
    let me: LeagueMyRank
    let onRankUpTapped: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let rank = me.rank {
                Text("\(rank)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray600)
                VStack(alignment: .leading, spacing: 4) {
                    Text(LeagueNickname.masked(me.name))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray900)
                    Text("오늘 \(blueNumber(me.todaySnackCount))스낵   총 \(blueNumber(me.weeklySnackCount))스낵")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray700)
                }
            } else {
                // TODO: 미참여 상태 시안 받으면 교체
                Text("이번 주 첫 스낵을 모아보세요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray700)
            }

            Spacer()

            Button(action: onRankUpTapped) {
                Text("순위 올리기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 48)
                    .background(Capsule().fill(Color.blue500))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }

    private func blueNumber(_ value: Int) -> Text {
        Text("\(value)").foregroundColor(.blue500)
    }
}

#Preview {
    NavigationStack {
        LeagueView(
            store: Store(initialState: LeagueFeature.State()) {
                LeagueFeature()
            }
        )
    }
}
