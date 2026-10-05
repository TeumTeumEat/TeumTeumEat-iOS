//
//  AnalyticsEventTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import OnboardingFeature
import Testing
@testable import TeumTeumEat

@MainActor
struct AnalyticsEventTests {
    @Test("퀴즈 시작 시 문제 수와 학습 유형을 기록한다")
    func quizStart_logsCountAndContentType() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(
            initialState: QuizFlowFeature.State(quizzes: [], summaryData: Fixture.summary(), isQuizGuideSeen: true)
        ) {
            QuizFlowFeature()
        } withDependencies: {
            $0.quizClient.completeQuizSet = {}
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.step(.summary(.delegate(.startQuiz(quizzes: Fixture.quizzes, isFirstTime: true)))))
        await store.finish()

        #expect(events.value == [.quizStart(quizCount: 2, contentType: "category")])
    }

    @Test("퀴즈 도중 나가면 몇 번째 문제에서 나갔는지 기록한다")
    func quizDismissed_logsAbandonWithQuestionIndex() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = QuizFlowFeature.State(quizzes: Fixture.quizzes, summaryData: Fixture.summary(), isQuizGuideSeen: true)
        var quizState = QuizFeature.State(quizzes: Fixture.quizzes.map { Quiz(from: $0) })
        quizState.currentIndex = 1
        state.step = .quiz(quizState)
        let store = TestStore(initialState: state) {
            QuizFlowFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.step(.quiz(.delegate(.dismissed))))
        await store.finish()

        #expect(events.value == [.quizAbandon(questionIndex: 2, quizCount: 2)])
    }

    @Test("온보딩에 진입하면 첫 단계(welcome)를 기록한다")
    func onboardingEntered_logsWelcomeStep() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = AppFeature.State()
        state.isShowingSplash = true
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.splash(.authenticationChecked(.authenticated(isOnboardingCompleted: false))))

        #expect(events.value == [.onboardingStepView(step: "welcome")])
    }

    @Test("온보딩 데이터를 Analytics 파라미터 값으로 변환한다")
    func onboardingData_analyticsValues() {
        var data = OnboardingData()
        data.contentType = .fileUpload
        data.difficulty = "상"
        #expect(data.analyticsContentType == "document")
        #expect(data.analyticsDifficulty == "hard")

        data.contentType = .category
        data.difficulty = nil
        #expect(data.analyticsContentType == "category")
        #expect(data.analyticsDifficulty == "unknown")
    }
}
