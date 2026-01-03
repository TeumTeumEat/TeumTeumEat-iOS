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
        var quizzes: [UserQuiz]
        var isFirstTime: Bool
        
        var currentStep: Step
        var contentSummary: ContentSummaryFeature.State
        var quizGuide: QuizGuideFeature.State?
        var quiz: QuizFeature.State?
        var result: QuizResultFeature.State?
        
        enum Step {
            case summary
            case quizGuide
            case quiz
            case result
        }
        
        init(
            quizzes: [UserQuiz],
            summaryData: ContentSummaryFeature.State,
            isFirstTime: Bool
        ) {
            self.quizzes = quizzes
            self.isFirstTime = isFirstTime
            self.currentStep = .summary
            self.contentSummary = summaryData
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
            case .contentSummary(.delegate(.startQuiz(let quizzes, let isFirstTime))):
                if isFirstTime {
                    // 처음이면 가이드로
                    state.currentStep = .quizGuide
                    state.quizGuide = QuizGuideFeature.State()
                    print("QuizFlow: 퀴즈 가이드로 이동")
                } else {
                    // 아니면 바로 퀴즈로
                    state.currentStep = .quiz
                    let convertedQuizzes = quizzes.map { Quiz(from: $0) }
                    state.quiz = QuizFeature.State(quizzes: convertedQuizzes)
                    print("QuizFlow: 퀴즈로 바로 이동")
                }
                return .none
                
            case .contentSummary(.delegate(.cancelled)):
                print("QuizFlow: ContentSummary에서 취소")
                return .send(.delegate(.cancelled))
                
            // QuizGuide에서 퀴즈 시작
            case .quizGuide(.delegate(.startQuiz)):
                state.currentStep = .quiz
                let convertedQuizzes = state.quizzes.map { Quiz(from: $0) }
                state.quiz = QuizFeature.State(quizzes: convertedQuizzes)
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
        var quizzes: [Quiz]
        var currentIndex: Int = 0
        var selectedAnswers: [Int: QuizAnswer] = [:]
        var submitResults: [Int: SubmitQuizAnswerData] = [:]
        var isAnimating: Bool = false
        var swipeDirection: SwipeDirection? = nil
        var isCompleted: Bool = false
        var isSubmitting: Bool = false
        
        var currentQuiz: Quiz? {
            guard currentIndex < quizzes.count else { return nil }
            return quizzes[currentIndex]
        }
        
        var isLastQuiz: Bool {
            currentIndex == quizzes.count - 1
        }
        
        init(quizzes: [Quiz]) {
            self.quizzes = quizzes
        }
    }
    
    enum SwipeDirection {
        case left   // O
        case right  // X
        case down   // 객관식
    }
    
    enum Action {
        case answerSelected(QuizAnswer)
        case submitAnswerResponse(Result<SubmitQuizAnswerData, Error>)
        case animationCompleted
        case gradeButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case completed
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .answerSelected(let answer):
                guard let currentQuiz = state.currentQuiz else { return .none }
                
                state.selectedAnswers[state.currentIndex] = answer
                state.isAnimating = true
                state.isSubmitting = true
                
                // 스와이프 방향 결정
                if currentQuiz.type == .ox {
                    state.swipeDirection = answer == .correct ? .left : .right
                } else {
                    state.swipeDirection = .down
                }
                
                // API 호출: 답안 제출
                let quizId = currentQuiz.id
                let userAnswer = convertAnswerToString(answer: answer, quiz: currentQuiz)
                
                return .run { send in
                    do {
                        let result = try await apiClient.submitQuizAnswer(
                            quizId: quizId,
                            userAnswer: userAnswer
                        )
                        await send(.submitAnswerResponse(.success(result)))
                    } catch {
                        await send(.submitAnswerResponse(.failure(error)))
                    }
                }
                
            case .submitAnswerResponse(.success(let result)):
                state.isSubmitting = false
                // 결과 저장
                state.submitResults[state.currentIndex] = result
                print("답안 제출 성공 - 정답: \(result.isCorrect)")
                
                // 애니메이션 시작
                return .run { send in
                    try await Task.sleep(for: .milliseconds(700))
                    await send(.animationCompleted)
                }
                
            case .submitAnswerResponse(.failure(let error)):
                state.isSubmitting = false
                print("답안 제출 실패: \(error)")
                
                // 일단 애니메이션은 계속 진행
                return .run { send in
                    try await Task.sleep(for: .milliseconds(700))
                    await send(.animationCompleted)
                }
                
                
            case .animationCompleted:
                state.isAnimating = false
                state.swipeDirection = nil
                
                if state.isLastQuiz {
                    state.isCompleted = true
                    return .none
                } else {
                    state.currentIndex += 1
                }
                return .none
                
            case .gradeButtonTapped:
                return .send(.delegate(.completed))
                
            case .delegate:
                return .none
            }
        }
    }
    private func convertAnswerToString(answer: QuizAnswer, quiz: Quiz) -> String {
            switch answer {
            case .correct:
                return "o"
            case .wrong:
                return "x"
            case .choice(let index):
                guard quiz.type == .multipleChoice,
                      let choices = quiz.choices,
                      index < choices.count else {
                    return ""
                }
                return choices[index]
            case .none:
                return ""
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
    
    init(from userQuiz: UserQuiz) {
        self.id = userQuiz.quizId
        self.question = userQuiz.question
        
        // type 변환
        if userQuiz.type == "OX" {
            self.type = .ox
            self.choices = nil
        } else {
            self.type = .multipleChoice
            self.choices = userQuiz.options.isEmpty ? nil : userQuiz.options
        }
    }
    
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
                // 배경: 완료 전에만 쌓인 이미지
                if !store.isCompleted {
                    Image("quiz_card_stack")
                        .resizable()
                        .scaledToFit()
                }
                
                // 카드
                if store.isCompleted {  // 완료 카드
                    CompletionCardView(
                        onGradeButtonTapped: {
                            store.send(.gradeButtonTapped)
                        }
                    )
                    .frame(height: 426)
                    .padding(.top, 0)  // 쌓인 이미지 없으니 padding 제거
                    .transition(.scale.combined(with: .opacity))
                    
                } else if let currentQuiz = store.currentQuiz {  // 퀴즈 카드
                    QuizCardView(
                        quiz: currentQuiz,
                        quizNumber: store.currentIndex + 1,
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
                    .rotationEffect(getRotation(direction: store.swipeDirection))
                    .offset(getOffset(direction: store.swipeDirection))
                    .opacity(store.isAnimating ? 0 : 1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.swipeDirection)
                }
            }
            .padding(.horizontal, 40)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.isCompleted)
            
            Spacer()
        }
    }
    
    func getRotation(direction: QuizFeature.SwipeDirection?) -> Angle {
        guard let direction = direction else { return .degrees(0) }
        
        switch direction {
        case .left:
            return .degrees(-15)
        case .right:
            return .degrees(15)
        case .down:
            return .degrees(0)
        }
    }
    
    func getOffset(direction: QuizFeature.SwipeDirection?) -> CGSize {
        guard let direction = direction else { return .zero }
        
        switch direction {
        case .left:
            return CGSize(width: -500, height: 100)
        case .right:
            return CGSize(width: 500, height: 100)
        case .down:
            return CGSize(width: 0, height: 800)
        }
    }
}

struct QuizCardView: View {
    let quiz: Quiz
    let quizNumber: Int
    @Binding var selectedAnswer: QuizAnswer
    let onAnswerSelected: (QuizAnswer) -> Void
    
    var body: some View {
        switch quiz.type {
        case .ox:
            TTEQuizCard(
                questionNumber: quizNumber,
                question: quiz.question,
                selectedAnswer: $selectedAnswer,
                onAnswerSelected: onAnswerSelected
            )
            
        case .multipleChoice:
            TTEMultipleChoiceCard(
                questionNumber: quizNumber,
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

struct CompletionCardView: View {
    let onGradeButtonTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            
            // 완료 이미지
            Image("character_complete 1")  // 완료 이미지
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(.bottom, 40)
            
            // 완료 텍스트
            Text("모든 퀴즈를 풀었어요!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 32)
            
            // 채점하러 가기 버튼
            Button(action: onGradeButtonTapped) {
                Text("채점하러 가기")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(minHeight: 426)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
