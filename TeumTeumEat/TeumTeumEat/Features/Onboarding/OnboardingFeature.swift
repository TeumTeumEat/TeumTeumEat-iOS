//
//  OnboardingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .welcome
        var onboardingData = OnboardingData()
        
        var welcome: WelcomeFeature.State?
        var nameInput: NameInputFeature.State?
        var timeSetting: TimeSettingFeature.State?
        var usageDuration: UsageDurationFeature.State?
        var contentSelection: ContentSelectionFeature.State?
        var fileUpload: FileUploadFeature.State?
        var categorySelection: CategorySelectionFeature.State?
        var difficultySelection: DifficultySelectionFeature.State?
        var durationSelection: DurationSelectionFeature.State?
        var summary: OnboardingSummaryFeature.State?
        var loading: OnboardingLoadingFeature.State?
        var complete: OnboardingCompleteFeature.State?
        
        enum Step: Int {
            case welcome = 0
            case nameInput = 1
            case timeSetting = 2
            case usageDuration = 3
            case contentSelection = 4
            case fileUpload = 5
            case categorySelection = 6
            case difficultySelection = 7
            case durationSelection = 8
            case summary = 9
            case loading = 10
            case complete = 11
        }
        
        init() {
            self.welcome = WelcomeFeature.State()
        }
    }
    
    enum Action {
        case welcome(WelcomeFeature.Action)
        case nameInput(NameInputFeature.Action)
        case timeSetting(TimeSettingFeature.Action)
        case usageDuration(UsageDurationFeature.Action)
        case contentSelection(ContentSelectionFeature.Action)
        case fileUpload(FileUploadFeature.Action)
        case categorySelection(CategorySelectionFeature.Action)
        case difficultySelection(DifficultySelectionFeature.Action)
        case durationSelection(DurationSelectionFeature.Action)
        case summary(OnboardingSummaryFeature.Action)
        case loading(OnboardingLoadingFeature.Action)
        case complete(OnboardingCompleteFeature.Action)
        case nextStep
        case previousStep
    }
    
    var body: some ReducerOf<Self> {
        Reduce(self.core)
            .onChange(of: \.onboardingData) { oldValue, newValue in
                Reduce { state, action in
                    printOnboardingData(action: action, data: newValue)
                    return .none
                }
            }
            .ifLet(\.welcome, action: \.welcome) {
                WelcomeFeature()
            }
            .ifLet(\.nameInput, action: \.nameInput) {
                NameInputFeature()
            }
            .ifLet(\.timeSetting, action: \.timeSetting) {
                TimeSettingFeature()
            }
            .ifLet(\.usageDuration, action: \.usageDuration) {
                UsageDurationFeature()
            }
            .ifLet(\.contentSelection, action: \.contentSelection) {
                ContentSelectionFeature()
            }
            .ifLet(\.fileUpload, action: \.fileUpload) {
                FileUploadFeature()
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
                OnboardingSummaryFeature()
            }
            .ifLet(\.loading, action: \.loading) {
                OnboardingLoadingFeature()
            }
            .ifLet(\.complete, action: \.complete) {
                OnboardingCompleteFeature()
            }
    }
    
    func core(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        // Welcome
        case .welcome(.startOnboardingTapped):
            return .send(.nextStep)
            
        // NameInput
        case .nameInput(.nextTapped):
            if let name = state.nameInput?.name {
                state.onboardingData.userName = name
            }
            return .send(.nextStep)
            
        case .nameInput(.backTapped):
            return .send(.previousStep)
            
        // TimeSetting
        case .timeSetting(.nextTapped):
            if let leaveTime = state.timeSetting?.leaveTime {
                state.onboardingData.leaveHomeTime = leaveTime
            }
            if let returnTime = state.timeSetting?.returnTime {
                state.onboardingData.returnHomeTime = returnTime
            }
            return .send(.nextStep)
            
        case .timeSetting(.backTapped):
            return .send(.previousStep)
            
        // UsageDuration
        case .usageDuration(.nextTapped):
            if let duration = state.usageDuration?.selectedDuration {
                state.onboardingData.dailyUsageMinutes = duration.rawValue
            }
            return .send(.nextStep)
            
        case .usageDuration(.backTapped):
            return .send(.previousStep)
            
        // ContentSelection
        case .contentSelection(.nextTapped):
            guard let type = state.contentSelection?.selectedType else {
                return .none
            }
            
            if type == .fileUpload {
                state.onboardingData.contentType = .fileUpload
                state.onboardingData.selectedRootCategory = nil
                state.onboardingData.selectedMainCategory = nil
                state.onboardingData.selectedSubCategory = nil
                state.onboardingData.selectedDetailCategory = nil
            } else {
                state.onboardingData.contentType = .category
                state.onboardingData.uploadedFileURL = nil
            }
            
            state.contentSelection = nil
            if type == .fileUpload {
                var fileUploadState = FileUploadFeature.State()
                if let url = state.onboardingData.uploadedFileURL {
                    fileUploadState.selectedFileURL = url
                    fileUploadState.selectedFileName = url.lastPathComponent
                    if let fileSize = try? url.fileSize() {
                        fileUploadState.selectedFileSize = fileSize
                    }
                }
                state.fileUpload = fileUploadState
            } else {
                // CategorySelection State 복원 (String으로)
                var categoryState = CategorySelectionFeature.State()
                categoryState.selectedRootCategory = state.onboardingData.selectedRootCategory
                categoryState.selectedMainCategory = state.onboardingData.selectedMainCategory
                categoryState.selectedSubCategory = state.onboardingData.selectedSubCategory
                categoryState.selectedDetailCategory = state.onboardingData.selectedDetailCategory
                state.categorySelection = categoryState
            }
            
            return .none

        case .difficultySelection(.backTapped):
            state.difficultySelection = nil
            
            if state.onboardingData.contentType == .fileUpload {
                var fileUploadState = FileUploadFeature.State()
                if let url = state.onboardingData.uploadedFileURL {
                    fileUploadState.selectedFileURL = url
                    fileUploadState.selectedFileName = url.lastPathComponent
                    if let fileSize = try? url.fileSize() {
                        fileUploadState.selectedFileSize = fileSize
                    }
                }
                state.fileUpload = fileUploadState
            } else {
                // CategorySelection State 복원 - 3단계로
                var categoryState = CategorySelectionFeature.State()
                categoryState.currentStep = .detailCategory
                categoryState.selectedRootCategory = state.onboardingData.selectedRootCategory
                categoryState.selectedMainCategory = state.onboardingData.selectedMainCategory
                categoryState.selectedSubCategory = state.onboardingData.selectedSubCategory
                categoryState.selectedDetailCategory = state.onboardingData.selectedDetailCategory
                state.categorySelection = categoryState
            }
            return .none
            
        case .categorySelection(.delegate(.saveProgress(let root, let main, let sub, let detail))):
            print("OnboardingFeature - saveProgress")
            print("Root: \(root ?? "nil")")
            print("Main: \(main ?? "nil")")
            print("Sub: \(sub ?? "nil")")
            print("Detail: \(detail?.name ?? "nil")")
            
            // String과 CategoryResponse로 저장
            state.onboardingData.selectedRootCategory = root
            state.onboardingData.selectedMainCategory = main
            state.onboardingData.selectedSubCategory = sub
            state.onboardingData.selectedDetailCategory = detail
            return .none
            
            
        case .categorySelection(.delegate(.backToContentSelection)):
            print("OnboardingFeature - backToContentSelection")
            state.categorySelection = nil
            state.contentSelection = ContentSelectionFeature.State()
            return .none
            
        case .categorySelection(.delegate(.completed(let root, let main, let sub, let detail))):
            print("OnboardingFeature - category completed")
            
            // String과 CategoryResponse로 저장
            state.onboardingData.selectedRootCategory = root
            state.onboardingData.selectedMainCategory = main
            state.onboardingData.selectedSubCategory = sub
            state.onboardingData.selectedDetailCategory = detail
            
            state.categorySelection = nil
            
            var difficultyState = DifficultySelectionFeature.State()
            if let difficulty = state.onboardingData.difficulty,
               let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                difficultyState.selectedDifficulty = selectedDifficulty
            }
            difficultyState.customPrompt = state.onboardingData.customPrompt
            state.difficultySelection = difficultyState
            return .none

            
        case .contentSelection(.backTapped):
            return .send(.previousStep)
            
        // FileUpload
        case .fileUpload(.backTapped):
            state.fileUpload = nil
            state.contentSelection = ContentSelectionFeature.State()
            return .none
            
        case .fileUpload(.nextTapped):
            if let fileURL = state.fileUpload?.selectedFileURL {
                state.onboardingData.uploadedFileURL = fileURL
            }
            
            state.fileUpload = nil
            
            // Difficulty State 생성 (복원)
            var difficultyState = DifficultySelectionFeature.State()
            if let difficulty = state.onboardingData.difficulty,
               let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                difficultyState.selectedDifficulty = selectedDifficulty
            }
            difficultyState.customPrompt = state.onboardingData.customPrompt
            state.difficultySelection = difficultyState
            
            return .none
            
        // CategorySelection
            
        case .difficultySelection(.nextTapped):
            if let difficulty = state.difficultySelection?.selectedDifficulty {
                state.onboardingData.difficulty = difficulty.rawValue
            }
            state.onboardingData.customPrompt = state.difficultySelection?.customPrompt ?? ""
            
            state.difficultySelection = nil
            
            // Duration State 생성 (복원)
            var durationState = DurationSelectionFeature.State()
            if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.onboardingData.programWeeks) {
                durationState.selectedWeeks = weeks
            }
            state.durationSelection = durationState
            
            return .none
            
        // DurationSelection
        case .durationSelection(.backTapped):
            state.durationSelection = nil
            
            // Difficulty State 생성 (복원)
            var difficultyState = DifficultySelectionFeature.State()
            if let difficulty = state.onboardingData.difficulty,
               let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficulty) {
                difficultyState.selectedDifficulty = selectedDifficulty
            }
            difficultyState.customPrompt = state.onboardingData.customPrompt
            state.difficultySelection = difficultyState
            
            return .none
            
        case .durationSelection(.nextTapped):
            if let weeks = state.durationSelection?.selectedWeeks {
                state.onboardingData.programWeeks = weeks.rawValue
            }
            
            state.durationSelection = nil
            state.summary = OnboardingSummaryFeature.State(
                userName: state.onboardingData.userName,
                leaveHomeTime: state.onboardingData.leaveHomeTime,
                returnHomeTime: state.onboardingData.returnHomeTime,
                dailyUsageMinutes: state.onboardingData.dailyUsageMinutes,
                programWeeks: state.onboardingData.programWeeks,
                contentType: state.onboardingData.contentType,
                fileName: state.onboardingData.uploadedFileURL?.lastPathComponent,
                rootCategory: state.onboardingData.selectedRootCategory,
                mainCategory: state.onboardingData.selectedMainCategory,
                subCategory: state.onboardingData.selectedSubCategory,
                detailCategory: state.onboardingData.selectedDetailCategory?.name,
                difficulty: state.onboardingData.difficulty,
                customPrompt: state.onboardingData.customPrompt
            )
            return .none
            
        // Summary
        case .summary(.backTapped):
            state.summary = nil
            
            // Duration State 생성 (복원)
            var durationState = DurationSelectionFeature.State()
            if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.onboardingData.programWeeks) {
                durationState.selectedWeeks = weeks
            }
            state.durationSelection = durationState
            
            return .none
            
        case .summary(.completeTapped):
            // Summary에서 수집한 OnboardingData 전달
            let onboardingData = state.onboardingData
            
            state.summary = nil
            state.loading = OnboardingLoadingFeature.State(
                onboardingData: onboardingData,
                isOnboarding: true,
                isFileUpload: onboardingData.contentType == .fileUpload // 온보딩 모드
            )
            return .none
        // Loading
        case .loading(.loadingCompleted):
            state.loading = nil
            state.complete = OnboardingCompleteFeature.State(
                userName: state.onboardingData.userName
            )
            return .none
            
        case .loading(.delegate(.onboardingCancelled)):
            // 온보딩 취소 → Welcome 화면으로
            state.loading = nil
            state.currentStep = .welcome
            state.welcome = WelcomeFeature.State()
            state.onboardingData = OnboardingData()  // 데이터 초기화
            return .none
            
        // Complete
        case .complete(.startButtonTapped):
            print("온보딩 완료!")
            print("수집된 데이터: \(state.onboardingData)")
            // TODO: AppFeature로 완료 알림 → 메인 화면으로 이동
            return .none
            
        // NextStep
        case .nextStep:
            switch state.currentStep {
            case .welcome:
                state.welcome = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State()
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .timeSetting
                state.timeSetting = TimeSettingFeature.State(
                           leaveTime: state.onboardingData.leaveHomeTime,
                           returnTime: state.onboardingData.returnHomeTime
                       )
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .usageDuration
                
                // UsageDuration State 생성 (복원)
                var usageDurationState = UsageDurationFeature.State()
                if let duration = UsageDurationFeature.State.Duration(rawValue: state.onboardingData.dailyUsageMinutes) {
                    usageDurationState.selectedDuration = duration
                }
                state.usageDuration = usageDurationState
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .contentSelection
                state.contentSelection = ContentSelectionFeature.State()
                
            case .contentSelection, .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary, .loading, .complete:
                break
            }
            return .none
            
        // PreviousStep
        case .previousStep:
            switch state.currentStep {
            case .welcome:
                break
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .welcome
                state.welcome = WelcomeFeature.State()
                state.onboardingData = OnboardingData()
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State(
                    name: state.onboardingData.userName
                )
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .timeSetting
                
                // TimeSetting State 생성 (복원)
                state.timeSetting = TimeSettingFeature.State(
                    leaveTime: state.onboardingData.leaveHomeTime,
                    returnTime: state.onboardingData.returnHomeTime
                )
                
            case .contentSelection:
                state.contentSelection = nil
                state.currentStep = .usageDuration
                
                // UsageDuration State 생성 (복원)
                var usageDurationState = UsageDurationFeature.State()
                if let duration = UsageDurationFeature.State.Duration(rawValue: state.onboardingData.dailyUsageMinutes) {
                    usageDurationState.selectedDuration = duration
                }
                state.usageDuration = usageDurationState
                
            case .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary, .loading, .complete:
                break
            }
            return .none
            
        // Default
        case .welcome, .nameInput, .timeSetting, .usageDuration, .contentSelection, .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary, .loading, .complete:
            return .none
        }
    }
}

private func printOnboardingData(action: OnboardingFeature.Action, data: OnboardingData) {
    print("==========================================")
    print("Action:", action)
    print("==========================================")
    print("이름:", data.userName)
    
    if let leaveTime = data.leaveHomeTime {
        print("집 나오는 시간:", leaveTime.formatted(date: .omitted, time: .shortened))
    } else {
        print("집 나오는 시간: 미설정")
    }
    
    if let returnTime = data.returnHomeTime {
        print("집 돌아오는 시간:", returnTime.formatted(date: .omitted, time: .shortened))
    } else {
        print("집 돌아오는 시간: 미설정")
    }
    
    print("목표 시간:", data.dailyUsageMinutes, "분")
    print("컨텐츠 타입:", data.contentType)
    
    if let url = data.uploadedFileURL {
        print("파일:", url.lastPathComponent)
    } else {
        print("파일: 없음")
    }
    
    if let main = data.selectedMainCategory {
        print("선택 카테고리 - 직군:", main)
    } else {
        print("선택 카테고리 - 직군: 미설정")
    }
    
    if let sub = data.selectedSubCategory {
        print("선택 카테고리 - 분야:", sub)
    } else {
        print("선택 카테고리 - 분야: 미설정")
    }
    
    if let detail = data.selectedDetailCategory {
        print("선택 카테고리 - 세부:", detail.name)
        print("카테고리 ID:", detail.categoryId)
        print("카테고리 Path:", detail.path)
    } else {
        print("선택 카테고리 - 세부: 미설정")
    }

    print("난이도:", data.difficulty ?? "미설정")
    print("프롬프트:", data.customPrompt.isEmpty ? "없음" : data.customPrompt)
    print("기간:", data.programWeeks, "주")
    print("==========================================")
}

extension String {
    var categoryIcon: String {
        switch self {
        case "앱개발자": return "phone"
        case "웹개발자": return "web"
        case "데이터베이스": return "pm"
        case "디자인": return "palette"
        case "PM": return "note"
        case "DevOps": return "phone"
        case "네트워크": return "phone"
        default: return "web"
        }
    }
}
