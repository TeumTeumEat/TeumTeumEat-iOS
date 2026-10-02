//
//  AddSubjectFlowFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

/// 새 주제 추가 흐름 (카테고리 선택 / 파일 업로드 공통)
/// 첫 단계만 contentType에 따라 다르고, 난이도 → 기간 → 요약 → 로딩 → 완료는 동일
@Reducer
struct AddSubjectFlowFeature {
    @Reducer
    enum Step {
        case category(CategorySelectionFeature)
        case fileUpload(FileUploadFeature)
        case difficulty(DifficultySelectionFeature)
        case duration(DurationSelectionFeature)
        case summary(AddSubjectSummaryFeature)
        case loading(OnboardingLoadingFeature)
        case complete(AddSubjectCompleteFeature)
    }

    @ObservableState
    struct State: Equatable {
        let contentType: OnboardingData.ContentType
        var step: Step.State

        // 선택된 값들 (뒤로가기 시 이전 단계 화면을 이 값으로 다시 생성)
        var selectedRootCategory: String?
        var selectedMainCategory: String?
        var selectedSubCategory: String?
        var selectedDetailCategory: CategoryResponse?
        var uploadedFileURL: URL?
        var selectedDifficulty: String?
        var customPrompt: String = ""
        var selectedWeeks: Int = 0

        init(contentType: OnboardingData.ContentType) {
            self.contentType = contentType
            switch contentType {
            case .category:
                self.step = .category(CategorySelectionFeature.State())
            case .fileUpload:
                self.step = .fileUpload(FileUploadFeature.State())
            }
        }
    }

    enum Action {
        case step(Step.Action)
        case delegate(Delegate)

        enum Delegate {
            case completed
            case cancelled
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.step, action: \.step) {
            Step.body
        }

        Reduce { state, action in
            switch action {
            // MARK: - Category Selection
            case .step(.category(.delegate(.saveProgress(let root, let main, let sub, let detail)))):
                // 카테고리 진행 상황 저장 (뒤로가기 시)
                Log.register.debug("AddSubject - saveProgress: \(root ?? "nil") > \(main ?? "nil") > \(sub ?? "nil") > \(detail?.name ?? "nil")")
                saveCategory(&state, root: root, main: main, sub: sub, detail: detail)
                return .none

            case .step(.category(.delegate(.completed(let root, let main, let sub, let detail)))):
                saveCategory(&state, root: root, main: main, sub: sub, detail: detail)
                state.step = .difficulty(makeDifficultyState(state))
                return .none

            case .step(.category(.delegate(.backToContentSelection))):
                return .send(.delegate(.cancelled))

            // MARK: - File Upload
            case .step(.fileUpload(.backTapped)):
                return .send(.delegate(.cancelled))

            case .step(.fileUpload(.nextTapped)):
                if case let .fileUpload(fileUpload) = state.step, let fileURL = fileUpload.selectedFileURL {
                    state.uploadedFileURL = fileURL
                }
                state.step = .difficulty(makeDifficultyState(state))
                return .none

            // MARK: - Difficulty Selection
            case .step(.difficulty(.backTapped)):
                // 난이도에서 뒤로가기 → 첫 단계(카테고리 / 파일)로 복원
                state.step = makeFirstStepState(state)
                return .none

            case .step(.difficulty(.nextTapped)):
                if case let .difficulty(difficulty) = state.step {
                    if let selected = difficulty.selectedDifficulty {
                        state.selectedDifficulty = selected.rawValue
                    }
                    state.customPrompt = difficulty.customPrompt
                }
                state.step = .duration(makeDurationState(state))
                return .none

            // MARK: - Duration Selection
            case .step(.duration(.backTapped)):
                state.step = .difficulty(makeDifficultyState(state))
                return .none

            case .step(.duration(.nextTapped)):
                if case let .duration(duration) = state.step, let weeks = duration.selectedWeeks {
                    state.selectedWeeks = weeks.rawValue
                }
                state.step = .summary(makeSummaryState(state))
                return .none

            // MARK: - Summary
            case .step(.summary(.delegate(.back))):
                state.step = .duration(makeDurationState(state))
                return .none

            case .step(.summary(.delegate(.complete))):
                Log.register.debug("주제 추가 시작 (\(state.contentType))")
                Log.register.debug("카테고리: \(state.selectedRootCategory ?? "") > \(state.selectedMainCategory ?? "") > \(state.selectedSubCategory ?? "") > \(state.selectedDetailCategory?.name ?? "")")
                Log.register.debug("파일: \(state.uploadedFileURL?.lastPathComponent ?? "없음")")
                Log.register.debug("난이도: \(state.selectedDifficulty ?? ""), 프롬프트: \(state.customPrompt), 기간: \(state.selectedWeeks)주")

                state.step = .loading(OnboardingLoadingFeature.State(
                    onboardingData: makeOnboardingData(state),
                    isOnboarding: false,
                    isFileUpload: state.contentType == .fileUpload
                ))
                return .none

            // MARK: - Loading & Complete
            case .step(.loading(.loadingCompleted)):
                Log.register.debug("주제 추가 API 완료 (\(state.contentType))")
                state.step = .complete(AddSubjectCompleteFeature.State())
                return .none

            case .step(.complete(.delegate(.completed))):
                return .send(.delegate(.completed))

            case .step, .delegate:
                return .none
            }
        }
    }

    // MARK: - Helpers

    private func saveCategory(
        _ state: inout State,
        root: String?,
        main: String?,
        sub: String?,
        detail: CategoryResponse?
    ) {
        state.selectedRootCategory = root
        state.selectedMainCategory = main
        state.selectedSubCategory = sub
        state.selectedDetailCategory = detail
    }

    /// 첫 단계 화면 복원 (카테고리는 마지막으로 보던 단계까지, 파일은 선택한 파일 정보)
    private func makeFirstStepState(_ state: State) -> Step.State {
        switch state.contentType {
        case .category:
            var categoryState = CategorySelectionFeature.State()
            categoryState.selectedRootCategory = state.selectedRootCategory
            categoryState.selectedMainCategory = state.selectedMainCategory
            categoryState.selectedSubCategory = state.selectedSubCategory
            categoryState.selectedDetailCategory = state.selectedDetailCategory

            if state.selectedDetailCategory != nil {
                categoryState.currentStep = .detailCategory
            } else if state.selectedSubCategory != nil {
                categoryState.currentStep = .subCategory
            } else if state.selectedMainCategory != nil {
                categoryState.currentStep = .mainCategory
            } else if state.selectedRootCategory != nil {
                categoryState.currentStep = .rootCategory
            }
            return .category(categoryState)

        case .fileUpload:
            var fileUploadState = FileUploadFeature.State()
            if let url = state.uploadedFileURL {
                fileUploadState.selectedFileURL = url
                fileUploadState.selectedFileName = url.lastPathComponent
                if let fileSize = try? url.fileSize() {
                    fileUploadState.selectedFileSize = fileSize
                }
            }
            return .fileUpload(fileUploadState)
        }
    }

    private func makeDifficultyState(_ state: State) -> DifficultySelectionFeature.State {
        var difficultyState = DifficultySelectionFeature.State()
        if let difficulty = state.selectedDifficulty,
           let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
            difficultyState.selectedDifficulty = selectedDifficulty
        }
        difficultyState.customPrompt = state.customPrompt
        return difficultyState
    }

    private func makeDurationState(_ state: State) -> DurationSelectionFeature.State {
        var durationState = DurationSelectionFeature.State()
        if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.selectedWeeks) {
            durationState.selectedWeeks = weeks
        }
        return durationState
    }

    private func makeSummaryState(_ state: State) -> AddSubjectSummaryFeature.State {
        let isCategory = state.contentType == .category
        return AddSubjectSummaryFeature.State(
            contentType: state.contentType,
            fileName: isCategory ? nil : state.uploadedFileURL?.lastPathComponent,
            rootCategory: isCategory ? state.selectedRootCategory : nil,
            mainCategory: isCategory ? state.selectedMainCategory : nil,
            subCategory: isCategory ? state.selectedSubCategory : nil,
            detailCategory: isCategory ? state.selectedDetailCategory?.name : nil,
            difficulty: state.selectedDifficulty,
            customPrompt: state.customPrompt,
            programWeeks: state.selectedWeeks
        )
    }

    private func makeOnboardingData(_ state: State) -> OnboardingData {
        let isCategory = state.contentType == .category
        return OnboardingData(
            userName: "",
            leaveHomeTime: nil,
            returnHomeTime: nil,
            dailyUsageMinutes: 0,
            contentType: state.contentType,
            uploadedFileURL: isCategory ? nil : state.uploadedFileURL,
            selectedRootCategory: isCategory ? state.selectedRootCategory : nil,
            selectedMainCategory: isCategory ? state.selectedMainCategory : nil,
            selectedSubCategory: isCategory ? state.selectedSubCategory : nil,
            selectedDetailCategory: isCategory ? state.selectedDetailCategory : nil,
            difficulty: state.selectedDifficulty,
            customPrompt: state.customPrompt,
            programWeeks: state.selectedWeeks
        )
    }
}

extension AddSubjectFlowFeature.Step.State: Equatable {}

struct AddSubjectFlowView: View {
    let store: StoreOf<AddSubjectFlowFeature>

    var body: some View {
        Group {
            switch store.scope(state: \.step, action: \.step).case {
            case let .category(categoryStore):
                CategorySelectionView(store: categoryStore, showProgressBar: false)
            case let .fileUpload(fileUploadStore):
                FileUploadView(store: fileUploadStore, showProgressBar: false)
            case let .difficulty(difficultyStore):
                DifficultySelectionView(store: difficultyStore)
            case let .duration(durationStore):
                DurationSelectionView(store: durationStore)
            case let .summary(summaryStore):
                AddSubjectSummaryView(store: summaryStore)
            case let .loading(loadingStore):
                OnboardingLoadingView(store: loadingStore)
            case let .complete(completeStore):
                AddSubjectCompleteView(store: completeStore)
            }
        }
        .colorScheme(.light)
    }
}

@Reducer
struct AddSubjectCompleteFeature {
    @ObservableState
    struct State: Equatable {
        // 필요한 정보 없음 (고정 메시지)
    }
    
    enum Action {
        case confirmTapped
        case delegate(Delegate)
        
        enum Delegate {
            case completed
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { (state: inout State, action: Action) -> Effect<Action> in
            switch action {
            case .confirmTapped:
                return .send(.delegate(.completed))
                
            case .delegate:
                return .none
            }
        }
    }
}


struct AddSubjectCompleteView: View {
    let store: StoreOf<AddSubjectCompleteFeature>
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 캐릭터 이미지
                Image("character_addComplete")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // 확인 버튼
                TTEButton(
                    title: "시작하기",
                    size: .large,
                    isEnabled: true
                ) {
                    store.send(.confirmTapped)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
    }
}
