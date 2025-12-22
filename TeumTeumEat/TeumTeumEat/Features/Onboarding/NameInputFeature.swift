//
//  NameInputFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct NameInputFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        
        var canProceed: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    enum Action {
        case nameChanged(String)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .nameChanged(name):
                state.name = name
                return .none
                
            case .nextTapped:
                // 부모에게 알림 (OnboardingFeature에서 처리)
                return .none
                
            case .backTapped:
                // 부모에게 알림
                return .none
            }
        }
    }
}
