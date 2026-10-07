//
//  NoticeClient.swift
//  TeumTeumEat
//

import ComposableArchitecture

/// 공지사항 API
@DependencyClient
struct NoticeClient {
    /// page는 0부터 시작
    var fetchNotices: @Sendable (_ page: Int, _ size: Int) async throws -> NoticeSliceResponse
}

extension NoticeClient: DependencyKey {
    static let liveValue: NoticeClient = {
        let api = APIClient.liveValue
        return NoticeClient(
            fetchNotices: { try await api.fetchNotices(page: $0, size: $1) }
        )
    }()

    static let previewValue = NoticeClient(
        fetchNotices: { page, size in
            NoticeSliceResponse(notices: page == 0 ? Notice.mocks : [], page: page, size: size, hasNext: false)
        }
    )

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = NoticeClient()
}

extension DependencyValues {
    var noticeClient: NoticeClient {
        get { self[NoticeClient.self] }
        set { self[NoticeClient.self] = newValue }
    }
}
