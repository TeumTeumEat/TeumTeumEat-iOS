//
//  AnalyticsClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import FirebaseAnalytics
import OnboardingFeature

/// Firebase Analytics 이벤트 전송
@DependencyClient
struct AnalyticsClient {
    var log: @Sendable (_ event: AnalyticsEvent) -> Void
}

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        log: { event in
            Analytics.logEvent(event.name, parameters: event.parameters)
        }
    )

    // 이벤트 전송은 테스트 결과에 영향이 없으므로 기본은 무시, 검증이 필요한 테스트에서 override
    static let testValue = AnalyticsClient(log: { _ in })
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

/// 이벤트 이름 / 파라미터 정의
/// 이름을 바꾸면 콘솔에서 기존 데이터와 이어지지 않으므로 변경 금지
enum AnalyticsEvent: Equatable, Sendable {
    // 로그인
    case login(method: String)
    case signUp(method: String)

    // 온보딩
    case onboardingStepView(step: String)
    case onboardingContentSelect(contentType: String)
    case onboardingComplete(contentType: String, difficulty: String, durationWeeks: Int)

    // 퀴즈
    case summaryView(contentType: String, isFirstTime: Bool)
    case summaryAbandon(contentType: String)
    case quizStart(quizCount: Int, contentType: String)
    case quizAbandon(questionIndex: Int, quizCount: Int)
    case quizComplete(quizCount: Int, correctCount: Int)
    case quizResultAction(action: String)

    // 쿠폰 / 광고
    case couponModalView(couponCount: Int)
    case couponUsed(couponCount: Int)
    case adRewardRequest
    case adRewardEarned
    case adInterrupted

    var name: String {
        switch self {
        case .login: AnalyticsEventLogin
        case .signUp: AnalyticsEventSignUp
        case .onboardingStepView: "onboarding_step_view"
        case .onboardingContentSelect: "onboarding_content_select"
        case .onboardingComplete: "onboarding_complete"
        case .summaryView: "summary_view"
        case .summaryAbandon: "summary_abandon"
        case .quizStart: "quiz_start"
        case .quizAbandon: "quiz_abandon"
        case .quizComplete: "quiz_complete"
        case .quizResultAction: "quiz_result_action"
        case .couponModalView: "coupon_modal_view"
        case .couponUsed: "coupon_used"
        case .adRewardRequest: "ad_reward_request"
        case .adRewardEarned: "ad_reward_earned"
        case .adInterrupted: "ad_interrupted"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .login(method), let .signUp(method):
            [AnalyticsParameterMethod: method]
        case let .onboardingStepView(step):
            ["step": step]
        case let .onboardingContentSelect(contentType):
            ["content_type": contentType]
        case let .onboardingComplete(contentType, difficulty, durationWeeks):
            ["content_type": contentType, "difficulty": difficulty, "duration_weeks": durationWeeks]
        case let .summaryView(contentType, isFirstTime):
            ["content_type": contentType, "is_first_time": isFirstTime ? "true" : "false"]
        case let .summaryAbandon(contentType):
            ["content_type": contentType]
        case let .quizStart(quizCount, contentType):
            ["quiz_count": quizCount, "content_type": contentType]
        case let .quizAbandon(questionIndex, quizCount):
            ["question_index": questionIndex, "quiz_count": quizCount]
        case let .quizComplete(quizCount, correctCount):
            ["quiz_count": quizCount, "correct_count": correctCount]
        case let .quizResultAction(action):
            ["action": action]
        case let .couponModalView(couponCount), let .couponUsed(couponCount):
            ["coupon_count": couponCount]
        case .adRewardRequest, .adRewardEarned, .adInterrupted:
            nil
        }
    }
}

// MARK: - 파라미터 값 변환

extension DocumentType {
    /// Analytics 파라미터 값 (category / document)
    var analyticsValue: String {
        switch self {
        case .category: "category"
        case .document: "document"
        }
    }
}

extension OnboardingData {
    /// Analytics 파라미터 값 (category / document) - DocumentType과 같은 값 사용
    var analyticsContentType: String {
        switch contentType {
        case .category: "category"
        case .fileUpload: "document"
        }
    }

    /// Analytics 파라미터 값 (easy / normal / hard)
    var analyticsDifficulty: String {
        switch difficulty.flatMap(DifficultySelectionFeature.State.Difficulty.init(rawValue:)) {
        case .easy: "easy"
        case .normal: "normal"
        case .hard: "hard"
        case nil: "unknown"
        }
    }
}

extension OnboardingFeature.State {
    /// 현재 화면에 보이는 온보딩 단계 (OnboardingView와 같은 우선순위로 판별)
    var analyticsStep: String? {
        if welcome != nil { return "welcome" }
        if timeSetting != nil { return "time_setting" }
        if contentSelection != nil { return "content_selection" }
        if fileUpload != nil { return "file_upload" }
        if categorySelection != nil { return "category_selection" }
        if difficultySelection != nil { return "difficulty_selection" }
        if durationSelection != nil { return "duration_selection" }
        if summary != nil { return "summary" }
        if loading != nil { return "loading" }
        if complete != nil { return "complete" }
        return nil
    }
}
