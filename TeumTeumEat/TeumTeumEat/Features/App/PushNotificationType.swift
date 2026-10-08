//
//  PushNotificationType.swift
//  TeumTeumEat
//

import Foundation

/// 서버 푸시 알림 종류 (FCM data.type)
enum PushNotificationType: String, Equatable, Sendable {
    /// 학습 알림 (유저가 설정한 시간)
    case dailyQuiz = "DAILY_QUIZ"
    /// 주간 리그 마감 임박 (일 20:00)
    case leagueDeadline = "LEAGUE_DEADLINE"
    /// 지난주 리그 결과 (월 08:00, 순위에 든 유저만)
    case leagueResult = "LEAGUE_RESULT"

    init?(userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo["type"] as? String else { return nil }
        self.init(rawValue: raw)
    }
}
