//
//  OnboardingCompleteFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct OnboardingCompleteFeature {
    @ObservableState
    struct State: Equatable {
        let userName: String
    }
    
    enum Action {
        case startButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startButtonTapped:
                // TODO: 메인 화면으로 이동
                return .none
            }
        }
    }
}
