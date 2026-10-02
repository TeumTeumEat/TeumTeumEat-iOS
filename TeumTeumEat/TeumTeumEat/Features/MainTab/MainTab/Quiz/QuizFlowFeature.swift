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
    /// 퀴즈 흐름의 단계 (현재 단계 = 현재 화면 상태)
    /// 단계가 바뀌면 이전 단계 화면의 effect는 자동으로 취소됨
    @Reducer
    enum Step {
        case summary(ContentSummaryFeature)
        case quizGuide(QuizGuideFeature)
        case quiz(QuizFeature)
        case result(QuizResultFeature)
        case detailResult(QuizDetailResultFeature)
        case reviewSummary(QuizReviewSummaryFeature)
        case complete(QuizCompleteFeature)
        case subjectComplete(QuizSubjectCompleteFeature)
    }

    /// 주제 완료 화면에서 띄우는 새 주제 추가 화면
    @Reducer
    enum Destination {
        case addSubject(AddSubjectFlowFeature)
    }

    @ObservableState
    struct State: Equatable {
        var step: Step.State

        // 단계 사이에 공유하는 값
        var quizzes: [UserQuiz]
        var isQuizGuideSeen: Bool
        var summaryText: String = ""
        var submitResults: [Int: SubmitQuizAnswerData] = [:]

        @Presents var destination: Destination.State?

        init(
            quizzes: [UserQuiz],
            summaryData: ContentSummaryFeature.State,
            isQuizGuideSeen: Bool
        ) {
            self.quizzes = quizzes
            self.isQuizGuideSeen = isQuizGuideSeen
            self.step = .summary(summaryData)
        }
    }

    enum Action {
        case step(Step.Action)
        case destination(PresentationAction<Destination.Action>)
        case completeSetResponse(Result<Void, Error>)
        case fetchStatusForCompletionResponse(Result<UserQuizStatusData, Error>)
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

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Scope(state: \.step, action: \.step) {
            Step.body
        }

        Reduce { state, action in
            switch action {
            // MARK: - Summary → QuizGuide / Quiz
            case .step(.summary(.delegate(.startQuiz(let quizzes, _)))):
                if case let .summary(summary) = state.step {
                    state.summaryText = summary.summaryText  // 결과 화면의 "글 보기"에서 사용
                }
                state.quizzes = quizzes  // ContentSummary에서 로드한 실제 퀴즈 목록 저장
                if !state.isQuizGuideSeen {
                    state.step = .quizGuide(QuizGuideFeature.State())
                    Log.quiz.debug("QuizFlow: 퀴즈 가이드로 이동 (isQuizGuideSeen=false)")
                    return .none
                }
                return startQuiz(&state)

            case .step(.summary(.delegate(.cancelled))):
                Log.quiz.debug("QuizFlow: ContentSummary에서 취소")
                return .send(.delegate(.cancelled))

            case .step(.quizGuide(.delegate(.startQuiz))):
                return startQuiz(&state)

            case .completeSetResponse(.success):
                Log.quiz.debug("[QuizFlow] complete-set 성공")
                return .none

            case .completeSetResponse(.failure(let error)):
                Log.quiz.error("[QuizFlow] complete-set 실패: \(error)")
                return .none

            // MARK: - Quiz → Result
            case .step(.quiz(.delegate(.dismissed))):
                Log.quiz.debug("QuizFlow: 퀴즈 뒤로가기 → 취소")
                return .send(.delegate(.cancelled))

            case .step(.quiz(.delegate(.completed))):
                if case let .quiz(quizState) = state.step {
                    state.submitResults = quizState.submitResults
                }
                let correctCount = state.submitResults.values.filter { $0.isCorrect }.count
                AnalyticsManager.logQuizComplete(quizCount: state.quizzes.count, correctCount: correctCount)

                state.step = .result(QuizResultFeature.State(
                    submitResults: state.submitResults,
                    totalQuizCount: state.quizzes.count
                ))
                Log.quiz.debug("QuizFlow: 결과 화면으로 이동")
                return .none

            // MARK: - Result
            case .step(.result(.delegate(.showDetailResults))):
                state.step = .detailResult(makeDetailResultState(state))
                Log.quiz.debug("QuizFlow: 상세 결과로 이동")
                return .none

            case .step(.result(.delegate(.navigateToHome))):
                Log.quiz.debug("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))

            case .step(.result(.delegate(.navigateToHistory))):
                Log.quiz.debug("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))

            // MARK: - DetailResult → ReviewSummary (글 보기)
            case .step(.detailResult(.delegate(.showReviewSummary))):
                state.step = .reviewSummary(QuizReviewSummaryFeature.State(summaryText: state.summaryText))
                Log.quiz.debug("QuizFlow: 요약본 다시 보기로 이동")
                return .none

            // ReviewSummary → 뒤로가기 (DetailResult로, 공유 값으로 다시 생성)
            case .step(.reviewSummary(.delegate(.back))):
                state.step = .detailResult(makeDetailResultState(state))
                Log.quiz.debug("QuizFlow: 상세 결과로 복귀")
                return .none

            // MARK: - DetailResult → Complete or SubjectComplete (다음으로)
            case .step(.detailResult(.delegate(.showComplete))):
                return .run { send in
                    let result = await Result { try await apiClient.fetchUserQuizStatus() }
                    await send(.fetchStatusForCompletionResponse(result))
                }

            case .fetchStatusForCompletionResponse(.success(let status)):
                if status.isCompleted {
                    state.step = .subjectComplete(QuizSubjectCompleteFeature.State())
                    Log.quiz.debug("QuizFlow: 주제 완료 화면으로 이동")
                } else {
                    state.step = .complete(QuizCompleteFeature.State())
                    Log.quiz.debug("QuizFlow: 일반 완료 화면으로 이동")
                }
                return .none

            case .fetchStatusForCompletionResponse(.failure(let error)):
                Log.quiz.error("QuizFlow: status 조회 실패, 일반 완료 화면으로 fallback: \(error)")
                state.step = .complete(QuizCompleteFeature.State())
                return .none

            // MARK: - Complete / SubjectComplete
            case .step(.complete(.delegate(.navigateToHome))),
                 .step(.subjectComplete(.delegate(.navigateToHome))):
                Log.quiz.debug("QuizFlow: 홈으로 이동")
                return .send(.delegate(.completed(destination: .home)))

            case .step(.complete(.delegate(.navigateToHistory))):
                Log.quiz.debug("QuizFlow: 히스토리로 이동")
                return .send(.delegate(.completed(destination: .history)))

            // SubjectComplete → 새 주제 추가 (QuizFlow 내부에서 띄움)
            case .step(.subjectComplete(.delegate(.navigateToFileUpload))):
                state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .fileUpload))
                return .none

            case .step(.subjectComplete(.delegate(.navigateToCategory))):
                state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
                return .none

            // 새 주제 추가 완료 → 홈으로
            case .destination(.presented(.addSubject(.delegate(.completed)))):
                state.destination = nil
                return .send(.delegate(.completed(destination: .home)))

            // 새 주제 추가 취소 → 주제 완료 화면으로 복귀
            case .destination(.presented(.addSubject(.delegate(.cancelled)))):
                state.destination = nil
                return .none

            case .step, .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    /// 퀴즈 시작 (Summary / QuizGuide 공통) - 일일 퀴즈 횟수 차감(complete-set) 포함
    private func startQuiz(_ state: inout State) -> Effect<Action> {
        // 퀴즈 로딩 실패 등으로 목록이 비어 있으면 빈 퀴즈 화면으로 진입하지 않음
        guard !state.quizzes.isEmpty else {
            Log.quiz.error("[QuizFlow] 퀴즈가 없어 시작 불가 - completeQuizSet 호출 건너뜀")
            return .none
        }
        state.step = .quiz(QuizFeature.State(quizzes: state.quizzes.map { Quiz(from: $0) }))
        AnalyticsManager.logQuizStart(quizCount: state.quizzes.count)
        Log.quiz.debug("QuizFlow: 퀴즈 시작 - complete-set 호출")
        return .run { send in
            await send(.completeSetResponse(Result { try await apiClient.completeQuizSet() }))
        }
    }

    private func makeDetailResultState(_ state: State) -> QuizDetailResultFeature.State {
        QuizDetailResultFeature.State(
            quizzes: state.quizzes,
            submitResults: state.submitResults,
            totalQuizCount: state.quizzes.count
        )
    }
}

extension QuizFlowFeature.Step.State: Equatable {}
extension QuizFlowFeature.Destination.State: Equatable {}

// MARK: - View
struct QuizFlowView: View {
    @Bindable var store: StoreOf<QuizFlowFeature>

    var body: some View {
        Group {
            switch store.scope(state: \.step, action: \.step).case {
            case let .summary(summaryStore):
                ContentSummaryView(store: summaryStore)

            case let .quizGuide(quizGuideStore):
                QuizGuideView(store: quizGuideStore)

            case let .quiz(quizStore):
                QuizView(store: quizStore)

            case let .result(resultStore):
                QuizResultView(store: resultStore)

            case let .detailResult(detailResultStore):
                QuizDetailResultView(store: detailResultStore)

            case let .reviewSummary(reviewSummaryStore):
                QuizReviewSummaryView(store: reviewSummaryStore)

            case let .complete(completeStore):
                QuizCompleteView(store: completeStore)

            case let .subjectComplete(subjectCompleteStore):
                SubjectFinView(store: subjectCompleteStore)
            }
        }
        // 단계 전환 시 opacity 애니메이션을 쓰면 fullScreenCover 위에서 화면이 검게 번쩍이므로 즉시 전환
        .fullScreenCover(
            item: $store.scope(state: \.destination?.addSubject, action: \.destination.addSubject)
        ) { addSubjectStore in
            AddSubjectFlowView(store: addSubjectStore)
        }
    }
}



import SwiftUI
import ComposableArchitecture
import WidgetKit

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
                    if let userDefaults = UserDefaults(suiteName: "group.com.TeumTeumEat") {
                        userDefaults.set(true, forKey: "widget_studiedToday")
                    }
                    WidgetCenter.shared.reloadAllTimelines()
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

            Image("char_exited_quiz_finish")
                .resizable()
                .scaledToFit()
                .frame(height: 240)

            Text("\(store.correctCount)문제를 맞췄어요!")
                .font(Font.custom("Pretendard-SemiBold", size: 30))
                .foregroundColor(.black)
                .padding(.top, 24)

            Text("아래 버튼을 눌러\n정답과 해설을 확인해보세요")
                .font(.body2_regular_16)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()

            // 결과 보기 버튼
            Button {
                store.send(.showDetailResultsButtonTapped)
            } label: {
                Text("결과 보기")
                    .btBold20_24()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
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
                .font(.t_bold_20)
                .foregroundColor(.black)
                .padding(.bottom, 32)

            // 채점하러 가기 버튼
            Button(action: onGradeButtonTapped) {
                Text("채점하러 가기")
                    .btSemiBold20_24()
                    .foregroundColor(Color(hex: "2B8FFF"))
                    .padding(.horizontal, 22.5)
                    .padding(.vertical, 18)
                    .background(Color(hex: "EAF4FF"))
                    .cornerRadius(16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 426)
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
                Log.quiz.debug("QuizDetailResult: 글 보기 → 요약본으로")
                return .send(.delegate(.showReviewSummary))
                
            case .nextButtonTapped:
                Log.quiz.debug("QuizDetailResult: 다음으로 → 완료 화면으로")
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
            Text("요약 글 보기")
                .btSemiBold20_24()
                .foregroundColor(Color(hex: "2B8FFF"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "EAF4FF"))
                .cornerRadius(16)
        }
    }
    
    // 다음으로 버튼
    private var nextButton: some View {
        Button {
            store.send(.nextButtonTapped)
        } label: {
            Text("다음으로")
                .btSemiBold20_24()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(16)
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
