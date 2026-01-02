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
        var quizGuide: QuizGuideFeature.State?
        var quiz: QuizFeature.State?
        var result: QuizResultFeature.State?
        
        enum Step {
            case summary    // 요약 화면
            case quizGuide  // 안내 화면
            case quiz       // 퀴즈 화면
            case result     // 결과 화면
        }
    }
    
    enum Action {
        case contentSummary(ContentSummaryFeature.Action)
        case quizGuide(QuizGuideFeature.Action)
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
            // ContentSummary에서 퀴즈 시작
            case .contentSummary(.delegate(.startQuiz)):
                if state.contentSummary.isFirstTime {
                    // 처음이면 안내 화면으로
                    state.currentStep = .quizGuide
                    state.quizGuide = QuizGuideFeature.State()
                    print("QuizFlow: 퀴즈 안내 화면으로 이동")
                } else {
                    // 아니면 바로 퀴즈로
                    state.currentStep = .quiz
                    state.quiz = QuizFeature.State()
                    print("QuizFlow: 퀴즈 화면으로 바로 이동")
                }
                return .none
                
            case .contentSummary(.delegate(.cancelled)):
                print("QuizFlow: 취소됨")
                return .send(.delegate(.cancelled))
                
            // QuizGuide에서 퀴즈 시작
            case .quizGuide(.delegate(.startQuiz)):
                state.currentStep = .quiz
                state.quiz = QuizFeature.State()
                print("QuizFlow: 안내 완료, 퀴즈 시작")
                return .none
                
            // Quiz 완료
            case .quiz(.delegate(.completed)):
                state.currentStep = .result
                state.result = QuizResultFeature.State()
                print("QuizFlow: 결과 화면으로 이동")
                return .none
                
            // Result에서 홈으로
            case .result(.delegate(.navigateToHome)):
                print("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))
                
            // Result에서 히스토리로
            case .result(.delegate(.navigateToHistory)):
                print("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))
                
            case .contentSummary, .quizGuide, .quiz, .result, .delegate:
                return .none
            }
        }
        .ifLet(\.quizGuide, action: \.quizGuide) {
            QuizGuideFeature()
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
                
            case .quizGuide:
                if let quizGuideStore = store.scope(state: \.quizGuide, action: \.quizGuide) {
                    QuizGuideView(store: quizGuideStore)
                }
                
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
        var quizzes: [Quiz] = Quiz.mockData  // 퀴즈 데이터
        var currentIndex: Int = 0  // 현재 카드 인덱스
        var selectedAnswers: [Int: QuizAnswer] = [:]  // 선택된 답변들
        
        var currentQuiz: Quiz? {
            guard currentIndex < quizzes.count else { return nil }
            return quizzes[currentIndex]
        }
        
        var isLastQuiz: Bool {
            currentIndex == quizzes.count - 1
        }
    }
    
    enum Action {
        case answerSelected(QuizAnswer)
        case nextQuiz
        case delegate(Delegate)
    }
    
    enum Delegate {
        case completed
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .answerSelected(let answer):
                state.selectedAnswers[state.currentIndex] = answer
                print("답변 선택: Q\(state.currentIndex + 1) - \(answer)")
                
                // 자동으로 다음 문제로 (선택사항)
                return .send(.nextQuiz)
                
            case .nextQuiz:
                if state.isLastQuiz {
                    // 마지막 문제면 완료
                    return .send(.delegate(.completed))
                } else {
                    state.currentIndex += 1
                }
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Models
struct Quiz: Equatable, Identifiable {
    let id: Int
    let question: String
    let type: QuizType
    let choices: [String]?  // 객관식일 때만
    
    enum QuizType {
        case ox
        case multipleChoice
    }
    
    // Mock Data
    static let mockData: [Quiz] = [
        Quiz(
            id: 1,
            question: "이거는 저거일까?",
            type: .ox,
            choices: nil
        ),
        Quiz(
            id: 2,
            question: "MVP의 정의는 무엇인가요?",
            type: .multipleChoice,
            choices: [
                "최소 기능 제품",
                "최대 기능 제품",
                "평균 기능 제품",
                "표준 기능 제품"
            ]
        ),
        Quiz(
            id: 3,
            question: "TDD는 테스트 주도 개발이다?",
            type: .ox,
            choices: nil
        )
    ]
}

struct QuizView: View {
    let store: StoreOf<QuizFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 진행 상황
            HStack {
                Text("\(store.currentIndex + 1) / \(store.quizzes.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // 카드 영역
            ZStack(alignment: .top) {
                // 배경: 쌓인 카드 이미지 (밑에 깔림)
                Image("Group 244")
                    .resizable()
                    .scaledToFit()
                
                // 실제 카드 (위에 올라감)
                if let currentQuiz = store.currentQuiz {
                    QuizCardView(
                        quiz: currentQuiz,
                        selectedAnswer: Binding(
                            get: { store.selectedAnswers[store.currentIndex] ?? .none },
                            set: { _ in }
                        ),
                        onAnswerSelected: { answer in
                            store.send(.answerSelected(answer))
                        }
                    )
                    .frame(height: 426)
                    .padding(.top, 34)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 다음 문제 버튼
            Button(action: {
                store.send(.nextQuiz)
            }) {
                Text("다음 문제")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 34)
        }
    }
}

struct QuizCardView: View {
    let quiz: Quiz
    @Binding var selectedAnswer: QuizAnswer
    let onAnswerSelected: (QuizAnswer) -> Void
    
    var body: some View {
        switch quiz.type {
        case .ox:
            TTEQuizCard(
                questionNumber: quiz.id,
                question: quiz.question,
                selectedAnswer: $selectedAnswer,
                onAnswerSelected: onAnswerSelected
            )
            
        case .multipleChoice:
            TTEMultipleChoiceCard(
                questionNumber: quiz.id,
                question: quiz.question,
                choices: quiz.choices ?? [],
                selectedChoice: Binding(
                    get: {
                        if case .choice(let index) = selectedAnswer {
                            return index
                        }
                        return nil
                    },
                    set: { newValue in
                        if let index = newValue {
                            selectedAnswer = .choice(index)
                        }
                    }
                ),
                onChoiceSelected: { index in
                    onAnswerSelected(.choice(index))
                }
            )
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
