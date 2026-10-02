//
//  Fixtures.swift
//  TeumTeumEatTests
//

import Foundation
@testable import TeumTeumEat

/// 테스트용 샘플 데이터
enum Fixture {
    /// 패키지 모델(public init 없음)은 JSON 디코딩으로 생성
    static func decode<T: Decodable>(_ json: String) -> T {
        try! JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    static func goal(id: Int = 1, categoryId: Int = 10, isCompleted: Bool = false) -> GoalResponse {
        decode("""
        {
          "goalId": \(id), "type": "CATEGORY", "startDate": "2026-10-01", "endDate": "2026-10-28",
          "studyPeriod": "4", "difficulty": "중", "prompt": null, "fileName": null,
          "category": { "categoryId": \(categoryId), "name": "SwiftUI", "path": "/IT/앱개발자/iOS", "description": null },
          "documentId": null, "isExpired": false, "isCompleted": \(isCompleted)
        }
        """)
    }

    static func quizStatus(
        hasSolvedToday: Bool = false,
        availableQuizCount: Int = 1,
        isCompleted: Bool = false,
        isQuizGuideSeen: Bool = true
    ) -> UserQuizStatusData {
        UserQuizStatusData(
            hasSolvedToday: hasSolvedToday,
            isFirstTime: false,
            hasCreatedToday: true,
            isQuizGuideSeen: isQuizGuideSeen,
            availableQuizCount: availableQuizCount,
            targetQuizSetCount: 4,
            completedQuizSetCount: 1,
            isCompleted: isCompleted,
            canIssueCoupon: true
        )
    }

    static let calendar = CalendarHistoryData(
        stampedDates: ["2026-10-01", "2026-10-02"],
        totalStamps: 3,
        currentStreak: 2
    )

    static let quizzes = [
        UserQuiz(quizId: 1, question: "SwiftUI는 선언형인가요?", options: ["O", "X"], type: "OX"),
        UserQuiz(quizId: 2, question: "상태 관리 래퍼는?", options: ["@State", "@Binding", "@Bindable", "@Environment"], type: "MULTIPLE"),
    ]

    static let submitResults: [Int: SubmitQuizAnswerData] = [
        0: SubmitQuizAnswerData(isCorrect: true, correctAnswer: "O", explanation: "선언형입니다."),
        1: SubmitQuizAnswerData(isCorrect: false, correctAnswer: "@State", explanation: "@State입니다."),
    ]

    static func summary(summaryText: String = "오늘의 요약") -> ContentSummaryFeature.State {
        // categoryId / goalId가 없으면 스트리밍 상태가 아님 (onAppear 전 상태)
        ContentSummaryFeature.State(
            documentId: 1,
            summaryText: summaryText,
            hasSolvedToday: false,
            isFirstTime: true,
            documentType: .category,
            quizzes: []
        )
    }
}
