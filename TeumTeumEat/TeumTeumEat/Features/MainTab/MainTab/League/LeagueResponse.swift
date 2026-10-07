//
//  LeagueResponse.swift
//  TeumTeumEat
//

import Foundation

/// GET /api/v1/league — 이번 주 리그 랭킹 (월 00:00 ~ 다음 주 월 00:00, KST)
struct LeagueResponse: Decodable, Equatable {
    /// 이번 주 시작일 (월요일, "2026-10-05")
    let weekStartDate: String
    /// 리그 리셋 시각 (KST, 타임존 없음 "2026-10-12T00:00:00") — 카운트다운은 remainingSeconds 기준
    let resetAt: String
    /// 리셋까지 남은 시간 (초)
    let remainingSeconds: Int
    /// 상위 랭커 (최대 10명, 순위 오름차순, 동점이면 같은 순위)
    let rankers: [LeagueRanker]
    /// 내 순위 및 스낵 현황
    let me: LeagueMyRank
}

struct LeagueRanker: Decodable, Equatable {
    let rank: Int
    /// 마스킹된 닉네임
    let name: String
    /// 이번 주 스낵 수 (랭크 기준)
    let weeklySnackCount: Int
    let isMe: Bool
}

/// GET /api/v1/league/me 응답과 같은 형태
struct LeagueMyRank: Decodable, Equatable {
    /// 내 순위 (이번 주 스낵이 0개면 nil = 리그 미참여)
    let rank: Int?
    /// 마스킹된 닉네임
    let name: String
    let weeklySnackCount: Int
    let todaySnackCount: Int
}

/// GET /api/v1/league/results/latest — 지난주 확정된 내 순위 (결과 모달용)
struct LeagueWeekResult: Decodable, Equatable {
    /// 결과 대상 주의 시작일 (월요일, "2026-09-28") — 이미 본 결과인지 구분하는 키
    let weekStartDate: String
    /// 최종 순위 (해당 주 스낵이 0개면 nil → 모달 표시 안 함)
    let rank: Int?
    let weeklySnackCount: Int

    /// "9월 4주" — 주 시작일(월요일)이 그 달의 몇 번째 월요일인지 기준
    var weekLabel: String? {
        guard let date = DateFormatters.yearMonthDay.date(from: weekStartDate) else { return nil }
        let components = Calendar(identifier: .gregorian).dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return nil }
        return "\(month)월 \((day - 1) / 7 + 1)주"
    }
}

// MARK: - 닉네임 마스킹

// 서버가 마스킹해서 내려줌 — 이미 마스킹된 값이 와도 같은 결과가 나와 시상대(가*마) 표시용으로 유지
enum LeagueNickname {
    /// 리스트 / 내 순위: 첫 글자와 마지막 글자만 남기고 가운데를 글자 수만큼 가림
    /// 가나다라마 → 가***마, 이서민 → 이*민, 이준 → 이*
    static func masked(_ nickname: String) -> String {
        mask(nickname, middleCount: max(0, nickname.count - 2))
    }

    /// 1~3위 시상대: 카드 폭이 좁아 가운데를 * 하나로 줄임
    /// 가나다라마 → 가*마, 이준 → 이*
    static func shortMasked(_ nickname: String) -> String {
        mask(nickname, middleCount: 1)
    }

    private static func mask(_ nickname: String, middleCount: Int) -> String {
        guard let first = nickname.first else { return nickname }
        switch nickname.count {
        case 1:
            return nickname
        case 2:
            return "\(first)*"
        default:
            return "\(first)\(String(repeating: "*", count: middleCount))\(nickname.last!)"
        }
    }
}

// MARK: - Mock

extension LeagueResponse {
    /// 이번 주 참여 중 (나는 8위)
    static let mock: LeagueResponse = {
        let rankers: [(rank: Int, name: String, weeklySnackCount: Int)] = [
            (1, "틈*잇", 12), (2, "김***민", 10), (3, "이*재", 9),
            (4, "김*영", 8), (5, "임*현", 7), (5, "강*수", 7),
            (7, "이*", 6), (8, "이*민", 5), (9, "김*주", 4),
            (10, "박*연", 4)
        ]
        return LeagueResponse(
            weekStartDate: "2026-10-05",
            resetAt: "2026-10-12T00:00:00",
            remainingSeconds: 86400,
            rankers: rankers.map {
                LeagueRanker(rank: $0.rank, name: $0.name, weeklySnackCount: $0.weeklySnackCount, isMe: $0.rank == 8)
            },
            me: LeagueMyRank(rank: 8, name: "이*민", weeklySnackCount: 5, todaySnackCount: 1)
        )
    }()

    /// 이번 주 미참여 (스낵 0개)
    static let mockNotParticipating = LeagueResponse(
        weekStartDate: mock.weekStartDate,
        resetAt: mock.resetAt,
        remainingSeconds: mock.remainingSeconds,
        rankers: mock.rankers.map {
            LeagueRanker(rank: $0.rank, name: $0.name, weeklySnackCount: $0.weeklySnackCount, isMe: false)
        },
        me: LeagueMyRank(rank: nil, name: "이*민", weeklySnackCount: 0, todaySnackCount: 0)
    )
}

extension LeagueWeekResult {
    static let mock = LeagueWeekResult(weekStartDate: "2026-09-28", rank: 2, weeklySnackCount: 10)
}

// MARK: - 공유 문구

extension ShareContent {
    /// 지난주 리그 결과 공유 (순위권이면 순위를 함께 보여줌)
    static func leagueResult(_ result: LeagueWeekResult) -> ShareContent {
        guard let rank = result.rank, rank <= 3, let weekLabel = result.weekLabel else { return .invite }
        return ShareContent(
            text: "틈틈잇 \(weekLabel) 리그에서 \(rank)위를 했어요! 같이 도전해 보세요.",
            url: appStoreURL
        )
    }
}
