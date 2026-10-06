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
}

struct LeagueRanker: Decodable, Equatable, Identifiable {
    var id: Int { userId }
    let rank: Int
    let userId: Int
    /// 마스킹된 닉네임 (예: 김*민)
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

// MARK: - Mock

extension LeagueResponse {
    static let mock: LeagueResponse = {
        let rankers: [(rank: Int, nickname: String, snackCount: Int)] = [
            (1, "틈*잇", 12), (2, "김*민", 10), (3, "이*재", 9),
            (4, "김*영", 8), (5, "임*현", 7), (5, "강*수", 7),
            (7, "이*", 6), (8, "이*민", 5), (9, "김*주", 4),
            (10, "박*연", 4), (11, "최*호", 3), (12, "정*아", 2),
            (13, "윤*", 2), (14, "한*우", 1), (15, "오*림", 1)
        ]
        return LeagueResponse(
            isActive: true,
            weekEndAt: "2026-10-12T00:00:00+09:00",
            myRank: LeagueMyRank(rank: 8, userId: 8, nickname: "이*민", todaySnackCount: 1, snackCount: 5),
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
