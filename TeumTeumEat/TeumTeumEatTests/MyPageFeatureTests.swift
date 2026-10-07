//
//  MyPageFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import Testing
@testable import TeumTeumEat

@MainActor
struct MyPageFeatureTests {
    @Test("공지사항을 누르면 공지 목록을 띄운다")
    func viewNoticesTapped_presentsNoticeList() async {
        let store = TestStore(initialState: MyPageFeature.State()) {
            MyPageFeature()
        }

        await store.send(.viewNoticesTapped) {
            $0.destination = .noticeList(NoticeListFeature.State())
        }
    }

    @Test("회원탈퇴 API가 실패하면 로딩을 끝내고 에러 알럿을 띄운다")
    func withdrawalFailure_showsErrorAlert() async {
        var state = MyPageFeature.State()
        state.showWithdrawalAlert = true
        let store = TestStore(initialState: state) {
            MyPageFeature()
        } withDependencies: {
            $0.userClient.withdrawUser = {
                throw APIError.networkError(URLError(.notConnectedToInternet))
            }
        }

        await store.send(.confirmWithdrawal) {
            $0.showWithdrawalAlert = false
            $0.isWithdrawing = true
        }
        await store.receive(\.withdrawalResponse) {
            $0.isWithdrawing = false
            $0.withdrawalErrorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        }
    }

    @Test("에러 알럿에서 다시 시도해 성공하면 탈퇴 처리를 상위로 전달한다")
    func withdrawalRetry_succeeds() async {
        var state = MyPageFeature.State()
        state.withdrawalErrorMessage = "인터넷 연결을 확인하고 다시 시도해 주세요."
        let store = TestStore(initialState: state) {
            MyPageFeature()
        } withDependencies: {
            $0.userClient.withdrawUser = {}
        }

        await store.send(.withdrawalRetryTapped) {
            $0.withdrawalErrorMessage = nil
        }
        await store.receive(\.confirmWithdrawal) {
            $0.isWithdrawing = true
        }
        await store.receive(\.withdrawalResponse) {
            $0.isWithdrawing = false
        }
        await store.receive(\.delegate)
    }

    @Test("탈퇴 요청 중에는 다시 눌러도 API를 중복 호출하지 않는다")
    func withdrawalInFlight_ignoresDuplicateTap() async {
        var state = MyPageFeature.State()
        state.isWithdrawing = true
        let store = TestStore(initialState: state) {
            MyPageFeature()
        }
        // withdrawUser를 override하지 않았으므로 호출되면 테스트 실패

        await store.send(.confirmWithdrawal)
    }
}
