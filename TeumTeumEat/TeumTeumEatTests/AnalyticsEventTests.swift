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

    @Test("주제 추가 첫 단계에서 뒤로가면 학습 유형과 단계를 기록한다")
    func subjectAddBack_logsCancel() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: AddSubjectFlowFeature.State(contentType: .fileUpload)) {
            AddSubjectFlowFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.step(.fileUpload(.backTapped)))
        await store.finish()

        #expect(events.value == [.subjectAddCancel(contentType: "document", step: "file_upload")])
    }

    @Test("+ 메뉴에서 주제 추가를 시작하면 진입 경로와 함께 기록한다")
    func registerMenu_logsSubjectAddStart() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        let store = TestStore(initialState: MainTabFeature.State()) {
            MainTabFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.registerMenuItemTapped(.category))

        #expect(events.value == [.subjectAddStart(contentType: "category", source: "home_menu")])
    }

    @Test("주제 완료 알럿은 진행 중인 주제 조회 후 그 결과와 함께 기록한다")
    func goalCompleted_logsViewWithActiveSubjects() async {
        let events = LockIsolated<[AnalyticsEvent]>([])
        var state = HomeFeature.State()
        state.showGoalCompletedAlert = true
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.analyticsClient.log = { event in events.withValue { $0.append(event) } }
        }
        store.exhaustivity = .off

        await store.send(.fetchActiveGoalsResponse(.success([Fixture.goal(id: 2, categoryId: 20)])))

        #expect(events.value == [.goalCompleteView(hasActiveSubjects: true)])
    }

    @Test("현재 목표를 받으면 학습 유형 / 난이도를 사용자 속성으로 설정한다")
    func currentGoal_setsUserProperties() async {
        let properties = LockIsolated<[AnalyticsUserProperty]>([])
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.analyticsClient.setUserProperty = { property in properties.withValue { $0.append(property) } }
            $0.quizClient.fetchUserQuizStatus = { Fixture.quizStatus() }
        }
        store.exhaustivity = .off

        await store.send(.fetchCurrentGoalResponse(.success(Fixture.goal())))
        await store.finish()

        #expect(properties.value == [.contentType("category"), .difficulty("normal")])
    }

    @Test("난이도는 하·중·상 / EASY·MEDIUM·HARD 모두 같은 값으로 변환한다")
    func difficulty_mapsBothFormats() {
        #expect(AnalyticsValue.difficulty("하") == "easy")
        #expect(AnalyticsValue.difficulty("MEDIUM") == "normal")
        #expect(AnalyticsValue.difficulty("HARD") == "hard")
        #expect(AnalyticsValue.difficulty(nil) == "unknown")
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
