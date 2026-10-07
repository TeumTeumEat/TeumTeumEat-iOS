//
//  AnalyticsClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import FirebaseAnalytics
import OnboardingFeature
import SwiftUI

/// Firebase Analytics 이벤트 전송
@DependencyClient
struct AnalyticsClient {
    var log: @Sendable (_ event: AnalyticsEvent) -> Void
    var setUserProperty: @Sendable (_ property: AnalyticsUserProperty) -> Void
}

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        log: { event in
            Analytics.logEvent(event.name, parameters: event.parameters)
        },
        setUserProperty: { property in
            Analytics.setUserProperty(property.value, forName: property.name)
        }
    )

    // 이벤트 전송은 테스트 결과에 영향이 없으므로 기본은 무시, 검증이 필요한 테스트에서 override
    static let testValue = AnalyticsClient(log: { _ in }, setUserProperty: { _ in })
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
    case logout
    case accountDelete

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

    // 주제 완료 / 주제 추가
    case goalCompleteView(hasActiveSubjects: Bool)
    case goalCompleteAction(action: String)
    case subjectAddStart(contentType: String, source: String)
    case subjectAddComplete(contentType: String, difficulty: String, durationWeeks: Int)
    case subjectAddCancel(contentType: String, step: String)

    // 히스토리 / 설정
    case historyTabSelect(tab: String)
    case notificationToggle(enabled: Bool)

    // 리그
    /// source: home(1등 도전 말풍선) / history(상단 배너)
    case leagueView(source: String)
    /// 리그 화면 "순위 올리기" 버튼
    case leagueRankUpClick

    // 공유
    /// channel: kakao / system, source: league(리그 화면 공유 버튼) / league_result(지난주 결과 모달)
    case shareClick(channel: String, source: String)

    var name: String {
        switch self {
        case .login: AnalyticsEventLogin
        case .signUp: AnalyticsEventSignUp
        case .logout: "logout"
        case .accountDelete: "account_delete"
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
        case .goalCompleteView: "goal_complete_view"
        case .goalCompleteAction: "goal_complete_action"
        case .subjectAddStart: "subject_add_start"
        case .subjectAddComplete: "subject_add_complete"
        case .subjectAddCancel: "subject_add_cancel"
        case .historyTabSelect: "history_tab_select"
        case .notificationToggle: "notification_toggle"
        case .leagueView: "league_view"
        case .leagueRankUpClick: "league_rank_up_click"
        case .shareClick: "share_click"
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
        case let .onboardingComplete(contentType, difficulty, durationWeeks),
             let .subjectAddComplete(contentType, difficulty, durationWeeks):
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
        case let .quizResultAction(action), let .goalCompleteAction(action):
            ["action": action]
        case let .couponModalView(couponCount), let .couponUsed(couponCount):
            ["coupon_count": couponCount]
        case let .goalCompleteView(hasActiveSubjects):
            ["has_active_subjects": hasActiveSubjects ? "true" : "false"]
        case let .subjectAddStart(contentType, source):
            ["content_type": contentType, "source": source]
        case let .leagueView(source):
            ["source": source]
        case let .shareClick(channel, source):
            ["channel": channel, "source": source]
        case let .subjectAddCancel(contentType, step):
            ["content_type": contentType, "step": step]
        case let .historyTabSelect(tab):
            ["tab": tab]
        case let .notificationToggle(enabled):
            ["enabled": enabled ? "true" : "false"]
        case .logout, .accountDelete, .adRewardRequest, .adRewardEarned, .adInterrupted, .leagueRankUpClick:
            nil
        }
    }
}

/// 사용자 속성 (콘솔에서 이 값 기준으로 사용자를 나눠 볼 수 있음)
enum AnalyticsUserProperty: Equatable, Sendable {
    case loginMethod(String)
    case contentType(String)
    case difficulty(String)

    var name: String {
        switch self {
        case .loginMethod: "login_method"
        case .contentType: "content_type"
        case .difficulty: "difficulty"
        }
    }

    var value: String {
        switch self {
        case let .loginMethod(value), let .contentType(value), let .difficulty(value):
            value
        }
    }
}

/// screen_view의 screen_name 값
enum AnalyticsScreen: String {
    case home
    case history
    case historyDetail = "history_detail"
    case myPage = "my_page"
    case subjectList = "subject_list"
    case appSettings = "app_settings"
    case league
}

extension View {
    /// 화면이 나타날 때 screen_view 기록 (Firebase 자동 화면 추적은 SwiftUI에서 화면 이름을 구분하지 못해 꺼둠)
    func trackScreen(_ screen: AnalyticsScreen) -> some View {
        analyticsScreen(name: screen.rawValue)
    }
}

// MARK: - 파라미터 값 변환

enum AnalyticsValue {
    /// 난이도 → easy / normal / hard
    /// 온보딩 / 주제 추가에서는 하·중·상, 서버 응답은 EASY·MEDIUM·HARD를 사용
    static func difficulty(_ raw: String?) -> String {
        switch raw {
        case "하", "EASY": "easy"
        case "중", "MEDIUM": "normal"
        case "상", "HARD": "hard"
        default: "unknown"
        }
    }
}

extension DocumentType {
    /// Analytics 파라미터 값 (category / document)
    var analyticsValue: String {
        switch self {
        case .category: "category"
        case .document: "document"
        }
    }
}

extension OnboardingData.ContentType {
    /// Analytics 파라미터 값 (category / document) - DocumentType과 같은 값 사용
    var analyticsValue: String {
        switch self {
        case .category: "category"
        case .fileUpload: "document"
        }
    }
}

extension OnboardingData {
    var analyticsContentType: String { contentType.analyticsValue }
    var analyticsDifficulty: String { AnalyticsValue.difficulty(difficulty) }
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
