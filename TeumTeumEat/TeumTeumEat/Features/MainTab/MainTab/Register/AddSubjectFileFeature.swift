//
//  AddSubjectFileFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AddSubjectFileFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .fileUpload
        
        // 선택된 값들
        var uploadedFileURL: URL?
        var selectedDifficulty: String?
        var customPrompt: String = ""
        var selectedWeeks: Int = 0
        
        // 각 Step State
        var fileUpload: FileUploadFeature.State?
        var difficultySelection: DifficultySelectionFeature.State?
        var durationSelection: DurationSelectionFeature.State?
        var loading: OnboardingLoadingFeature.State?
        var complete: AddSubjectCompleteFeature.State?
        
        enum Step {
            case fileUpload
            case difficulty
            case duration
            case loading
            case complete
        }
        
        init() {
            // fileUpload 초기화
            self.fileUpload = FileUploadFeature.State()
        }
    }
    
    enum Action {
        case fileUpload(FileUploadFeature.Action)
        case difficultySelection(DifficultySelectionFeature.Action)
        case durationSelection(DurationSelectionFeature.Action)
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
            // MARK: - File Upload
            case .fileUpload(.backTapped):
                // 뒤로가기 → Sheet 닫기
                return .send(.delegate(.cancelled))
                
            case .fileUpload(.nextTapped):
                // 파일 선택 완료
                if let fileURL = state.fileUpload?.selectedFileURL {
                    state.uploadedFileURL = fileURL
                }
                
                // 파일 state 제거하고 난이도로 이동
                state.fileUpload = nil
                state.currentStep = .difficulty
                
                var difficultyState = DifficultySelectionFeature.State()
                if let difficulty = state.selectedDifficulty,
                   let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                    difficultyState.selectedDifficulty = selectedDifficulty
                }
                difficultyState.customPrompt = state.customPrompt
                state.difficultySelection = difficultyState
                return .none
                
            // MARK: - Difficulty Selection
            case .difficultySelection(.backTapped):
                // 난이도에서 뒤로가기 → 파일 업로드로
                state.difficultySelection = nil
                state.currentStep = .fileUpload
                
                // 파일 업로드 state 복원
                var fileUploadState = FileUploadFeature.State()
                if let url = state.uploadedFileURL {
                    fileUploadState.selectedFileURL = url
                    fileUploadState.selectedFileName = url.lastPathComponent
                    if let fileSize = try? url.fileSize() {
                        fileUploadState.selectedFileSize = fileSize
                    }
                }
                state.fileUpload = fileUploadState
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
                
                // AddSubjectFileFeature.swift

                case .durationSelection(.nextTapped):
                    // 기간 선택 완료 → 로딩으로
                    if let weeks = state.durationSelection?.selectedWeeks {
                        state.selectedWeeks = weeks.rawValue
                    }
                    
                    print("주제 추가 시작 (파일)")
                    print("파일: \(state.uploadedFileURL?.lastPathComponent ?? "없음")")
                    print("난이도: \(state.selectedDifficulty ?? "")")
                    print("프롬프트: \(state.customPrompt)")
                    print("기간: \(state.selectedWeeks)주")
                    
                    // AddSubjectFileFeature 데이터 → OnboardingData 변환
                    let onboardingData = OnboardingData(
                        userName: "",           // 주제 추가에서는 사용 안 함
                        leaveHomeTime: nil,     // 주제 추가에서는 사용 안 함
                        returnHomeTime: nil,    // 주제 추가에서는 사용 안 함
                        dailyUsageMinutes: 0,   // 주제 추가에서는 사용 안 함
                        contentType: .fileUpload,  // 파일 업로드
                        uploadedFileURL: state.uploadedFileURL,
                        selectedMainCategory: nil,
                        selectedSubCategory: nil,
                        selectedDetailCategory: nil,
                        difficulty: state.selectedDifficulty,
                        customPrompt: state.customPrompt,
                        programWeeks: state.selectedWeeks
                    )
                    
                    // 로딩 화면으로 전환
                    state.durationSelection = nil
                    state.currentStep = .loading
                    state.loading = OnboardingLoadingFeature.State(
                        onboardingData: onboardingData,
                        isOnboarding: false  // 주제 추가 모드
                    )
                    
                    return .none
                
            // MARK: - Loading & Complete
            case .loading(.loadingCompleted):
                print("주제 추가 API 완료 (파일)")
                
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
                
            case .fileUpload, .difficultySelection, .durationSelection, .loading, .complete, .delegate:
                return .none
            }
        }
        .ifLet(\.fileUpload, action: \.fileUpload) {
            FileUploadFeature()
        }
        .ifLet(\.difficultySelection, action: \.difficultySelection) {
            DifficultySelectionFeature()
        }
        .ifLet(\.durationSelection, action: \.durationSelection) {
            DurationSelectionFeature()
        }
        .ifLet(\.loading, action: \.loading) {
            OnboardingLoadingFeature()
        }
        .ifLet(\.complete, action: \.complete) {
            AddSubjectCompleteFeature()
        }
    }
}

struct AddSubjectFileView: View {
    let store: StoreOf<AddSubjectFileFeature>
    
    var body: some View {
        Group {
            switch store.currentStep {
            case .fileUpload:
                if let fileUploadStore = store.scope(state: \.fileUpload, action: \.fileUpload) {
                    FileUploadView(store: fileUploadStore, showProgressBar: false)
                }
            case .difficulty:
                if let difficultyStore = store.scope(state: \.difficultySelection, action: \.difficultySelection) {
                    DifficultySelectionView(store: difficultyStore)
                }
            case .duration:
                if let durationStore = store.scope(state: \.durationSelection, action: \.durationSelection) {
                    DurationSelectionView(store: durationStore)
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
    }
}
