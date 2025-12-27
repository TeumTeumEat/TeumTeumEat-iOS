//
//  ContentSelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct ContentSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedType: ContentType?
        
        var canProceed: Bool {
            selectedType != nil
        }
        
        enum ContentType {
            case fileUpload
            case category
        }
    }
    
    enum Action {
        case contentTypeSelected(State.ContentType)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
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
