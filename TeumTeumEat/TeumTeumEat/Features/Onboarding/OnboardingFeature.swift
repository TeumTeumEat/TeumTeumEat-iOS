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
        var fileUpload: FileUploadFeature.State?  // ← 추가
        var showCategorySelection = false
        
        enum Step: Int {
            case welcome = 0
            case nameInput = 1
            case timeSetting = 2
            case usageDuration = 3
            case contentSelection = 4
            case fileUpload = 5
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
        case nextStep
        case previousStep
        case backFromCategorySelection
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .welcome(.startOnboardingTapped):
                return .send(.nextStep)
                
            case .nameInput(.nextTapped):
                if let name = state.nameInput?.name {
                    state.onboardingData.userName = name
                }
                return .send(.nextStep)
                
            case .nameInput(.backTapped):
                return .send(.previousStep)
                
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
                
            case .usageDuration(.nextTapped):
                if let duration = state.usageDuration?.selectedDuration {
                    state.onboardingData.dailyUsageMinutes = duration.rawValue
                }
                return .send(.nextStep)
                
            case .usageDuration(.backTapped):
                return .send(.previousStep)
                
            case .contentSelection(.nextTapped):
                if let type = state.contentSelection?.selectedType {
                    state.onboardingData.contentType = type == .fileUpload ? .fileUpload : .category
                    
                    // 분기 처리
                    if type == .fileUpload {
                        state.contentSelection = nil
                        state.fileUpload = FileUploadFeature.State()
                    } else {
                        state.showCategorySelection = true
                    }
                }
                return .none
                
            case .contentSelection(.backTapped):
                return .send(.previousStep)
                
            // FileUpload 액션 처리 추가
            case .fileUpload(.backTapped):
                state.fileUpload = nil
                state.contentSelection = ContentSelectionFeature.State()
                return .none
                
            case .fileUpload(.nextTapped):
                if let fileURL = state.fileUpload?.selectedFileURL {
                    state.onboardingData.uploadedFileURL = fileURL
                }
                // TODO: 다음 화면으로 이동 (온보딩 완료 등)
                return .none
                
            case .backFromCategorySelection:
                state.showCategorySelection = false
                return .none
                
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
                    
                case .contentSelection:
                    return .none
                    
                case .fileUpload:
                    return .none
                }
                return .none
                
            case .previousStep:
                switch state.currentStep {
                case .welcome:
                    return .none
                    
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
                    
                case .fileUpload:
                    return .none
                }
                return .none
                
            case .welcome, .nameInput, .timeSetting, .usageDuration, .contentSelection, .fileUpload:
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
    }
}
