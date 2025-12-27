//
//  DifficultySelectionFeature .swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct DifficultySelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDifficulty: Difficulty?
        var isDifficultyPickerPresented = false
        var customPrompt: String = ""  // ← 추가
        
        var canProceed: Bool {
            selectedDifficulty != nil
        }
        
        var difficultyText: String {
            guard let difficulty = selectedDifficulty else { return "난이도 선택" }
            return difficulty.rawValue
        }
        
        var characterCount: Int {
            customPrompt.count
        }
        
        enum Difficulty: String, CaseIterable, Codable, Equatable {
            case easy = "쉬움"
            case normal = "보통"
            case hard = "어려움"
            
            var description: String {
                switch self {
                case .easy: return "초보자를 위한 난이도"
                case .normal: return "적당한 도전을 원하는 분"
                case .hard: return "높은 난이도를 원하는 분"
                }
            }
            
            var icon: String {
                switch self {
                case .easy: return "1.circle.fill"
                case .normal: return "2.circle.fill"
                case .hard: return "3.circle.fill"
                }
            }
        }
    }
    
    enum Action {
        case backTapped
        case difficultyButtonTapped
        case difficultySelected(State.Difficulty)
        case difficultyPickerDismissed
        case customPromptChanged(String)
        case nextTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .none
                
            case .difficultyButtonTapped:
                state.isDifficultyPickerPresented = true
                return .none
                
            case let .difficultySelected(difficulty):
                state.selectedDifficulty = difficulty
                state.isDifficultyPickerPresented = false
                return .none
                
            case .difficultyPickerDismissed:
                state.isDifficultyPickerPresented = false
                return .none
                
            case let .customPromptChanged(text):
                // 30자 제한
                if text.count <= 30 {
                    state.customPrompt = text
                }
                return .none
                
            case .nextTapped:
                return .none
            }
        }
    }
}
