//
//  LeagueResponse.swift
//  TeumTeumEat
//

import Foundation

// TODO: API 스펙 확정 후 필드명 / 타입 맞추기 (현재는 mock 기준으로 가정한 모델)

/// 주간 리그 (전체 유저 단일 랭킹, 매주 일요일 자정 마감)
struct LeagueResponse: Decodable, Equatable {
    /// 이번 주 리그 진행 중 여부 (false면 랭킹 보드만 표시)
    let isActive: Bool
    /// 이번 주 리그 마감 시각 (ISO 8601, 타임존 포함)
    let weekEndAt: String
    /// 내 순위 (이번 주 아직 참여하지 않았으면 nil)
    let myRank: LeagueMyRank?
    /// 랭킹 보드 (서버에서 순위 계산 후 정렬해서 내려줌, 동점이면 같은 순위)
    let rankers: [LeagueRanker]
    /// 지난주 리그 결과 (새 주 첫 진입 시 결과 모달로 한 번 표시)
    var lastWeekResult: LeagueWeekResult? = nil
}

struct LeagueWeekResult: Decodable, Equatable {
    /// 주차 시작일 ("2026-09-28") — 이미 본 결과인지 구분하는 키
    let weekStartDate: String
    /// 제목 "9월 4주 리그 결과"용
    let month: Int
    let weekOfMonth: Int
    /// 지난주 최종 순위 (참여하지 않았으면 nil → 모달 표시 안 함)
    let rank: Int?
}

struct LeagueRanker: Decodable, Equatable, Identifiable {
    var id: Int { userId }
    let rank: Int
    let userId: Int
    /// 닉네임 (화면에는 LeagueNickname으로 마스킹해서 표시)
    let nickname: String
    /// 이번 주 모은 스낵 개수 (랭크 기준)
    let snackCount: Int
}

struct LeagueMyRank: Decodable, Equatable {
    let rank: Int
    let userId: Int
    let nickname: String
    /// 오늘 모은 스낵 개수
    let todaySnackCount: Int
    /// 이번 주 모은 스낵 개수
    let snackCount: Int
}

// MARK: - 닉네임 마스킹

// TODO: 서버가 마스킹해서 내려주기로 하면 정리 (이미 마스킹된 값이 와도 같은 결과가 나옴)
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
    static let mock: LeagueResponse = {
        let rankers: [(rank: Int, nickname: String, snackCount: Int)] = [
            (1, "틈틈잇", 12), (2, "김가나다민", 10), (3, "이수재", 9),
            (4, "김하영", 8), (5, "임재현", 7), (5, "강민수", 7),
            (7, "이준", 6), (8, "이서민", 5), (9, "김지주", 4),
            (10, "박서연", 4), (11, "최지호", 3), (12, "정다아", 2),
            (13, "윤", 2), (14, "한지우", 1), (15, "오아름림", 1)
        ]
        return LeagueResponse(
            isActive: true,
            weekEndAt: "2026-10-12T00:00:00+09:00",
            myRank: LeagueMyRank(rank: 8, userId: 8, nickname: "이서민", todaySnackCount: 1, snackCount: 5),
            rankers: rankers.enumerated().map { index, ranker in
                LeagueRanker(rank: ranker.rank, userId: index + 1, nickname: ranker.nickname, snackCount: ranker.snackCount)
            }
        )
    }()

    static let mockInactive = LeagueResponse(
        isActive: false,
        weekEndAt: mock.weekEndAt,
        myRank: nil,
        rankers: mock.rankers
    )
}

extension LeagueWeekResult {
    static let mock = LeagueWeekResult(
        weekStartDate: "2026-09-28",
        month: 9,
        weekOfMonth: 5,
        rank: 2
    )
}

// MARK: - 공유 문구

extension ShareContent {
    /// 지난주 리그 결과 공유 (순위권이면 순위를 함께 보여줌)
    static func leagueResult(_ result: LeagueWeekResult) -> ShareContent {
        guard let rank = result.rank, rank <= 3 else { return .invite }
        return ShareContent(
            text: "틈틈잇 \(result.month)월 \(result.weekOfMonth)주 리그에서 \(rank)위를 했어요! 같이 도전해 보세요.",
            url: appStoreURL
        )
    }
}
