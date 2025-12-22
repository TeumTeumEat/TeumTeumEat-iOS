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
        
        init() {
            self.welcome = WelcomeFeature.State()
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
    
    enum Action {
        case welcome(WelcomeFeature.Action)
        case nextStep

    }
    
    var body: some ReducerOf<Self> {
         Reduce { state, action in
             switch action {
             case .welcome(.startOnboardingTapped):
                 // "시작하기" 버튼 눌렀을 때
                 return .send(.nextStep)
                 
             case .nextStep:
                 // 일단은 아무것도 안 함 (다음 Step 준비되면 전환)
                 print("다음 단계로 이동 준비")
                 return .none
                 
             case .welcome:
                 return .none
             }
         }
         .ifLet(\.welcome, action: \.welcome) {
             WelcomeFeature()
         }
     }
}
