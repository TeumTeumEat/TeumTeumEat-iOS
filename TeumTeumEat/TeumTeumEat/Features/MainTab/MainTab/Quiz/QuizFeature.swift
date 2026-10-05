//
//  QuizFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

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
        case backTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case completed
        case dismissed
    }
    
    @Dependency(\.quizClient) var quizClient
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
                        let result = try await quizClient.submitQuizAnswer(
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
                Log.quiz.debug("답안 제출 성공 - 정답: \(result.isCorrect)")
                
                // 애니메이션 시작
                return .run { send in
                    try await Task.sleep(for: .milliseconds(700))
                    await send(.animationCompleted)
                }
                
            case .submitAnswerResponse(.failure(let error)):
                state.isSubmitting = false
                Log.quiz.error("답안 제출 실패: \(error)")
                
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

            case .backTapped:
                return .send(.delegate(.dismissed))

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

// MARK: - Card Page Placement Layout

/// 짧은 카드는 참고 위치 유지, 긴 카드는 하단 여백을 확보하며 위로 이동
private struct QuizCardPlacement: Layout {
    let preferredTop: CGFloat
    let bottomInset: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let card = subviews.first else { return }
        let cardProposal = ProposedViewSize(width: bounds.width, height: nil)
        let size = card.sizeThatFits(cardProposal)
        let top = max(0, min(preferredTop, bounds.height - size.height - bottomInset))
        card.place(
            at: CGPoint(x: bounds.midX, y: bounds.minY + top),
            anchor: .top,
            proposal: cardProposal
        )
    }
}

// MARK: - Quiz View

struct QuizView: View {
    let store: StoreOf<QuizFeature>

    var body: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 360
            // 진행바 영역: top(12) + HStack(44) + bottom(56) = 112pt
            let topAreaHeight: CGFloat = 112
            // 흰 카드 최대 높이 = 전체 - 진행바 - 뒤카드 드러남(34s) - 하단 여백(20s)
            let maxCardHeight = proxy.size.height - topAreaHeight - 34 * s - 20 * s
            // 참고 이미지(360×812)에서 맨 뒤 카드 y=190 → 실제 화면 비율 환산
            let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let referenceRearTop = fullHeight * (190.0 / 812.0) - proxy.safeAreaInsets.top
            let preferredCardTop = max(0, referenceRearTop - topAreaHeight)

            VStack(spacing: 0) {
                // 상단 진행 상황
                if !store.isCompleted {
                    HStack(spacing: 12) {
                        Button { store.send(.backTapped) } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                        }
                        TTEProgressBar(
                            currentStep: store.currentIndex + 1,
                            totalSteps: store.quizzes.count
                        )
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 56)
                }

                // 카드 영역
                Group {
                    if store.isCompleted {
                        // 완료 카드
                        VStack {
                            CompletionCardView(
                                onGradeButtonTapped: { store.send(.gradeButtonTapped) }
                            )
                            .frame(height: 426)
                            .padding(.horizontal, 20)
                            .padding(.top, 120)
                            .transition(.scale.combined(with: .opacity))
                            Spacer()
                        }
                    } else if let currentQuiz = store.currentQuiz {
                        quizCardArea(
                            quiz: currentQuiz,
                            s: s,
                            maxCardHeight: maxCardHeight,
                            preferredCardTop: preferredCardTop
                        )
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.isCompleted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(hex: "F5F5F5"))
    }

    @ViewBuilder
    private func quizCardArea(quiz: Quiz, s: CGFloat, maxCardHeight: CGFloat, preferredCardTop: CGFloat) -> some View {
        switch quiz.type {
        case .multipleChoice:
            // TTEMultipleChoiceCard에 뒤쪽 카드 내장 → 외부 스택 불필요
            QuizCardPlacement(preferredTop: preferredCardTop, bottomInset: 20 * s) {
                quizCardContent(quiz: quiz, availableWidth: 360 * s, maxCardHeight: maxCardHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ox:
            // TTEQuizCard에 뒤쪽 카드 내장 → 외부 스택 불필요
            QuizCardPlacement(preferredTop: preferredCardTop, bottomInset: 20 * s) {
                quizCardContent(quiz: quiz, availableWidth: 360 * s, maxCardHeight: maxCardHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func quizCardContent(quiz: Quiz, availableWidth: CGFloat, maxCardHeight: CGFloat) -> some View {
        QuizCardView(
            quiz: quiz,
            quizNumber: store.currentIndex + 1,
            availableWidth: availableWidth,
            maxCardHeight: maxCardHeight,
            selectedAnswer: Binding(
                get: { store.selectedAnswers[store.currentIndex] ?? .none },
                set: { _ in }
            ),
            onAnswerSelected: { store.send(.answerSelected($0)) }
        )
        .rotationEffect(getRotation(direction: store.swipeDirection))
        .offset(getOffset(direction: store.swipeDirection))
        .opacity(store.isAnimating ? 0 : 1)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.swipeDirection)
    }

    private func getRotation(direction: QuizFeature.SwipeDirection?) -> Angle {
        switch direction {
        case .left:  return .degrees(-15)
        case .right: return .degrees(15)
        case .down, .none: return .degrees(0)
        }
    }

    private func getOffset(direction: QuizFeature.SwipeDirection?) -> CGSize {
        switch direction {
        case .left:  return CGSize(width: -500, height: 100)
        case .right: return CGSize(width: 500, height: 100)
        case .down:  return CGSize(width: 0, height: 800)
        case .none:  return .zero
        }
    }
}

// MARK: - Quiz Card View

struct QuizCardView: View {
    let quiz: Quiz
    let quizNumber: Int
    let availableWidth: CGFloat
    let maxCardHeight: CGFloat
    @Binding var selectedAnswer: QuizAnswer
    let onAnswerSelected: (QuizAnswer) -> Void

    var body: some View {
        switch quiz.type {
        case .ox:
            TTEQuizCard(
                availableWidth: availableWidth,
                maxCardHeight: maxCardHeight,
                questionNumber: quizNumber,
                question: quiz.question,
                selectedAnswer: $selectedAnswer,
                onAnswerSelected: onAnswerSelected
            )

        case .multipleChoice:
            TTEMultipleChoiceCard(
                availableWidth: availableWidth,
                maxCardHeight: maxCardHeight,
                questionNumber: quizNumber,
                question: quiz.question,
                choices: quiz.choices ?? [],
                selectedChoice: Binding(
                    get: {
                        if case .choice(let index) = selectedAnswer { return index }
                        return nil
                    },
                    set: { if let index = $0 { selectedAnswer = .choice(index) } }
                ),
                onChoiceSelected: { onAnswerSelected(.choice($0)) }
            )
        }
    }
}
