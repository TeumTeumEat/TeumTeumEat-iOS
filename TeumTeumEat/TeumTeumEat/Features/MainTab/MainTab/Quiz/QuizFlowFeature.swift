//
//  QuizFlowFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizFlowFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .summary
        var contentSummary: ContentSummaryFeature.State = .init()
        var quiz: QuizFeature.State?
        var result: QuizResultFeature.State?
        
        enum Step {
            case summary    // 요약 화면
            case quiz       // 퀴즈 화면
            case result     // 결과 화면
        }
    }
    
    enum Action {
        case contentSummary(ContentSummaryFeature.Action)
        case quiz(QuizFeature.Action)
        case result(QuizResultFeature.Action)
        case delegate(Delegate)
    }
    
    enum Delegate {
        case completed(destination: CompletionDestination)
        case cancelled
        
        enum CompletionDestination {
            case home
            case history
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.contentSummary, action: \.contentSummary) {
            ContentSummaryFeature()
        }
        
        Reduce { state, action in
            switch action {
            // ContentSummary 관련
            case .contentSummary(.delegate(.startQuiz)):
                // 퀴즈 시작
                state.currentStep = .quiz
                state.quiz = QuizFeature.State()
                print("QuizFlow: 퀴즈 화면으로 이동")
                return .none
                
            case .contentSummary(.delegate(.cancelled)):
                // 취소 - 홈으로
                print("QuizFlow: 취소됨")
                return .send(.delegate(.cancelled))
                
            // Quiz 관련 (나중에 구현)
            case .quiz(.delegate(.completed)):
                state.currentStep = .result
                state.result = QuizResultFeature.State()
                print("QuizFlow: 결과 화면으로 이동")
                return .none
                
            // Result 관련 (나중에 구현)
            case .result(.delegate(.navigateToHome)):
                print("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))
                
            case .result(.delegate(.navigateToHistory)):
                print("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))
                
            case .contentSummary, .quiz, .result, .delegate:
                return .none
            }
        }
        .ifLet(\.quiz, action: \.quiz) {
            QuizFeature()
        }
        .ifLet(\.result, action: \.result) {
            QuizResultFeature()
        }
    }
}

// MARK: - View
struct QuizFlowView: View {
    let store: StoreOf<QuizFlowFeature>
    
    var body: some View {
        Group {
            switch store.currentStep {
            case .summary:
                ContentSummaryView(
                    store: store.scope(
                        state: \.contentSummary,
                        action: \.contentSummary
                    )
                )
                
            case .quiz:
                if let quizStore = store.scope(state: \.quiz, action: \.quiz) {
                    QuizView(store: quizStore)
                }
                
            case .result:
                if let resultStore = store.scope(state: \.result, action: \.result) {
                    QuizResultView(store: resultStore)
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.currentStep)
    }
}



import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizFeature {
    @ObservableState
    struct State: Equatable {
        // TODO: 나중에 실제 퀴즈 데이터 추가
    }
    
    enum Action {
        case delegate(Delegate)
    }
    
    enum Delegate {
        case completed
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizView: View {
    let store: StoreOf<QuizFeature>
    
    var body: some View {
        VStack {
            Text("퀴즈 화면 (임시)")
                .font(.system(size: 24, weight: .bold))
            
            Button("완료 (임시)") {
                store.send(.delegate(.completed))
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}


import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizResultFeature {
    @ObservableState
    struct State: Equatable {
        // TODO: 나중에 실제 결과 데이터 추가
    }
    
    enum Action {
        case homeButtonTapped
        case historyButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case navigateToHome
        case navigateToHistory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .homeButtonTapped:
                return .send(.delegate(.navigateToHome))
                
            case .historyButtonTapped:
                return .send(.delegate(.navigateToHistory))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizResultView: View {
    let store: StoreOf<QuizResultFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("퀴즈 결과 (임시)")
                .font(.system(size: 24, weight: .bold))
            
            HStack(spacing: 20) {
                Button("홈으로") {
                    store.send(.homeButtonTapped)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("히스토리로") {
                    store.send(.historyButtonTapped)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}
