//
//  TestFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/11/25.
//

import ComposableArchitecture
import Combine

@Reducer
struct TestFeature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }
    
    enum Action {
        case increment
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .increment:
                state.count += 1
                return .none
            }
            
        }
    }
}
