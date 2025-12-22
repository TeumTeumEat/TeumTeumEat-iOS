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
        
        
        enum Step: Int, CaseIterable {
            case welcome = 0
            case nameInput
//            case timeSetting
//            case usageDuration
//            case contentSelection
//            case studyPeriod
//            case summary
//            case complete
            
            var progress: Double {
                Double(rawValue) / Double(Step.allCases.count - 1)
            }
        }
        
        init() {
            self.welcome = WelcomeFeature.State()
        }
        
        var canGoNext: Bool {
            switch currentStep {
            case .welcome:
                return true
            case .nameInput:
                return true
//            case .timeSetting:
//                return true
//            case .usageDuration:
//                return true
//            case .contentSelection:
//                return true
//            case .studyPeriod:
//                return true
//            case .summary:
//                return true
//            case .complete:
//                return true
            }
        }
        
    }
    
    enum Action {
        case welcome(WelcomeFeature.Action)
        case nameInput(NameInputFeature.Action)
        case nextStep
        case previousStep

    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .welcome(.startOnboardingTapped):
                return .send(.nextStep)
                
            case .nameInput(.nextTapped):
                // 이름 저장
                if let name = state.nameInput?.name {
                    state.onboardingData.userName = name
                }
                return .send(.nextStep)
                
            case .nameInput(.backTapped):
                return .send(.previousStep)
                
            case .nextStep:
                switch state.currentStep {
                case .welcome:
                    state.welcome = nil
                    state.currentStep = .nameInput
                    state.nameInput = NameInputFeature.State()
                    
                case .nameInput:
                    // 다음 단계 준비
                    print("다음 단계로")
                }
                return .none
                
            case .previousStep:
                switch state.currentStep {
                case .welcome:
                    // Welcome은 첫 화면이므로 뒤로 갈 곳 없음
                    return .none
                    
                case .nameInput:
                    state.nameInput = nil
                    state.currentStep = .welcome
                    state.welcome = WelcomeFeature.State()
                }
                return .none
                
            case .welcome, .nameInput:
                return .none
            }
        }
         .ifLet(\.welcome, action: \.welcome) {
             WelcomeFeature()
         }
         .ifLet(\.nameInput, action: \.nameInput) {
             NameInputFeature()
         }
     }
}
