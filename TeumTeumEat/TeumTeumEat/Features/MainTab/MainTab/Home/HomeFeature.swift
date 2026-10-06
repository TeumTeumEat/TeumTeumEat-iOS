//
//  HomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import CoreNetwork
import OnboardingFeature

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        var isTodayQuizCompleted: Bool = false
        var isGoalCompleted: Bool = false
        var showGoalCompletedAlert: Bool = false
        var hasActiveSubjects: Bool = false
        
        // API 관련 상태
        var currentGoal: GoalResponse?
        var quizStatus: UserQuizStatusData?
        var calendarData: CalendarHistoryData?
        
        var isLoading: Bool = false
        /// 목표 전환 가능성이 있을 때의 재조회 중 여부 (로딩 문구를 "간식 준비 중"으로 표시)
        var isPreparingSnack: Bool = false

        var showErrorOverlay: Bool = false
        var errorOverlayMessage: String = ""
        var isRetryingError: Bool = false
        var retryCount: Int = 0
        var showRetryToast: Bool = false

        var showCouponModal: Bool = false
        var isUsingCoupon: Bool = false
        var showAdInterruptedToast: Bool = false

        var availableQuizCount: Int {
            quizStatus?.availableQuizCount ?? 0
        }

        var canIssueCoupon: Bool {
            quizStatus?.canIssueCoupon ?? true
        }
        
        var currentSnackImage: String {
            guard !isGoalCompleted else { return "done" }
            guard !isTodayQuizCompleted else { return "done" }
            guard let goal = currentGoal else { return "burger" }

            let today = DateFormatters.yearMonthDay.string(from: Date())

            if goal.type == "CATEGORY" {
                let id = goal.category?.categoryId ?? goal.goalId
                return SnackImageMapper.snackImage(for: id, createdAt: today)
            }

            if goal.type == "DOCUMENT" {
                let id = goal.documentId ?? goal.goalId
                return SnackImageMapper.snackImage(for: id, createdAt: today)
            }

            return "burger"
        }
    }
    
    enum Action {
        case onAppear
        case goalMayHaveChanged
        
        case fetchCalendarHistoryResponse(Result<CalendarHistoryData, Error>)
        
        // Step 1: 현재 목표 조회
        case fetchCurrentGoalResponse(Result<GoalResponse, Error>)
        
        // Step 2: 퀴즈 상태 확인
        case fetchQuizStatusResponse(Result<UserQuizStatusData, Error>)
        
        case retryFromErrorOverlay
        case dismissErrorOverlay
        case retryToastDismissed
        case goalCompletedAlertDismissed
        case goalCompletedNewGoalTapped
        case goalCompletedSelectExistingTapped
        case fetchActiveGoalsResponse(Result<[GoalResponse], Error>)
        case settingTapped
        case leagueTapped
        case characterEatTapped
        case speechBubbleTapped
        case dismissCouponModal
        case couponUseTapped
        case couponChargeTapped
        case adRewardEarned
        case adInterrupted
        case adInterruptedToastDismissed
        case postAdRewardResponse(Result<Void, Error>)
        case refreshQuizStatusResponse(Result<UserQuizStatusData, Error>)
        case delegate(Delegate)
    }

    enum Delegate {
        case startQuizFlow(
            quizzes: [UserQuiz],
            summaryData: ContentSummaryFeature.State,
            isQuizGuideSeen: Bool
        )
        case openMyPageRequested
        case openLeagueRequested
        case startNewGoalTapped
    }
    
    @Dependency(\.goalClient) var goalClient
    
    @Dependency(\.quizClient) var quizClient
    
    @Dependency(\.historyClient) var historyClient
    @Dependency(\.analyticsClient) var analyticsClient
    @Dependency(\.rewardedAdClient) var rewardedAdClient
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 이미 데이터가 있으면 로딩 스피너 표시 없이 백그라운드 리프레시
                if state.currentGoal == nil {
                    state.isLoading = true
                }
                state.showErrorOverlay = false
                state.retryCount = 0
                state.showRetryToast = false

                return .merge(
                    loadHomeData(),
                    .run { _ in await rewardedAdClient.load() }
                )

            // MyPage 등에서 목표가 바뀌었을 수 있음 → 이전 화면 대신 준비 중 로딩을 보여주고 재조회
            case .goalMayHaveChanged:
                state.isLoading = true
                state.isPreparingSnack = true
                state.showErrorOverlay = false
                state.retryCount = 0
                state.showRetryToast = false
                return loadHomeData()
                
            // 캘린더 조회 완료 (독립적 처리)
            case .fetchCalendarHistoryResponse(.success(let calendarData)):
                state.calendarData = calendarData
                state.fireCount = calendarData.currentStreak
                state.stampCount = calendarData.totalStamps
                return .none

            case .fetchCalendarHistoryResponse(.failure(let error)):
                Log.home.error("[Home] 캘린더 조회 실패: \(error)")
                return .none
                
            // Step 1 완료 → Step 2 시작
            case .fetchCurrentGoalResponse(.success(let goal)):
                state.showErrorOverlay = false
                state.isRetryingError = false
                state.retryCount = 0

                state.currentGoal = goal
                setGoalUserProperties(goal)

                Log.home.debug("[Home] Step1 완료 - type: \(goal.type)")
                
                // Step 2: 퀴즈 상태는 항상 확인 (날짜 변경 감지용)
                return .run { send in
                    do {
                        let status = try await quizClient.fetchUserQuizStatus()
                        await send(.fetchQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.fetchQuizStatusResponse(.failure(error)))
                    }
                }
                .cancellable(id: CancelID.quizStatus, cancelInFlight: true)
                
            case .fetchCurrentGoalResponse(.failure(let error)):
                state.isLoading = false
                state.isPreparingSnack = false
                let overlayMsg = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                state.errorOverlayMessage = overlayMsg
                state.showErrorOverlay = true
                state.isRetryingError = false
                Log.home.error("[Home] Step1 실패: \(error)")
                return .none
                
            // Step 2 완료 (요약글/퀴즈는 ContentSummaryFeature가 SSE로 직접 처리)
            case .fetchQuizStatusResponse(.success(let status)):
                state.quizStatus = status
                state.isPreparingSnack = false
                if !state.isUsingCoupon {
                    // complete-set이 퀴즈 시작 시 차감되므로,
                    // hasSolvedToday=false여도 availableQuizCount=0이면 더 이상 퀴즈 불가 → 부스러기 화면
                    state.isTodayQuizCompleted = status.hasSolvedToday || status.availableQuizCount == 0
                } else {
                    // 쿠폰 사용 후: 추가 퀴즈 슬롯이 없으면 부스러기 화면으로 복귀
                    // availableQuizCount > 0이면 isTodayQuizCompleted = false 유지 (새 퀴즈 가능)
                    if status.availableQuizCount == 0 {
                        state.isTodayQuizCompleted = true
                    }
                }
                state.isUsingCoupon = false

                Log.home.debug("[Home] Step2 완료 - hasSolvedToday: \(status.hasSolvedToday)")

                // 목표 전환 후 이전 목표의 완료 상태가 남지 않도록 서버 값으로 갱신
                state.isGoalCompleted = status.isCompleted

                if status.isCompleted {
                    state.showGoalCompletedAlert = true
                    state.isLoading = false
                    Log.home.debug("[Home] Goal 완료 - 모든 퀴즈 세트 완료")
                    return .run { send in
                        await send(.fetchActiveGoalsResponse(
                            Result { try await goalClient.fetchGoals() }
                        ))
                    }
                }

                state.isLoading = false
                return .none
                
            case .fetchQuizStatusResponse(.failure(let error)):
                state.isPreparingSnack = false
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError, code == "GOAL-002" {
                    state.isGoalCompleted = true
                    state.showGoalCompletedAlert = true
                    state.isLoading = false
                    return .run { send in
                        await send(.fetchActiveGoalsResponse(
                            Result { try await goalClient.fetchGoals() }
                        ))
                    }
                }
                state.isLoading = false
                let overlayMsg = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                state.errorOverlayMessage = overlayMsg
                state.showErrorOverlay = true
                state.isRetryingError = false
                Log.home.error("[Home] Step2 실패: \(error)")
                return .none
                
            case .retryFromErrorOverlay:
                state.retryCount += 1
                if state.retryCount >= 2 {
                    state.showRetryToast = true
                }
                state.isRetryingError = true
                state.isLoading = true

                return loadHomeData()

            case .dismissErrorOverlay:
                state.showErrorOverlay = false
                state.isRetryingError = false
                return .none

            case .retryToastDismissed:
                state.showRetryToast = false
                return .none

            case .settingTapped:
                return .send(.delegate(.openMyPageRequested))

            case .leagueTapped:
                return .send(.delegate(.openLeagueRequested))

            case .speechBubbleTapped:
                state.showCouponModal = true
                analyticsClient.log(.couponModalView(couponCount: state.availableQuizCount))
                return .none

            case .dismissCouponModal:
                state.showCouponModal = false
                return .none

            case .couponChargeTapped:
                analyticsClient.log(.adRewardRequest)
                state.showCouponModal = false
                return .run { send in
                    for await event in rewardedAdClient.show() {
                        switch event {
                        case .rewarded:
                            await send(.adRewardEarned)
                        case .interrupted:
                            await send(.adInterrupted)
                        }
                    }
                }

            case .couponUseTapped:
                guard state.availableQuizCount > 0 else { return .none }
                analyticsClient.log(.couponUsed(couponCount: state.availableQuizCount))
                state.isTodayQuizCompleted = false
                state.isUsingCoupon = true
                state.showCouponModal = false
                state.isLoading = true
                return .run { send in
                    do {
                        let status = try await quizClient.fetchUserQuizStatus()
                        await send(.fetchQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.fetchQuizStatusResponse(.failure(error)))
                    }
                }

            case .adRewardEarned:
                analyticsClient.log(.adRewardEarned)
                return .run { send in
                    do {
                        try await quizClient.postAdReward()
                        await send(.postAdRewardResponse(.success(())))
                    } catch {
                        await send(.postAdRewardResponse(.failure(error)))
                    }
                }

            case .adInterrupted:
                analyticsClient.log(.adInterrupted)
                state.showAdInterruptedToast = true
                return .none

            case .adInterruptedToastDismissed:
                state.showAdInterruptedToast = false
                return .none

            case .postAdRewardResponse(.success):
                return .run { send in
                    do {
                        let status = try await quizClient.fetchUserQuizStatus()
                        await send(.refreshQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.refreshQuizStatusResponse(.failure(error)))
                    }
                }

            case .postAdRewardResponse(.failure(let error)):
                Log.home.error("광고 보상 API 실패: \(error)")
                return .none

            case .refreshQuizStatusResponse(.success(let status)):
                state.quizStatus = status
                state.showCouponModal = true
                return .none

            case .refreshQuizStatusResponse(.failure(let error)):
                Log.home.error("퀴즈 상태 새로고침 실패: \(error)")
                return .none

            case .fetchActiveGoalsResponse(.success(let goals)):
                state.hasActiveSubjects = goals.contains { !$0.isExpired && !$0.isCompleted }
                logGoalCompleteViewIfNeeded(state)
                return .none

            case .fetchActiveGoalsResponse(.failure):
                state.hasActiveSubjects = false
                logGoalCompleteViewIfNeeded(state)
                return .none

            case .goalCompletedAlertDismissed:
                state.showGoalCompletedAlert = false
                return .none

            case .goalCompletedNewGoalTapped:
                analyticsClient.log(.goalCompleteAction(action: "new_goal"))
                state.showGoalCompletedAlert = false
                return .send(.delegate(.startNewGoalTapped))

            case .goalCompletedSelectExistingTapped:
                analyticsClient.log(.goalCompleteAction(action: "select_existing"))
                state.showGoalCompletedAlert = false
                return .send(.delegate(.openMyPageRequested))

            case .characterEatTapped:
                if state.isGoalCompleted {
                    state.showGoalCompletedAlert = true
                    return .none
                }

                if state.isTodayQuizCompleted {
                    Log.home.debug("오늘 퀴즈를 이미 완료했습니다")
                    return .none
                }
                
                guard let summaryData = makeSummaryState(state) else {
                    Log.home.debug("요약 데이터가 아직 없습니다")
                    return .none
                }
                return .send(.delegate(.startQuizFlow(
                    quizzes: [],
                    summaryData: summaryData,
                    isQuizGuideSeen: state.quizStatus?.isQuizGuideSeen ?? false
                )))

            case .delegate:
                return .none
            }
        }
    }

    private enum CancelID {
        case calendar
        case currentGoal
        case quizStatus
    }

    /// 캘린더 + 현재 목표 병렬 조회 (Step 1 시작)
    /// 중복 호출 시 이전 요청을 취소해 응답 순서가 꼬이지 않도록 함
    private func loadHomeData() -> Effect<Action> {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        return .merge(
            // 캘린더 조회 (독립적)
            .run { send in
                do {
                    let calendarData = try await historyClient.fetchCalendarHistory(year: year, month: month)
                    await send(.fetchCalendarHistoryResponse(.success(calendarData)))
                } catch {
                    await send(.fetchCalendarHistoryResponse(.failure(error)))
                }
            }
            .cancellable(id: CancelID.calendar, cancelInFlight: true),
            // 목표 조회 (Step 1 시작)
            .run { send in
                do {
                    let goal = try await goalClient.fetchCurrentGoal()
                    await send(.fetchCurrentGoalResponse(.success(goal)))
                } catch {
                    await send(.fetchCurrentGoalResponse(.failure(error)))
                }
            }
            .cancellable(id: CancelID.currentGoal, cancelInFlight: true)
        )
    }

    /// 현재 목표로 요약 화면 상태를 만든다. 요약할 대상(카테고리 / 문서 ID)이 없으면 nil
    /// SSE 스트리밍은 ContentSummaryFeature가 전담하므로 빈 요약으로 시작
    private func makeSummaryState(_ state: State) -> ContentSummaryFeature.State? {
        guard let goal = state.currentGoal else { return nil }
        let hasSolvedToday = state.quizStatus?.hasSolvedToday ?? false

        if goal.type == "CATEGORY", let categoryId = goal.category?.categoryId {
            return ContentSummaryFeature.State(
                documentId: 0,
                summaryText: "",
                hasSolvedToday: hasSolvedToday,
                isFirstTime: true,
                documentType: .category,
                quizzes: [],
                categoryId: categoryId
            )
        }

        if goal.type == "DOCUMENT", let documentId = goal.documentId {
            return ContentSummaryFeature.State(
                documentId: documentId,
                summaryText: "",
                hasSolvedToday: hasSolvedToday,
                isFirstTime: true,
                documentType: .document,
                quizzes: [],
                goalId: goal.goalId
            )
        }

        return nil
    }

    /// 주제 완료 알럿은 진행 중인 주제 조회 후 버튼 구성이 정해지므로 그 시점에 기록
    private func logGoalCompleteViewIfNeeded(_ state: State) {
        guard state.showGoalCompletedAlert else { return }
        analyticsClient.log(.goalCompleteView(hasActiveSubjects: state.hasActiveSubjects))
    }

    private func setGoalUserProperties(_ goal: GoalResponse) {
        if let documentType = DocumentType(rawValue: goal.type) {
            analyticsClient.setUserProperty(.contentType(documentType.analyticsValue))
        }
        analyticsClient.setUserProperty(.difficulty(AnalyticsValue.difficulty(goal.difficulty)))
    }
}
