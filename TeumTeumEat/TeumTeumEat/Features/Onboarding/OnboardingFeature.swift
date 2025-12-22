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
        
        enum Step: Int {
            case welcome = 0
            case nameInput = 1
            case timeSetting = 2
        }
        
        init() {
            self.welcome = WelcomeFeature.State()
        }
    }
    
    enum Action {
        case welcome(WelcomeFeature.Action)
        case nameInput(NameInputFeature.Action)
        case timeSetting(TimeSettingFeature.Action)
        case nextStep
        case previousStep
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
                    print("다음 단계로 (아직 미구현)")
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
                }
                return .none
                
            case .welcome, .nameInput, .timeSetting:
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
    }
}
