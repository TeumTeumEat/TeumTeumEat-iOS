//
//  WelcomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture

@Reducer
struct WelcomeFeature {
    @ObservableState
    struct State: Equatable {
        
    }
    enum Action {
        case startOnboardingTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startOnboardingTapped:
                return .none
            }
        }
    }
}
