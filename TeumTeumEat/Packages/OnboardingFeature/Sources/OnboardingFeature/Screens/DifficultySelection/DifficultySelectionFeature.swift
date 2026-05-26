//
//  DifficultySelectionFeature .swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct DifficultySelectionFeature {
    public init() {}
    public static let promptOptions: [String] = [
        "출퇴근길에 가볍게 풀 수 있게 만들어주세요",
        "기초부터 차근차근 개념을 익히고 싶어요",
        "최신 트렌드나 뉴스 위주로 구성해주세요",
        "면접에 도움이 되는 내용으로 만들어주세요",
        "시험 대비용 문제 위주로 만들어주세요",
        "실무에서 바로 쓸 수 있게 구성해주세요",
        "이론보다 예시 중심으로 배우고 싶어요",
        "헷갈리기 쉬운 개념을 비교/정리해주세요",
        "짧고 핵심만 담긴 상식 위주로 구성해주세요",
        "심화 개념까지 깊이 있게 다뤄주세요"
    ]

    @ObservableState
    public struct State: Equatable {
        public var selectedDifficulty: Difficulty?
        public var isDifficultyPickerPresented = false
        public var isPromptPickerPresented = false
        public var customPrompt: String = ""

        public var canProceed: Bool {
            selectedDifficulty != nil
        }

        public var difficultyText: String {
            guard let difficulty = selectedDifficulty else { return "난이도 선택" }
            return difficulty.rawValue
        }

        public init() {}

        public enum Difficulty: String, CaseIterable, Codable, Equatable {
            case easy = "하"
            case normal = "중"
            case hard = "상"
            
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
    
    public enum Action {
        case backTapped
        case difficultyButtonTapped
        case difficultySelected(State.Difficulty)
        case difficultyPickerDismissed
        case promptButtonTapped
        case promptOptionSelected(String?)
        case promptPickerDismissed
        case nextTapped
    }

    public var body: some ReducerOf<Self> {
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
                
            case .promptButtonTapped:
                state.isPromptPickerPresented = true
                return .none

            case let .promptOptionSelected(prompt):
                state.customPrompt = prompt ?? ""
                state.isPromptPickerPresented = false
                return .none

            case .promptPickerDismissed:
                state.isPromptPickerPresented = false
                return .none

            case .nextTapped:
                return .none
            }
        }
    }
}
