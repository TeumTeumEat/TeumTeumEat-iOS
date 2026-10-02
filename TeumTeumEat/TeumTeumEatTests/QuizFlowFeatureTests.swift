//
//  QuizFlowFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Testing
@testable import TeumTeumEat

@MainActor
struct QuizFlowFeatureTests {
    @Test("가이드를 아직 안 봤으면 요약 → 퀴즈 가이드로 이동한다")
    func startQuiz_guideNotSeen_goesToGuide() async {
        let store = TestStore(
            initialState: QuizFlowFeature.State(quizzes: [], summaryData: Fixture.summary(), isQuizGuideSeen: false)
        ) {
            QuizFlowFeature()
        }

        await store.send(.step(.summary(.delegate(.startQuiz(quizzes: Fixture.quizzes, isFirstTime: true))))) {
            $0.summaryText = "오늘의 요약"
            $0.quizzes = Fixture.quizzes
            $0.step = .quizGuide(QuizGuideFeature.State())
        }
    }

    @Test("가이드를 봤으면 바로 퀴즈로 이동하고 일일 퀴즈 횟수를 차감한다")
    func startQuiz_guideSeen_startsQuizAndCompletesSet() async {
        let store = TestStore(
            initialState: QuizFlowFeature.State(quizzes: [], summaryData: Fixture.summary(), isQuizGuideSeen: true)
        ) {
            QuizFlowFeature()
        } withDependencies: {
            $0.quizClient.completeQuizSet = {}
        }

        await store.send(.step(.summary(.delegate(.startQuiz(quizzes: Fixture.quizzes, isFirstTime: true))))) {
            $0.summaryText = "오늘의 요약"
            $0.quizzes = Fixture.quizzes
            $0.step = .quiz(QuizFeature.State(quizzes: Fixture.quizzes.map { Quiz(from: $0) }))
        }
        await store.receive(\.completeSetResponse)
    }

    @Test("퀴즈 목록이 비어 있으면 퀴즈 화면으로 진입하지 않고 횟수도 차감하지 않는다")
    func startQuiz_emptyQuizzes_staysOnSummary() async {
        let store = TestStore(
            initialState: QuizFlowFeature.State(quizzes: [], summaryData: Fixture.summary(), isQuizGuideSeen: true)
        ) {
            QuizFlowFeature()
        }
        // completeQuizSet을 override하지 않았으므로 호출되면 테스트 실패

        await store.send(.step(.summary(.delegate(.startQuiz(quizzes: [], isFirstTime: true))))) {
            $0.summaryText = "오늘의 요약"
        }
    }

    @Test("퀴즈를 마치면 채점 결과를 보관하고 결과 화면으로 이동한다")
    func quizCompleted_goesToResult() async {
        var state = QuizFlowFeature.State(quizzes: Fixture.quizzes, summaryData: Fixture.summary(), isQuizGuideSeen: true)
        var quizState = QuizFeature.State(quizzes: Fixture.quizzes.map { Quiz(from: $0) })
        quizState.submitResults = Fixture.submitResults
        state.step = .quiz(quizState)

        let store = TestStore(initialState: state) {
            QuizFlowFeature()
        }

        await store.send(.step(.quiz(.delegate(.completed)))) {
            $0.submitResults = Fixture.submitResults
            $0.step = .result(QuizResultFeature.State(submitResults: Fixture.submitResults, totalQuizCount: 2))
        }
    }

    @Test("결과 → 상세 결과 → 글 보기 → 뒤로가기 시 상세 결과가 동일하게 복원된다")
    func detailResult_reviewSummary_backRestoresDetail() async {
        var state = QuizFlowFeature.State(quizzes: Fixture.quizzes, summaryData: Fixture.summary(), isQuizGuideSeen: true)
        state.summaryText = "오늘의 요약"
        state.submitResults = Fixture.submitResults
        state.step = .result(QuizResultFeature.State(submitResults: Fixture.submitResults, totalQuizCount: 2))

        let store = TestStore(initialState: state) {
            QuizFlowFeature()
        }
        let detail = QuizDetailResultFeature.State(
            quizzes: Fixture.quizzes,
            submitResults: Fixture.submitResults,
            totalQuizCount: 2
        )

        await store.send(.step(.result(.delegate(.showDetailResults)))) {
            $0.step = .detailResult(detail)
        }
        await store.send(.step(.detailResult(.delegate(.showReviewSummary)))) {
            $0.step = .reviewSummary(QuizReviewSummaryFeature.State(summaryText: "오늘의 요약"))
        }
        await store.send(.step(.reviewSummary(.delegate(.back)))) {
            $0.step = .detailResult(detail)
        }
    }

    @Test("마지막 퀴즈 세트였으면 주제 완료 화면으로, 아니면 일반 완료 화면으로 이동한다")
    func showComplete_branchesOnGoalCompletion() async {
        var state = QuizFlowFeature.State(quizzes: Fixture.quizzes, summaryData: Fixture.summary(), isQuizGuideSeen: true)
        state.step = .detailResult(QuizDetailResultFeature.State(
            quizzes: Fixture.quizzes, submitResults: Fixture.submitResults, totalQuizCount: 2
        ))

        let completedStore = TestStore(initialState: state) {
            QuizFlowFeature()
        } withDependencies: {
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus(isCompleted: true) }
        }
        await completedStore.send(.step(.detailResult(.delegate(.showComplete))))
        await completedStore.receive(\.fetchStatusForCompletionResponse.success) {
            $0.step = .subjectComplete(QuizSubjectCompleteFeature.State())
        }

        let inProgressStore = TestStore(initialState: state) {
            QuizFlowFeature()
        } withDependencies: {
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus(isCompleted: false) }
        }
        await inProgressStore.send(.step(.detailResult(.delegate(.showComplete))))
        await inProgressStore.receive(\.fetchStatusForCompletionResponse.success) {
            $0.step = .complete(QuizCompleteFeature.State())
        }
    }
}
