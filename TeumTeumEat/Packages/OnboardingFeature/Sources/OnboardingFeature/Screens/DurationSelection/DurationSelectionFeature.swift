//
//  DurationSelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct DurationSelectionFeature {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        public var selectedWeeks: Weeks?

        public var canProceed: Bool {
            selectedWeeks != nil
        }

        public init() {}

        public enum Weeks: Int, CaseIterable {
            case one = 1
            case two = 2
            case three = 3
            case four = 4
            
            var displayText: String {
                "\(rawValue)주"
            }
        }
    }
    
    public enum Action {
        case backTapped
        case weeksSelected(State.Weeks)
        case nextTapped
    }

    public var body: some ReducerOf<Self> {
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
