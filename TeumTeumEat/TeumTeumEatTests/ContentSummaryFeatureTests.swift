//
//  ContentSummaryFeatureTests.swift
//  TeumTeumEatTests
//

import ComposableArchitecture
import Foundation
import OnboardingFeature
import Testing
@testable import TeumTeumEat

@MainActor
struct ContentSummaryFeatureTests {
    private static let categoryDocument = CategoryDocumentData(
        documentId: 7, content: "저장된 요약", hasSolvedToday: false,
        isFirstTime: true, title: "SwiftUI 기초", createdAt: "2026-10-05"
    )

    private static let pdfSummary = PDFSummaryData(
        documentId: 30, fileName: "회의록.pdf", fileKey: "key", summary: "PDF 요약",
        status: "COMPLETED", hasSolvedToday: false, isFirstTime: false, updatedAt: "2026-10-05"
    )

    private static func categoryState() -> ContentSummaryFeature.State {
        ContentSummaryFeature.State(
            documentId: 0, summaryText: "", hasSolvedToday: false, isFirstTime: true,
            documentType: .category, quizzes: [], categoryId: 10
        )
    }

    private static func documentState() -> ContentSummaryFeature.State {
        ContentSummaryFeature.State(
            documentId: 30, summaryText: "", hasSolvedToday: false, isFirstTime: true,
            documentType: .document, quizzes: [], goalId: 3
        )
    }

    private static func stream(_ events: [CategoryStreamEvent]) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            events.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }

    private static func failingStream(_ error: Error) -> AsyncThrowingStream<CategoryStreamEvent, Error> {
        AsyncThrowingStream { $0.finish(throwing: error) }
    }

    @Test("카테고리 요약 스트리밍이 끝나면 요약을 확정하고 문서 정보와 퀴즈를 조회한다")
    func categoryStreaming_completes_fetchesQuizzes() async {
        let store = TestStore(initialState: Self.categoryState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamCategoryDocument = { _ in
                Self.stream([.connected, .titleChunk("SwiftUI 기초"), .textChunk("선언형 "), .textChunk("UI"), .completed])
            }
            $0.quizClient.fetchCategoryDocumentIfExists = { _ in Self.categoryDocument }
            $0.quizClient.fetchUserQuizzes = { _, _ in Fixture.quizzes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.summaryText = "선언형 UI"  // 서버 저장본이 아닌 스트리밍 결과 유지
            $0.streamingText = ""
            $0.isStreaming = false
            $0.documentId = 7
            $0.title = "SwiftUI 기초"
            $0.createdAt = "2026-10-05"
            $0.quizzes = Fixture.quizzes
            $0.isQuizLoading = false
        }
    }

    @Test("PDF 요약 스트리밍이 끝나면 퀴즈를 생성해 조회한다")
    func documentStreaming_completes_createsQuizzes() async {
        let store = TestStore(initialState: Self.documentState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamPDFSummary = { _, _ in Self.stream([.textChunk("PDF 요약"), .completed]) }
            $0.quizClient.createAndFetchPDFQuizzes = { _, _ in Fixture.quizzes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.summaryText = "PDF 요약"
            $0.isStreaming = false
            $0.quizzes = Fixture.quizzes
            $0.isQuizLoading = false
        }
    }

    @Test("스트림이 비어 있으면 저장된 요약을 조회해 보여준다")
    func emptyStream_fallsBackToSavedDocument() async {
        let store = TestStore(initialState: Self.categoryState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamCategoryDocument = { _ in Self.stream([.completed]) }
            $0.quizClient.fetchCategoryDocumentIfExists = { _ in Self.categoryDocument }
            $0.quizClient.fetchUserQuizzes = { _, _ in Fixture.quizzes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.summaryText = "저장된 요약"
            $0.documentId = 7
            $0.title = "SwiftUI 기초"
            $0.isStreaming = false
            $0.quizzes = Fixture.quizzes
            $0.isQuizLoading = false
        }
    }

    @Test("QUIZ-002(퀴즈 횟수 소진)면 에러 알럿 메시지를 띄운다")
    func streamFailed_quiz002_showsAlert() async {
        let store = TestStore(initialState: Self.categoryState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamCategoryDocument = { _ in
                Self.failingStream(APIError.serverError(code: "QUIZ-002", message: "", details: nil))
            }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.isStreaming = false
            $0.errorMessage = "오늘의 퀴즈 횟수를 모두 소진했어요."
            $0.showErrorOverlay = false
        }
    }

    @Test("QUIZ-003(이미 생성된 문서)면 저장된 PDF 요약을 조회해 보여준다")
    func streamFailed_quiz003_fallsBackToSavedPDF() async {
        let store = TestStore(initialState: Self.documentState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamPDFSummary = { _, _ in
                Self.failingStream(APIError.serverError(code: "QUIZ-003", message: "이미 생성됨", details: nil))
            }
            $0.quizClient.fetchPDFSummaryOnly = { _, _ in Self.pdfSummary }
            $0.quizClient.fetchUserQuizzes = { _, _ in Fixture.quizzes }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.summaryText = "PDF 요약"
            $0.title = "회의록.pdf"
            $0.isFirstTime = false
            $0.isStreaming = false
            $0.quizzes = Fixture.quizzes
            $0.isQuizLoading = false
        }
    }

    @Test("그 밖의 스트리밍 오류면 에러 오버레이를 띄운다")
    func streamFailed_otherError_showsOverlay() async {
        let store = TestStore(initialState: Self.categoryState()) {
            ContentSummaryFeature()
        } withDependencies: {
            $0.quizClient.streamCategoryDocument = { _ in Self.failingStream(URLError(.timedOut)) }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.finish()
        await store.skipReceivedActions()

        store.assert {
            $0.isStreaming = false
            $0.showErrorOverlay = true
            $0.errorOverlayMessage = "에러가 발생했습니다."
            $0.isRetryingError = false
        }
    }
}
