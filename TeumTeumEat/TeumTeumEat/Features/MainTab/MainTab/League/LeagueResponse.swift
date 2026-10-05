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
    /// 이번 주 리그 마감 시각 (ISO 8601)
    let weekEndAt: String
    /// 내 순위 (이번 주 아직 참여하지 않았으면 nil)
    let myRank: LeagueRanker?
    /// 랭킹 보드 (서버에서 순위 계산 후 정렬해서 내려줌)
    let rankers: [LeagueRanker]
}

struct LeagueRanker: Decodable, Equatable, Identifiable {
    var id: Int { userId }
    let rank: Int
    let userId: Int
    let nickname: String
    /// 이번 주 풀이 개수 (랭크 기준)
    let solvedCount: Int
    let profileImageUrl: String?
}

// MARK: - Mock

extension LeagueResponse {
    static let mock: LeagueResponse = {
        let nicknames = [
            "틈틈이", "퀴즈왕", "오늘도한입", "출근길공부", "점심시간러",
            "꾸준함", "하루한문제", "지식냠냠", "토익가자", "새벽공부",
            "열공중", "한입더", "느리지만꾸준히", "공부하는곰", "퇴근후",
            "주말전사", "도전자", "책벌레", "작심삼일탈출", "만점가자"
        ]
        let rankers = nicknames.enumerated().map { index, nickname in
            LeagueRanker(
                rank: index + 1,
                userId: index + 1,
                nickname: nickname,
                solvedCount: 120 - index * 5,
                profileImageUrl: nil
            )
        }
        return LeagueResponse(
            isActive: true,
            weekEndAt: "2026-10-11T23:59:59",
            myRank: rankers[11],
            rankers: rankers
        )
    }()

    static let mockInactive = LeagueResponse(
        isActive: false,
        weekEndAt: mock.weekEndAt,
        myRank: nil,
        rankers: mock.rankers
    )
}
