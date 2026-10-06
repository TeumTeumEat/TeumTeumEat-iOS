//
//  LeagueFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture

/// 주간 리그 랭킹 화면 (Home / History에서 push로 진입)
@Reducer
struct LeagueFeature {
    @ObservableState
    struct State: Equatable {
        var league: LeagueResponse?
        var isLoading: Bool = false
        var errorMessage: String?
        /// 리그 리셋까지 남은 시간 (초)
        var remainingSeconds: Int = 0

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
        case leagueLoaded(Result<LeagueResponse, Error>)
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
                // TODO: 공유 이슈에서 연결
                return .none

            case .infoTapped:
                // TODO: 리그 규칙 안내 시안 받으면 연결
                return .none

            case .rankUpTapped:
                analyticsClient.log(.leagueRankUpClick)
                return .send(.delegate(.rankUpRequested))

            case .leagueLoaded(.success(let league)):
                state.isLoading = false
                state.league = league
                Log.league.debug("League loaded: active=\(league.isActive), rankers=\(league.rankers.count)")

                guard let weekEnd = DateFormatters.iso8601.date(from: league.weekEndAt) else {
                    Log.league.error("Invalid weekEndAt: \(league.weekEndAt)")
                    state.remainingSeconds = 0
                    return .cancel(id: CancelID.timer)
                }
                state.remainingSeconds = remainingSeconds(until: weekEnd)
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

            case .timerTicked:
                // 1초씩 빼지 않고 매번 마감 시각 기준으로 다시 계산 (백그라운드 다녀와도 정확하도록)
                guard let weekEndAt = state.league?.weekEndAt,
                      let weekEnd = DateFormatters.iso8601.date(from: weekEndAt) else { return .none }
                state.remainingSeconds = remainingSeconds(until: weekEnd)
                guard state.remainingSeconds == 0 else { return .none }
                // 리셋 시각이 지나면 새 주차 리그를 다시 조회
                return .merge(
                    .cancel(id: CancelID.timer),
                    fetchLeague(&state)
                )

            case .delegate:
                return .none
            }
        }
    }

    private func remainingSeconds(until date: Date) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    private func fetchLeague(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            await send(.leagueLoaded(Result { try await leagueClient.fetchLeague() }))
        }
    }
}

// MARK: - View

// TODO: 시안 수치(hex) 받으면 교체 — 현재는 시안 이미지 기준 근사값
private extension Color {
    static let leagueBackgroundTop = Color(hex: "#F3F8CC")
    static let leagueMyRow = Color(hex: "#F4F9C4")
    static let crownGold = Color(hex: "#FFC93C")
    static let crownSilver = Color(hex: "#C9CCD1")
    static let crownBronze = Color(hex: "#E8A23A")
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
            LinearGradient(colors: [.leagueBackgroundTop, .white], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
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
                    LeaguePodiumView(rankers: store.podium)
                        .padding(.top, 28)
                    LazyVStack(spacing: 0) {
                        ForEach(store.restRankers) { ranker in
                            LeagueRankerRow(ranker: ranker, isMe: ranker.userId == league.myRank?.userId)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    LeagueCountdownBar(remainingTimeText: store.remainingTimeText)
                    LeagueMyRankBar(myRank: league.myRank) {
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
            // TODO: 시안 아이콘 에셋 받으면 교체
            Button(action: onShareTapped) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            Button(action: onInfoTapped) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
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

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            // 시상대 순서: 2위 - 1위 - 3위
            podiumCard(at: 1, crownColor: .crownSilver, isFirst: false)
            podiumCard(at: 0, crownColor: .crownGold, isFirst: true)
            podiumCard(at: 2, crownColor: .crownBronze, isFirst: false)
        }
    }

    @ViewBuilder
    private func podiumCard(at index: Int, crownColor: Color, isFirst: Bool) -> some View {
        if rankers.indices.contains(index) {
            LeaguePodiumCard(ranker: rankers[index], crownColor: crownColor, isFirst: isFirst)
        } else {
            Color.clear.frame(width: LeaguePodiumCard.width(isFirst: isFirst))
        }
    }
}

private struct LeaguePodiumCard: View {
    let ranker: LeagueRanker
    let crownColor: Color
    let isFirst: Bool

    static func width(isFirst: Bool) -> CGFloat { isFirst ? 118 : 88 }

    var body: some View {
        VStack(spacing: 4) {
            // TODO: 왕관 / 1위 캐릭터 에셋 받으면 교체
            LeagueCrown(rank: ranker.rank, color: crownColor, size: isFirst ? 36 : 28)

            VStack(spacing: isFirst ? 6 : 4) {
                Text(LeagueNickname.shortMasked(ranker.nickname))
                    .font(.system(size: isFirst ? 20 : 16, weight: .semibold))
                    .foregroundColor(.gray900)
                LeagueSnackCountText(count: ranker.snackCount, numberSize: isFirst ? 24 : 20)
            }
            .frame(width: Self.width(isFirst: isFirst), height: isFirst ? 96 : 72)
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

private struct LeagueCrown: View {
    let rank: Int
    let color: Color
    let size: CGFloat

    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: size))
            .foregroundColor(color)
            .overlay(alignment: .center) {
                Text("\(rank)")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: size * 0.1)
            }
    }
}

// MARK: - Ranker Row

private struct LeagueRankerRow: View {
    let ranker: LeagueRanker
    let isMe: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text("\(ranker.rank)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray600)
                .frame(width: 28, alignment: .leading)
            Text(LeagueNickname.masked(ranker.nickname))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray900)
            Spacer()
            LeagueSnackCountText(count: ranker.snackCount, numberSize: 20)
        }
        .padding(.horizontal, 24)
        .frame(height: 50)
        .background(isMe ? Color.leagueMyRow : Color.clear)
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
    let myRank: LeagueMyRank?
    let onRankUpTapped: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let myRank {
                Text("\(myRank.rank)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray600)
                VStack(alignment: .leading, spacing: 4) {
                    Text(LeagueNickname.masked(myRank.nickname))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray900)
                    Text("오늘 \(blueNumber(myRank.todaySnackCount))스낵   총 \(blueNumber(myRank.snackCount))스낵")
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
