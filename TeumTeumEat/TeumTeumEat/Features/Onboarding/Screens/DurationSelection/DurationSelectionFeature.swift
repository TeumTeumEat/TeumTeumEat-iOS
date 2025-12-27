//
//  DurationSelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct DurationSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedWeeks: Weeks?
        
        var canProceed: Bool {
            selectedWeeks != nil
        }
        
        enum Weeks: Int, CaseIterable {
            case one = 1
            case two = 2
            case three = 3
            case four = 4
            
            var displayText: String {
                "\(rawValue)주"
            }
        }
    }
    
    enum Action {
        case backTapped
        case weeksSelected(State.Weeks)
        case nextTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case let .weeksSelected(weeks):
                state.selectedWeeks = weeks
                return .none
                
            case .nextTapped:
                return .none
            }
        }
    }
}
