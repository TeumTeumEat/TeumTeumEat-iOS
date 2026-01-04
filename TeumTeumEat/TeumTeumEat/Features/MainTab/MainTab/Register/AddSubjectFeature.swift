//
//  AddSubjectFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AddSubjectFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .category
        
        // 선택된 값들
        var selectedMainCategory: String?
        var selectedSubCategory: String?
        var selectedDetailCategory: CategoryResponse?
        var selectedDifficulty: String?
        var customPrompt: String = ""
        var selectedWeeks: Int = 0
        
        // 각 Step State (모두 Optional)
        var categorySelection: CategorySelectionFeature.State?
        var difficultySelection: DifficultySelectionFeature.State?
        var durationSelection: DurationSelectionFeature.State?
        var summary: AddSubjectSummaryFeature.State?
        var loading: OnboardingLoadingFeature.State?
        var complete: AddSubjectCompleteFeature.State?
        
        enum Step {
            case category
            case difficulty
            case duration
            case summary
            case loading
            case complete
        }
        
        init() {
            // categorySelection 초기화
            self.categorySelection = CategorySelectionFeature.State()
        }
    }
    
    enum Action {
        case categorySelection(CategorySelectionFeature.Action)
        case difficultySelection(DifficultySelectionFeature.Action)
        case durationSelection(DurationSelectionFeature.Action)
        case summary(AddSubjectSummaryFeature.Action)
        case loading(OnboardingLoadingFeature.Action)
        case complete(AddSubjectCompleteFeature.Action)
        case closeSheet
        case delegate(Delegate)
        
        enum Delegate {
            case completed
            case cancelled
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - Category Selection
            case .categorySelection(.delegate(.completed(let main, let sub, let detail))):
                // 카테고리 선택 완료
                state.selectedMainCategory = main
                state.selectedSubCategory = sub
                state.selectedDetailCategory = detail
                
                // 카테고리 state 제거하고 난이도로 이동
                state.categorySelection = nil
                state.currentStep = .difficulty
                
                var difficultyState = DifficultySelectionFeature.State()
                if let difficulty = state.selectedDifficulty,
                   let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                    difficultyState.selectedDifficulty = selectedDifficulty
                }
                difficultyState.customPrompt = state.customPrompt
                state.difficultySelection = difficultyState
                return .none
                
            case .categorySelection(.delegate(.backToContentSelection)):
                // 뒤로가기 → Sheet 닫기
                return .send(.delegate(.cancelled))
                
            // MARK: - Difficulty Selection
            case .difficultySelection(.backTapped):
                // 난이도에서 뒤로가기 → 카테고리로
                state.difficultySelection = nil
                state.currentStep = .category
                
                // 카테고리 state 복원 (detail 단계까지)
                var categoryState = CategorySelectionFeature.State()
                categoryState.selectedMainCategory = state.selectedMainCategory
                categoryState.selectedSubCategory = state.selectedSubCategory
                categoryState.selectedDetailCategory = state.selectedDetailCategory
                
                // 👇 핵심: currentStep을 detailCategory로 설정!
                if state.selectedDetailCategory != nil {
                    categoryState.currentStep = .detailCategory
                } else if state.selectedSubCategory != nil {
                    categoryState.currentStep = .subCategory
                } else if state.selectedMainCategory != nil {
                    categoryState.currentStep = .mainCategory
                }
                
                state.categorySelection = categoryState
                return .none
                
            case .difficultySelection(.nextTapped):
                // 난이도 선택 완료
                if let difficulty = state.difficultySelection?.selectedDifficulty {
                    state.selectedDifficulty = difficulty.rawValue
                }
                state.customPrompt = state.difficultySelection?.customPrompt ?? ""
                
                // 난이도 state 제거하고 기간으로 이동
                state.difficultySelection = nil
                state.currentStep = .duration
                
                var durationState = DurationSelectionFeature.State()
                if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.selectedWeeks) {
                    durationState.selectedWeeks = weeks
                }
                state.durationSelection = durationState
                return .none
                
            // MARK: - Duration Selection
            case .durationSelection(.backTapped):
                // 기간에서 뒤로가기 → 난이도로
                state.durationSelection = nil
                state.currentStep = .difficulty
                
                // 난이도 state 복원
                var difficultyState = DifficultySelectionFeature.State()
                if let difficulty = state.selectedDifficulty,
                   let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                    difficultyState.selectedDifficulty = selectedDifficulty
                }
                difficultyState.customPrompt = state.customPrompt
                state.difficultySelection = difficultyState
                return .none
                
            case .durationSelection(.nextTapped):
                // 기간 선택 완료 → Summary로
                if let weeks = state.durationSelection?.selectedWeeks {
                    state.selectedWeeks = weeks.rawValue
                }
                
                state.durationSelection = nil
                state.currentStep = .summary
                state.summary = AddSubjectSummaryFeature.State(
                    contentType: .category,
                    fileName: nil,
                    mainCategory: state.selectedMainCategory,
                    subCategory: state.selectedSubCategory,
                    detailCategory: state.selectedDetailCategory?.name,
                    difficulty: state.selectedDifficulty,
                    customPrompt: state.customPrompt,
                    programWeeks: state.selectedWeeks
                )
                return .none
                
            // MARK: - Summary
            case .summary(.delegate(.back)):
                // Summary에서 뒤로가기 → Duration으로
                state.summary = nil
                state.currentStep = .duration
                
                var durationState = DurationSelectionFeature.State()
                if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.selectedWeeks) {
                    durationState.selectedWeeks = weeks
                }
                state.durationSelection = durationState
                return .none
                
            case .summary(.delegate(.complete)):
                // Summary 완료 → Loading으로
                print("주제 추가 시작")
                print("카테고리: \(state.selectedMainCategory ?? "") > \(state.selectedSubCategory ?? "") > \(state.selectedDetailCategory?.name ?? "")")
                print("난이도: \(state.selectedDifficulty ?? "")")
                print("프롬프트: \(state.customPrompt)")
                print("기간: \(state.selectedWeeks)주")
                
                let onboardingData = OnboardingData(
                    userName: "",
                    leaveHomeTime: nil,
                    returnHomeTime: nil,
                    dailyUsageMinutes: 0,
                    contentType: .category,
                    uploadedFileURL: nil,
                    selectedMainCategory: state.selectedMainCategory,
                    selectedSubCategory: state.selectedSubCategory,
                    selectedDetailCategory: state.selectedDetailCategory,
                    difficulty: state.selectedDifficulty,
                    customPrompt: state.customPrompt,
                    programWeeks: state.selectedWeeks
                )
                
                state.summary = nil
                state.currentStep = .loading
                state.loading = OnboardingLoadingFeature.State(
                    onboardingData: onboardingData,
                    isOnboarding: false
                )
                
                return .none
                
            // MARK: - Loading & Complete
            case .loading(.loadingCompleted):
                // Complete 화면으로
                state.loading = nil
                state.currentStep = .complete
                state.complete = AddSubjectCompleteFeature.State()
                
                return .none
                
            case .complete(.confirmTapped):
                return .none
                
            case .complete(.delegate(.completed)):
                return .send(.delegate(.completed))
                
            // MARK: - Close & Delegate
            case .closeSheet:
                return .send(.delegate(.cancelled))
                
            case .categorySelection, .difficultySelection, .durationSelection, .summary, .delegate, .loading, .complete:
                return .none
            }
        }
        .ifLet(\.categorySelection, action: \.categorySelection) {
            CategorySelectionFeature()
        }
        .ifLet(\.difficultySelection, action: \.difficultySelection) {
            DifficultySelectionFeature()
        }
        .ifLet(\.durationSelection, action: \.durationSelection) {
            DurationSelectionFeature()
        }
        .ifLet(\.summary, action: \.summary) {
            AddSubjectSummaryFeature()
        }
        .ifLet(\.loading, action: \.loading) {
            OnboardingLoadingFeature()
        }
        .ifLet(\.complete, action: \.complete) {
            AddSubjectCompleteFeature()
        }
    }
}
struct AddSubjectView: View {
    let store: StoreOf<AddSubjectFeature>
    
    var body: some View {
        Group {
            switch store.currentStep {
            case .category:
                if let categoryStore = store.scope(state: \.categorySelection, action: \.categorySelection) {
                    CategorySelectionView(store: categoryStore, showProgressBar: false)
                }
            case .difficulty:
                if let difficultyStore = store.scope(state: \.difficultySelection, action: \.difficultySelection) {
                    DifficultySelectionView(store: difficultyStore)
                }
            case .duration:
                if let durationStore = store.scope(state: \.durationSelection, action: \.durationSelection) {
                    DurationSelectionView(store: durationStore)
                }
            case .summary:
                if let summaryStore = store.scope(state: \.summary, action: \.summary) {
                    AddSubjectSummaryView(store: summaryStore)
                }
            case .loading:
                if let loadingStore = store.scope(state: \.loading, action: \.loading) {
                    OnboardingLoadingView(store: loadingStore)
                }
            case .complete:  
                if let completeStore = store.scope(state: \.complete, action: \.complete) {
                    AddSubjectCompleteView(store: completeStore)
                }
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
        Reduce { state, action in
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
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.56, blue: 0.98),
                    Color(red: 0.17, green: 0.65, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 캐릭터 이미지
                Image("character_complete")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 40)
                
                // 메시지
                VStack(spacing: 12) {
                    Text("새로운 주제로")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("바뀌었어요!!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 확인 버튼
                TTEButton(
                    title: "확인",
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
