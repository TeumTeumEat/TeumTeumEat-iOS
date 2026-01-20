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
        var detailResult: QuizDetailResultFeature.State?
        var reviewSummary: QuizReviewSummaryFeature.State?
        var complete: QuizCompleteFeature.State?
        
        enum Step {
            case summary
            case quizGuide
            case quiz
            case result
            case detailResult
            case reviewSummary
            case complete
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
        case detailResult(QuizDetailResultFeature.Action)
        case reviewSummary(QuizReviewSummaryFeature.Action)
        case complete(QuizCompleteFeature.Action)
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
            case .contentSummary(.delegate(.startQuiz(let quizzes, let isFirstTime))):
                if isFirstTime {
                    state.currentStep = .quizGuide
                    state.quizGuide = QuizGuideFeature.State()
                    print("QuizFlow: 퀴즈 가이드로 이동")
                } else {
                    state.currentStep = .quiz
                    let convertedQuizzes = quizzes.map { Quiz(from: $0) }
                    state.quiz = QuizFeature.State(quizzes: convertedQuizzes)
                    print("QuizFlow: 퀴즈로 바로 이동")
                }
                return .none
                
            case .contentSummary(.delegate(.cancelled)):
                print("QuizFlow: ContentSummary에서 취소")
                return .send(.delegate(.cancelled))
                
            case .quizGuide(.delegate(.startQuiz)):
                state.currentStep = .quiz
                let convertedQuizzes = state.quizzes.map { Quiz(from: $0) }
                state.quiz = QuizFeature.State(quizzes: convertedQuizzes)
                print("QuizFlow: 안내 완료, 퀴즈 시작")
                return .none
                
            case .quiz(.delegate(.completed)):
                state.currentStep = .result
                
                let quizState = state.quiz
                state.result = QuizResultFeature.State(
                    submitResults: quizState?.submitResults ?? [:],
                    totalQuizCount: state.quizzes.count
                )
                print("QuizFlow: 결과 화면으로 이동")
                return .none
                
            case .result(.delegate(.showDetailResults)):
                state.currentStep = .detailResult
                
                let resultState = state.result
                state.detailResult = QuizDetailResultFeature.State(
                    quizzes: state.quizzes,
                    submitResults: resultState?.submitResults ?? [:],
                    totalQuizCount: state.quizzes.count
                )
                print("QuizFlow: 상세 결과로 이동")
                return .none
                
            case .result(.delegate(.navigateToHome)):
                print("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))
                
            case .result(.delegate(.navigateToHistory)):
                print("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))
                
            // DetailResult → ReviewSummary (글 보기)
            case .detailResult(.delegate(.showReviewSummary)):
                state.currentStep = .reviewSummary
                state.reviewSummary = QuizReviewSummaryFeature.State(
                    summaryText: state.contentSummary.summaryText
                )
                print("QuizFlow: 요약본 다시 보기로 이동")
                return .none
                
            // DetailResult → Complete (다음으로)
            case .detailResult(.delegate(.showComplete)):
                state.currentStep = .complete
                state.complete = QuizCompleteFeature.State()
                print("QuizFlow: 완료 화면으로 이동")
                return .none
                
            // ReviewSummary → 뒤로가기 (DetailResult로)
            case .reviewSummary(.delegate(.back)):
                state.currentStep = .detailResult
                print("QuizFlow: 상세 결과로 복귀")
                return .none
                
            // Complete → 홈으로
            case .complete(.delegate(.navigateToHome)):
                print("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))
                
            // Complete → 히스토리로
            case .complete(.delegate(.navigateToHistory)):
                print("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))
                
            case .contentSummary, .quizGuide, .quiz, .result, .detailResult, .reviewSummary, .complete, .delegate:
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
        .ifLet(\.detailResult, action: \.detailResult) {
            QuizDetailResultFeature()
        }
        .ifLet(\.reviewSummary, action: \.reviewSummary) {
            QuizReviewSummaryFeature()
        }
        .ifLet(\.complete, action: \.complete) {
            QuizCompleteFeature()
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
                
            case .detailResult:
                if let detailResultStore = store.scope(state: \.detailResult, action: \.detailResult) {
                    QuizDetailResultView(store: detailResultStore)
                }
                
            case .reviewSummary:
                if let reviewSummaryStore = store.scope(state: \.reviewSummary, action: \.reviewSummary) {
                    QuizReviewSummaryView(store: reviewSummaryStore)
                }
                
            case .complete: 
                if let completeStore = store.scope(state: \.complete, action: \.complete) {
                    QuizCompleteView(store: completeStore)
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
        .background(.white)
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
        var submitResults: [Int: SubmitQuizAnswerData]
        var totalQuizCount: Int

        var correctCount: Int {
            submitResults.values.filter { $0.isCorrect }.count
        }
        
        var incorrectCount: Int {
            totalQuizCount - correctCount
        }
        
        var score: Int {
            guard totalQuizCount > 0 else { return 0 }
            return (correctCount * 100) / totalQuizCount
        }
        
        init(submitResults: [Int: SubmitQuizAnswerData], totalQuizCount: Int) {
            self.submitResults = submitResults
            self.totalQuizCount = totalQuizCount
        }
    }
    
    enum Action {
        case showDetailResultsButtonTapped
        case homeButtonTapped
        case historyButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case showDetailResults
        case navigateToHome
        case navigateToHistory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showDetailResultsButtonTapped:
                return .send(.delegate(.showDetailResults))
                
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
        VStack(spacing: 0) {
            Spacer()
            
            //  결과 요약
            VStack(spacing: 16) {
                // 정답 개수 표시
                Text("\(store.totalQuizCount)문제 중 \(store.correctCount)문제를 맞췄어요!")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundStyle(.black)
                
                // 점수 표시 (선택사항)
                Text("\(store.score)점")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(.blue500)
                
                // 정답/오답 표시
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("정답")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(store.correctCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 8) {
                        Text("오답")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(store.incorrectCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 20)
            }
            
            Spacer()
            
            // 결과 보기 버튼
            Button {
                store.send(.showDetailResultsButtonTapped)
            } label: {
                Text("결과 보기")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(.white)
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


@Reducer
struct QuizDetailResultFeature {
    @ObservableState
    struct State: Equatable {
        var quizzes: [UserQuiz]
        var submitResults: [Int: SubmitQuizAnswerData]
        var totalQuizCount: Int
        
        // 정렬된 결과 리스트
        var sortedResults: [(index: Int, result: SubmitQuizAnswerData)] {
            submitResults
                .sorted { $0.key < $1.key }
                .map { (index: $0.key, result: $0.value) }
        }
        
        init(
            quizzes: [UserQuiz],
            submitResults: [Int: SubmitQuizAnswerData],
            totalQuizCount: Int
        ) {
            self.quizzes = quizzes
            self.submitResults = submitResults
            self.totalQuizCount = totalQuizCount
        }
    }
    
    enum Action {
        case reviewSummaryButtonTapped
        case nextButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case showReviewSummary
        case showComplete
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .reviewSummaryButtonTapped:
                print("QuizDetailResult: 글 보기 → 요약본으로")
                return .send(.delegate(.showReviewSummary))
                
            case .nextButtonTapped:
                print("QuizDetailResult: 다음으로 → 완료 화면으로")
                return .send(.delegate(.showComplete))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizDetailResultView: View {
    let store: StoreOf<QuizDetailResultFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Navigation Bar
                    navigationBar
                    
                    // 문제별 결과 리스트
                    resultsList
                }
                
                // 그라디언트 + 버튼
                bottomButtons
            }
        }
        .navigationBarHidden(true)
    }
    
    // Navigation Bar
    private var navigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                Text("오늘의 정답 확인")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.white)
    }
    
    // 결과 리스트
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<store.submitResults.count, id: \.self) { index in
                    if let result = store.submitResults[index] {
                        answerCardView(index: index, result: result)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 180)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
    }
    
    // 답안 카드
    private func answerCardView(index: Int, result: SubmitQuizAnswerData) -> some View {
        TTEAnswerCard(
            questionNumber: index + 1,
            question: getQuestionText(for: index),
            correctAnswer: result.correctAnswer,
            explanation: result.explanation,
            status: result.isCorrect ? .correct : .wrong
        )
    }
    
    // 하단 버튼 영역
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.8),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            
            buttonsRow
                .padding(.bottom, 34)
                .background(Color.white)
        }
    }
    
    // 버튼 Row
    private var buttonsRow: some View {
        HStack(spacing: 12) {
            reviewButton
            nextButton
        }
        .padding(.horizontal, 20)
    }
    
    // 글 보기 버튼
    private var reviewButton: some View {
        Button {
            store.send(.reviewSummaryButtonTapped)
        } label: {
            Text("글 보기")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }
    
    // 다음으로 버튼
    private var nextButton: some View {
        Button {
            store.send(.nextButtonTapped)
        } label: {
            Text("다음으로")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
    
    // 문제 텍스트 가져오기
    private func getQuestionText(for index: Int) -> String {
        guard index < store.quizzes.count else { return "" }
        return store.quizzes[index].question
    }
}

// 각 문제별 결과 아이템
struct QuizResultItemView: View {
    let questionNumber: Int
    let result: SubmitQuizAnswerData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 문제 번호 + 정답/오답
            HStack {
                Text("Q\(questionNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                if result.isCorrect {
                    Label("정답", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Label("오답", systemImage: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            // 정답 표시
            if !result.isCorrect {
                HStack(spacing: 8) {
                    Text("정답:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(result.correctAnswer)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            // 해설
            VStack(alignment: .leading, spacing: 4) {
                Text("해설")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text(result.explanation)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
