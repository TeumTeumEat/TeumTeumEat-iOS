//
//  NoticeResponse.swift
//  TeumTeumEat
//

import Foundation

/// GET /api/v1/notices — 공지 목록 (최신순, 무한 스크롤)
struct NoticeSliceResponse: Decodable, Equatable {
    let notices: [Notice]
    /// 현재 페이지 (0부터 시작)
    let page: Int
    let size: Int
    let hasNext: Bool
}

struct Notice: Decodable, Equatable, Identifiable {
    var id: Int { noticeId }
    let noticeId: Int
    let title: String
    /// 본문 (목록 응답에 포함되어 상세 조회 API 없이 표시)
    let content: String
    /// 작성일시 (KST, 타임존 없음 "2026-10-01T12:00:00")
    let createdDate: String

    /// "3월 12일"
    var dateText: String {
        guard let date = DateFormatters.yearMonthDay.date(from: String(createdDate.prefix(10))) else { return "" }
        return DateFormatters.koreanMonthDay.string(from: date)
    }
}

// MARK: - Mock

extension Notice {
    static let mocks: [Notice] = [
        Notice(noticeId: 3, title: "틈틈잇 공지사항입니다!", content: "안녕하세요. 틈틈잇입니다.\n새로운 소식을 전해드려요.", createdDate: "2026-03-12T12:00:00"),
        Notice(noticeId: 2, title: "리그 관련 오픈 이벤트", content: "주간 리그가 오픈했어요.", createdDate: "2026-02-22T09:30:00"),
        Notice(noticeId: 1, title: "틈틈잇 공지사항입니다!", content: "틈틈잇을 이용해 주셔서 감사합니다.", createdDate: "2026-01-11T18:00:00")
    ]
}
