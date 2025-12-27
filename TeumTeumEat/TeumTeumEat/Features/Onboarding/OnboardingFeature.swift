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
        var durationSelection: DurationSelectionFeature.State?
        
        enum Step: Int {
            case welcome = 0
            case nameInput = 1
            case timeSetting = 2
            case usageDuration = 3
            case contentSelection = 4
            case fileUpload = 5
            case categorySelection = 6
            case durationSelection = 7
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
        case durationSelection(DurationSelectionFeature.Action)
        case nextStep
        case previousStep
    }
    
    var body: some ReducerOf<Self> {
        Reduce(self.core)  // ⭐️ reduce → core로 변경
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
            .ifLet(\.durationSelection, action: \.durationSelection) {
                DurationSelectionFeature()
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
            } else {
                state.onboardingData.contentType = .category
            }
            
            state.contentSelection = nil
            if type == .fileUpload {
                state.fileUpload = FileUploadFeature.State()
            } else {
                state.categorySelection = CategorySelectionFeature.State()
            }
            
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
            state.durationSelection = DurationSelectionFeature.State()
            return .none
            
        // CategorySelection
        case .categorySelection(.backTapped):
            state.categorySelection = nil
            state.contentSelection = ContentSelectionFeature.State()
            return .none
            
        case .categorySelection(.nextTapped):
            if let categories = state.categorySelection?.selectedCategories {
                state.onboardingData.selectedCategories = Array(categories)
            }
            state.categorySelection = nil
            state.durationSelection = DurationSelectionFeature.State()
            return .none
            
        // DurationSelection
        case .durationSelection(.backTapped):
            state.durationSelection = nil
            
            if state.onboardingData.contentType == .fileUpload {
                state.fileUpload = FileUploadFeature.State()
                if let url = state.onboardingData.uploadedFileURL {
                    state.fileUpload?.selectedFileURL = url
                    state.fileUpload?.selectedFileName = url.lastPathComponent
                    if let fileSize = try? url.fileSize() {
                        state.fileUpload?.selectedFileSize = fileSize
                    }
                }
            } else {
                // 로컬 변수로 복사
                let categories = state.onboardingData.selectedCategories
                state.categorySelection = CategorySelectionFeature.State()
                state.categorySelection?.selectedCategories = Set(categories)
            }
            return .none
            
        case .durationSelection(.nextTapped):
            if let weeks = state.durationSelection?.selectedWeeks {
                state.onboardingData.programWeeks = weeks.rawValue
            }
            print("온보딩 완료!")
            print("수집된 데이터: \(state.onboardingData)")
            return .none
            
        // NextStep - 직접 처리
        case .nextStep:
            switch state.currentStep {
            case .welcome:
                state.welcome = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State()
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .timeSetting
                state.timeSetting = TimeSettingFeature.State()
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .usageDuration
                state.usageDuration = UsageDurationFeature.State()
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .contentSelection
                state.contentSelection = ContentSelectionFeature.State()
                
            case .contentSelection, .fileUpload, .categorySelection, .durationSelection:
                break
            }
            return .none
            
        // PreviousStep - 직접 처리
        case .previousStep:
            switch state.currentStep {
            case .welcome:
                break
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .welcome
                state.welcome = WelcomeFeature.State()
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State(
                    name: state.onboardingData.userName
                )
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .timeSetting
                state.timeSetting = TimeSettingFeature.State()
                
            case .contentSelection:
                state.contentSelection = nil
                state.currentStep = .usageDuration
                state.usageDuration = UsageDurationFeature.State()
                
            case .fileUpload, .categorySelection, .durationSelection:
                break
            }
            return .none
            
        // Default
        case .welcome, .nameInput, .timeSetting, .usageDuration, .contentSelection, .fileUpload, .categorySelection, .durationSelection:
            return .none
        }
    }
    
    private func handleNextStep(state: inout State) -> Effect<Action> {
        switch state.currentStep {
        case .welcome:
            state.welcome = nil
            state.currentStep = .nameInput
            state.nameInput = NameInputFeature.State()
            
        case .nameInput:
            state.nameInput = nil
            state.currentStep = .timeSetting
            state.timeSetting = TimeSettingFeature.State()
            
        case .timeSetting:
            state.timeSetting = nil
            state.currentStep = .usageDuration
            state.usageDuration = UsageDurationFeature.State()
            
        case .usageDuration:
            state.usageDuration = nil
            state.currentStep = .contentSelection
            state.contentSelection = ContentSelectionFeature.State()
            
        case .contentSelection, .fileUpload, .categorySelection, .durationSelection:
            break
        }
        return .none
    }
    
    private func handlePreviousStep(state: inout State) -> Effect<Action> {
        switch state.currentStep {
        case .welcome:
            break
            
        case .nameInput:
            state.nameInput = nil
            state.currentStep = .welcome
            state.welcome = WelcomeFeature.State()
            
        case .timeSetting:
            state.timeSetting = nil
            state.currentStep = .nameInput
            state.nameInput = NameInputFeature.State(
                name: state.onboardingData.userName
            )
            
        case .usageDuration:
            state.usageDuration = nil
            state.currentStep = .timeSetting
            state.timeSetting = TimeSettingFeature.State()
            
        case .contentSelection:
            state.contentSelection = nil
            state.currentStep = .usageDuration
            state.usageDuration = UsageDurationFeature.State()
            
        case .fileUpload, .categorySelection, .durationSelection:
            break
        }
        return .none
    }
}
