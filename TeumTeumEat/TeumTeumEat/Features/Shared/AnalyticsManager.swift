//
//  AnalyticsManager.swift
//  TeumTeumEat
//
//  Created by 임재현 on 6/23/26.
//

import Foundation
import FirebaseAnalytics

enum AnalyticsManager {
    static func logLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logOnboardingComplete() {
        Analytics.logEvent("onboarding_complete", parameters: nil)
    }

    static func logQuizStart(quizCount: Int) {
        Analytics.logEvent("quiz_start", parameters: [
            "quiz_count": quizCount
        ])
    }

    static func logQuizComplete(quizCount: Int, correctCount: Int) {
        Analytics.logEvent("quiz_complete", parameters: [
            "quiz_count": quizCount,
            "correct_count": correctCount
        ])
    }

    static func logCouponUsed() {
        Analytics.logEvent("coupon_used", parameters: nil)
    }
}
