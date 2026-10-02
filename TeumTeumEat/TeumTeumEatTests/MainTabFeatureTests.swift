//
//  MainTabFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Testing
@testable import TeumTeumEat

@MainActor
struct MainTabFeatureTests {
    @Test("+ 메뉴에서 주제찾기 / 자료올리기를 고르면 해당 주제 추가 흐름을 띄운다")
    func registerMenuItem_presentsAddSubject() async {
        var state = MainTabFeature.State()
        state.isRegisterMenuExpanded = true
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.registerMenuItemTapped(.category)) {
            $0.isRegisterMenuExpanded = false
            $0.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
        }
        await store.send(.destination(.presented(.addSubject(.delegate(.cancelled))))) {
            $0.destination = nil
        }
        await store.send(.registerMenuItemTapped(.fileUpload)) {
            $0.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .fileUpload))
        }
    }

    @Test("주제 완료 상태에서 마이페이지를 스와이프로 닫으면 주제 완료 알럿을 다시 띄운다")
    func swipeDismissMyPage_whenGoalCompleted_showsAlert() async {
        var state = MainTabFeature.State()
        state.home.isGoalCompleted = true
        state.destination = .myPage(MyPageFeature.State())
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.destination(.dismiss)) {
            $0.home.showGoalCompletedAlert = true
            $0.destination = nil
        }
    }

    @Test("주제 완료 상태에서는 탭 전환과 + 메뉴가 동작하지 않는다")
    func goalCompleted_blocksTabAndMenu() async {
        var state = MainTabFeature.State()
        state.home.isGoalCompleted = true
        let store = TestStore(initialState: state) {
            MainTabFeature()
        }

        await store.send(.tabSelected(.quiz))
        await store.send(.toggleRegisterMenu)
        await store.send(.registerMenuItemTapped(.category))
    }
}
