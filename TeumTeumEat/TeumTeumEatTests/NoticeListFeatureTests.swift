//
//  NoticeListFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct NoticeListFeatureTests {
    private static func slice(_ notices: [Notice], page: Int, hasNext: Bool) -> NoticeSliceResponse {
        NoticeSliceResponse(notices: notices, page: page, size: NoticeListFeature.State.pageSize, hasNext: hasNext)
    }

    @Test("첫 진입 시 첫 페이지를 조회한다")
    func onAppear_loadsFirstPage() async {
        let requested = LockIsolated<[Int]>([])
        let store = TestStore(initialState: NoticeListFeature.State()) {
            NoticeListFeature()
        } withDependencies: {
            $0.noticeClient.fetchNotices = { page, _ in
                requested.withValue { $0.append(page) }
                return Self.slice(Notice.mocks, page: 0, hasNext: true)
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.noticesLoaded.success) {
            $0.isLoading = false
            $0.page = 0
            $0.hasNext = true
            $0.notices = Notice.mocks
        }
        #expect(requested.value == [0])

        // 상세에서 돌아와도 다시 조회하지 않음
        await store.send(.onAppear)
    }

    @Test("목록 끝에 닿으면 다음 페이지를 이어 붙이고, 마지막 페이지 이후로는 조회하지 않는다")
    func lastRowAppeared_appendsNextPage_untilNoMore() async {
        let nextPage = [Notice(noticeId: 0, title: "이전 공지", content: "내용", createdDate: "2025-12-31T10:00:00")]
        var state = NoticeListFeature.State()
        state.notices = Notice.mocks
        state.page = 0
        let store = TestStore(initialState: state) {
            NoticeListFeature()
        } withDependencies: {
            $0.noticeClient.fetchNotices = { page, _ in Self.slice(nextPage, page: page, hasNext: false) }
        }

        await store.send(.lastRowAppeared) {
            $0.isLoading = true
        }
        await store.receive(\.noticesLoaded.success) {
            $0.isLoading = false
            $0.page = 1
            $0.hasNext = false
            $0.notices = Notice.mocks + nextPage
        }

        await store.send(.lastRowAppeared)
    }

    @Test("다음 페이지 조회에 실패하면 목록은 유지하고, 스크롤로는 다시 조회하지 않고 다시 시도로 같은 페이지를 조회한다")
    func loadMoreFailure_keepsList_retryRequestsSamePage() async {
        let shouldFail = LockIsolated(true)
        let requested = LockIsolated<[Int]>([])
        var state = NoticeListFeature.State()
        state.notices = Notice.mocks
        state.page = 0
        let store = TestStore(initialState: state) {
            NoticeListFeature()
        } withDependencies: {
            $0.noticeClient.fetchNotices = { page, _ in
                requested.withValue { $0.append(page) }
                if shouldFail.value { throw APIError.networkError(URLError(.notConnectedToInternet)) }
                return Self.slice([], page: page, hasNext: false)
            }
        }

        await store.send(.lastRowAppeared) {
            $0.isLoading = true
        }
        await store.receive(\.noticesLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }
        await store.send(.lastRowAppeared)

        shouldFail.setValue(false)
        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.noticesLoaded.success) {
            $0.isLoading = false
            $0.page = 1
            $0.hasNext = false
        }
        #expect(requested.value == [1, 1])
    }

    @Test("첫 페이지 조회에 실패한 뒤 다시 시도하면 첫 페이지를 조회한다")
    func firstPageFailure_retryRequestsFirstPage() async {
        let shouldFail = LockIsolated(true)
        let store = TestStore(initialState: NoticeListFeature.State()) {
            NoticeListFeature()
        } withDependencies: {
            $0.noticeClient.fetchNotices = { page, _ in
                if shouldFail.value { throw APIError.networkError(URLError(.notConnectedToInternet)) }
                #expect(page == 0)
                return Self.slice([], page: 0, hasNext: false)
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.noticesLoaded.failure) {
            $0.isLoading = false
            $0.errorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }

        shouldFail.setValue(false)
        await store.send(.retryTapped) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.noticesLoaded.success) {
            $0.isLoading = false
            $0.page = 0
            $0.hasNext = false
        }
    }

    @Test("공지를 누르면 상세 화면을 띄운다")
    func noticeTapped_presentsDetail() async {
        var state = NoticeListFeature.State()
        state.notices = Notice.mocks
        state.page = 0
        let store = TestStore(initialState: state) {
            NoticeListFeature()
        }

        await store.send(.noticeTapped(Notice.mocks[1])) {
            $0.detail = NoticeDetailFeature.State(notice: Notice.mocks[1])
        }
    }

    @Test("작성일은 월 / 일로 표시한다", arguments: [
        ("2026-03-12T12:00:00", "3월 12일"),
        ("2026-10-01T00:00:00.123456", "10월 1일"),
        ("잘못된 날짜", "")
    ])
    func dateText(createdDate: String, expected: String) {
        let notice = Notice(noticeId: 1, title: "제목", content: "내용", createdDate: createdDate)
        #expect(notice.dateText == expected)
    }
}
