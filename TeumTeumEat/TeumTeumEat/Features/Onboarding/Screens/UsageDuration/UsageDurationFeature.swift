//
//  UsageDurationFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct UsageDurationFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDuration: Duration?
        
        var canProceed: Bool {
            selectedDuration != nil
        }
        
        enum Duration: Int, CaseIterable {
            case five = 5
            case seven = 7
            case ten = 10
            case fifteenPlus = 15
            
            var displayText: String {
                switch self {
                case .five: return "5분"
                case .seven: return "7분"
                case .ten: return "10분"
                case .fifteenPlus: return "15분+"
                }
            }
        }
    }
    
    enum Action {
        case durationSelected(State.Duration)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .durationSelected(duration):
                state.selectedDuration = duration
                return .none
                
            case .nextTapped:
                return .none
                
            case .backTapped:
                return .none
            }
        }
    }
}
