//
//  OnboardingLoadingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct OnboardingLoadingFeature {
    @ObservableState
    struct State: Equatable {
        var loadingSteps: [LoadingStep] = [
            LoadingStep(title: "카테고리 퀴즈 생성 중", isCompleted: false),
            LoadingStep(title: "맞춤형 문제 준비 중", isCompleted: false),
            LoadingStep(title: "최적화 진행 중", isCompleted: false)
        ]
        
        var currentStepIndex: Int = 0
        
        struct LoadingStep: Equatable, Identifiable {
            let id = UUID()
            let title: String
            var isCompleted: Bool
        }
    }
    
    enum Action {
        case onAppear
        case updateProgress
        case loadingCompleted
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.updateProgress)
                }
                
            case .updateProgress:
                guard state.currentStepIndex < state.loadingSteps.count else {
                    return .send(.loadingCompleted)
                }
                
                state.loadingSteps[state.currentStepIndex].isCompleted = true
                state.currentStepIndex += 1
                
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.updateProgress)
                }
                
            case .loadingCompleted:
                // TODO: 온보딩 완료 화면으로 이동
                print("로딩 완료! 메인 화면으로 이동")
                return .none
            }
        }
    }
}
