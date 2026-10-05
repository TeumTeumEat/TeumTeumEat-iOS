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
        var documentType: DocumentType
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
            self.documentType = summaryData.documentType
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

    @Dependency(\.quizClient) var quizClient
    @Dependency(\.analyticsClient) var analyticsClient
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
                analyticsClient.log(.summaryAbandon(contentType: state.documentType.analyticsValue))
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
                if case let .quiz(quizState) = state.step {
                    analyticsClient.log(.quizAbandon(
                        questionIndex: quizState.currentIndex + 1,
                        quizCount: state.quizzes.count
                    ))
                }
                return .send(.delegate(.cancelled))

            case .step(.quiz(.delegate(.completed))):
                if case let .quiz(quizState) = state.step {
                    state.submitResults = quizState.submitResults
                }
                let correctCount = state.submitResults.values.filter { $0.isCorrect }.count
                analyticsClient.log(.quizComplete(quizCount: state.quizzes.count, correctCount: correctCount))

                state.step = .result(QuizResultFeature.State(
                    submitResults: state.submitResults,
                    totalQuizCount: state.quizzes.count
                ))
                Log.quiz.debug("QuizFlow: 결과 화면으로 이동")
                return .none

            // MARK: - Result
            case .step(.result(.delegate(.showDetailResults))):
                analyticsClient.log(.quizResultAction(action: "detail"))
                state.step = .detailResult(makeDetailResultState(state))
                Log.quiz.debug("QuizFlow: 상세 결과로 이동")
                return .none

            case .step(.result(.delegate(.navigateToHome))):
                Log.quiz.debug("QuizFlow: 홈으로 이동")
                analyticsClient.log(.quizResultAction(action: "home"))
                return .send(.delegate(.completed(destination: .home)))

            case .step(.result(.delegate(.navigateToHistory))):
                Log.quiz.debug("QuizFlow: 히스토리로 이동")
                analyticsClient.log(.quizResultAction(action: "history"))
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
                    let result = await Result { try await quizClient.fetchUserQuizStatus() }
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
                analyticsClient.log(.subjectAddStart(contentType: "document", source: "quiz_complete"))
                return .none

            case .step(.subjectComplete(.delegate(.navigateToCategory))):
                state.destination = .addSubject(AddSubjectFlowFeature.State(contentType: .category))
                analyticsClient.log(.subjectAddStart(contentType: "category", source: "quiz_complete"))
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
        analyticsClient.log(.quizStart(
            quizCount: state.quizzes.count,
            contentType: state.documentType.analyticsValue
        ))
        Log.quiz.debug("QuizFlow: 퀴즈 시작 - complete-set 호출")
        return .run { send in
            await send(.completeSetResponse(Result { try await quizClient.completeQuizSet() }))
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
