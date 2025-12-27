//
//  CategorySelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CategorySelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedCategories: Set<Category> = []
        
        var canProceed: Bool {
            !selectedCategories.isEmpty
        }
    }
    
    enum Action {
        case backTapped
        case categoryToggled(Category) 
        case nextTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case let .categoryToggled(category):
                state.selectedCategories = [category]
                return .none
                
            case .nextTapped:
                return .none
            }
        }
    }
}

enum Category: String, CaseIterable, Codable, Equatable {
    case travel = "여행여행"
    case food = "음식"
    case sports = "운동운동운동"
    case study = "공부"
    case hobby = "취미취미취미"
    case culture = "문화"
    
    var icon: String {
        switch self {
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .sports: return "figure.run"
        case .study: return "book.fill"
        case .hobby: return "paintbrush.fill"
        case .culture: return "theatermasks.fill"
        }
    }
}
