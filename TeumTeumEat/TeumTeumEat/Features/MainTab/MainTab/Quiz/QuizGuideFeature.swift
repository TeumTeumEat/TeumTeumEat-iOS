//
//  QuizGuideFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/2/26.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizGuideFeature {
    @ObservableState
    struct State: Equatable {
        // 안내 화면 상태
    }
    
    enum Action {
        case startQuizButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuiz  // 퀴즈 시작
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startQuizButtonTapped:
                return .send(.delegate(.startQuiz))
                
            case .delegate:
                return .none
            }
        }
    }
}
