//
//  AddSubjectFlowFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Testing
@testable import TeumTeumEat

@MainActor
struct AddSubjectFlowFeatureTests {
    @Test("난이도에서 뒤로가기 후 다시 들어오면 선택한 난이도와 프롬프트가 유지된다")
    func difficultyBack_keepsSelection() async {
        var state = AddSubjectFlowFeature.State(contentType: .category)
        var difficulty = DifficultySelectionFeature.State()
        difficulty.selectedDifficulty = .hard
        difficulty.customPrompt = "실무 위주로"
        state.step = .difficulty(difficulty)

        let store = TestStore(initialState: state) {
            AddSubjectFlowFeature()
        }

        await store.send(.step(.difficulty(.backTapped))) {
            $0.selectedDifficulty = "상"
            $0.customPrompt = "실무 위주로"
            $0.step = .category(CategorySelectionFeature.State())
        }

        let detail = CategoryResponse(categoryId: 1, name: "SwiftUI", path: "/IT/앱개발자/iOS")
        await store.send(.step(.category(.delegate(.completed(root: "IT", main: "앱개발자", sub: "iOS", detail: detail))))) {
            $0.selectedRootCategory = "IT"
            $0.selectedMainCategory = "앱개발자"
            $0.selectedSubCategory = "iOS"
            $0.selectedDetailCategory = detail
            $0.step = .difficulty(difficulty)  // 뒤로가기 전 선택 그대로 복원
        }
    }

    @Test("기간에서 뒤로가기 시 선택한 기간을 저장한다")
    func durationBack_keepsWeeks() async {
        var state = AddSubjectFlowFeature.State(contentType: .category)
        var duration = DurationSelectionFeature.State()
        duration.selectedWeeks = .three
        state.step = .duration(duration)

        let store = TestStore(initialState: state) {
            AddSubjectFlowFeature()
        }

        await store.send(.step(.duration(.backTapped))) {
            $0.selectedWeeks = 3
            $0.step = .difficulty(DifficultySelectionFeature.State())
        }
    }

    @Test("세부 카테고리까지 선택했다면 난이도에서 뒤로가기 시 세부 카테고리 단계로 복원된다")
    func difficultyBack_restoresCategoryStep() async {
        let detail = CategoryResponse(categoryId: 1, name: "SwiftUI", path: "/IT/앱개발자/iOS")
        var state = AddSubjectFlowFeature.State(contentType: .category)
        state.selectedRootCategory = "IT"
        state.selectedMainCategory = "앱개발자"
        state.selectedSubCategory = "iOS"
        state.selectedDetailCategory = detail
        state.step = .difficulty(DifficultySelectionFeature.State())

        let store = TestStore(initialState: state) {
            AddSubjectFlowFeature()
        }

        var expectedCategory = CategorySelectionFeature.State()
        expectedCategory.selectedRootCategory = "IT"
        expectedCategory.selectedMainCategory = "앱개발자"
        expectedCategory.selectedSubCategory = "iOS"
        expectedCategory.selectedDetailCategory = detail
        expectedCategory.currentStep = .detailCategory

        await store.send(.step(.difficulty(.backTapped))) {
            $0.step = .category(expectedCategory)
        }
    }

    @Test("첫 단계에서 뒤로가기 시 흐름 취소를 알린다 (카테고리 / 파일)")
    func firstStepBack_cancelsFlow() async {
        let categoryStore = TestStore(initialState: AddSubjectFlowFeature.State(contentType: .category)) {
            AddSubjectFlowFeature()
        }
        await categoryStore.send(.step(.category(.delegate(.backToContentSelection))))
        await categoryStore.receive(\.delegate.cancelled)

        let fileStore = TestStore(initialState: AddSubjectFlowFeature.State(contentType: .fileUpload)) {
            AddSubjectFlowFeature()
        }
        await fileStore.send(.step(.fileUpload(.backTapped)))
        await fileStore.receive(\.delegate.cancelled)
    }
}
