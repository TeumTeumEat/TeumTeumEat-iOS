//
//  QuizClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import OnboardingFeature

/// 퀴즈 / 요약글 API
@DependencyClient
struct QuizClient {
    var fetchUserQuizStatus: @Sendable () async throws -> UserQuizStatusData
    var completeQuizSet: @Sendable () async throws -> Void
    var submitQuizAnswer: @Sendable (_ quizId: Int, _ userAnswer: String) async throws -> SubmitQuizAnswerData
    var updateQuizGuideSeen: @Sendable () async throws -> Void
    var postAdReward: @Sendable () async throws -> Void
    var fetchUserQuizzes: @Sendable (_ documentId: Int, _ documentType: DocumentType) async throws -> [UserQuiz]
    var createAndFetchPDFQuizzes: @Sendable (_ goalId: Int, _ documentId: Int) async throws -> [UserQuiz]
    var fetchCategoryDocumentIfExists: @Sendable (_ categoryId: Int) async throws -> CategoryDocumentData
    var fetchPDFSummaryOnly: @Sendable (_ goalId: Int, _ documentId: Int) async throws -> PDFSummaryData
    var streamCategoryDocument: @Sendable (_ categoryId: Int) -> AsyncThrowingStream<CategoryStreamEvent, Error> = { _ in
        AsyncThrowingStream { $0.finish() }
    }
    var streamPDFSummary: @Sendable (_ goalId: Int, _ documentId: Int) -> AsyncThrowingStream<CategoryStreamEvent, Error> = { _, _ in
        AsyncThrowingStream { $0.finish() }
    }
}

extension QuizClient: DependencyKey {
    static let liveValue: QuizClient = {
        let api = APIClient.liveValue
        return QuizClient(
            fetchUserQuizStatus: { try await api.fetchUserQuizStatus() },
            completeQuizSet: { try await api.completeQuizSet() },
            submitQuizAnswer: { try await api.submitQuizAnswer(quizId: $0, userAnswer: $1) },
            updateQuizGuideSeen: { try await api.updateQuizGuideSeen() },
            postAdReward: { try await api.postAdReward() },
            fetchUserQuizzes: { try await api.fetchUserQuizzes(documentId: $0, documentType: $1) },
            createAndFetchPDFQuizzes: { try await api.createAndFetchPDFQuizzes(goalId: $0, documentId: $1) },
            fetchCategoryDocumentIfExists: { try await api.fetchCategoryDocumentIfExists(categoryId: $0) },
            fetchPDFSummaryOnly: { try await api.fetchPDFSummaryOnly(goalId: $0, documentId: $1) },
            streamCategoryDocument: { api.streamCategoryDocument(categoryId: $0) },
            streamPDFSummary: { api.streamPDFSummary(goalId: $0, documentId: $1) }
        )
    }()

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = QuizClient()
}

extension DependencyValues {
    var quizClient: QuizClient {
        get { self[QuizClient.self] }
        set { self[QuizClient.self] = newValue }
    }
}
