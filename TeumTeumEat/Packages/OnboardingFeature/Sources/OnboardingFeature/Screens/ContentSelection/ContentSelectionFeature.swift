//
//  ContentSelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
public struct ContentSelectionFeature {
    public init() {}

    @ObservableState
    public struct State: Equatable {
        public var selectedType: ContentType?

        public init() {}

        public var canProceed: Bool {
            selectedType != nil
        }

        public enum ContentType {
            case fileUpload
            case category
        }
    }

    public enum Action {
        case contentTypeSelected(State.ContentType)
        case nextTapped
        case backTapped
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .contentTypeSelected(type):
                state.selectedType = type
                return .none

            case .nextTapped:
                return .none

            case .backTapped:
                return .none
            }
        }
    }
}
