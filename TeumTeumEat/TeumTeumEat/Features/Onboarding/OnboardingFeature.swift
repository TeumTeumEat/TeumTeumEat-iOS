//
//  OnboardingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .welcome
    //    var onboardingData = OnboardingData()
        
   //     var welcome:= WelcomeFeature.State?
        
        
        enum Step: Int, CaseIterable {
            case welcome = 0
            case nameInput
            case timeSetting
            case usageDuration
            case contentSelection
            case studyPeriod
            case summary
            case complete
            
            var progress: Double {
                Double(rawValue) / Double(Step.allCases.count - 1)
            }
        }
        
        var canGoNext: Bool {
            switch currentStep {
            case .welcome:
                return true
            case .nameInput:
                return true
            case .timeSetting:
                return true
            case .usageDuration:
                return true
            case .contentSelection:
                return true
            case .studyPeriod:
                return true
            case .summary:
                return true
            case .complete:
                return true
            }
        }
        
    }
}
