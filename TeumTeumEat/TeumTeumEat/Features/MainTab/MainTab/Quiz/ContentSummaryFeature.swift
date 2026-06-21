//
//  ContentSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import OnboardingFeature
import ComposableArchitecture

@Reducer
struct ContentSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var documentId: Int
        var summaryText: String
        var hasSolvedToday: Bool
        var isFirstTime: Bool
        var documentType: DocumentType
        var quizzes: [UserQuiz]
        var isLoading: Bool = false

        var categoryId: Int? = nil
        var goalId: Int? = nil
        var streamingText: String = ""
        var isStreaming: Bool = false
        var isQuizLoading: Bool = false
        var errorMessage: String? = nil
        var showErrorOverlay: Bool = false
        var errorOverlayMessage: String = ""
        var isRetryingError: Bool = false

        init(
            documentId: Int,
            summaryText: String,
            hasSolvedToday: Bool,
            isFirstTime: Bool,
            documentType: DocumentType,
            quizzes: [UserQuiz],
            categoryId: Int? = nil,
            goalId: Int? = nil
        ) {
            self.documentId = documentId
            self.summaryText = summaryText
            self.hasSolvedToday = hasSolvedToday
            self.isFirstTime = isFirstTime
            self.documentType = documentType
            self.quizzes = quizzes
            self.categoryId = categoryId
            self.goalId = goalId
            // 스트리밍 타입이면 onAppear 전에 미리 로딩 상태로 설정
            self.isStreaming = (documentType == .category && categoryId != nil)
                            || (documentType == .document && goalId != nil)
        }
    }

    enum Action {
        case onAppear
        case startQuizButtonTapped
        case closeButtonTapped
        case errorAlertDismissed
        case retryFromErrorOverlay
        case dismissErrorOverlay
        case delegate(Delegate)

        case startStreaming
        case streamEventReceived(CategoryStreamEvent)
        case streamCompleted
        case streamFailed(Error)
        case fallbackResponse(Result<CategoryDocumentData, Error>)
        case pdfFallbackResponse(Result<PDFSummaryData, Error>)

        // 스트리밍 완료 후 quizzes 로딩 (신규 문서 케이스 - 카테고리)
        case fetchDocumentMetaCompleted(Result<CategoryDocumentData, Error>)
        case fetchQuizzesCompleted(Result<[UserQuiz], Error>)
    }

    enum Delegate {
        case startQuiz(quizzes: [UserQuiz], isFirstTime: Bool)
        case cancelled
    }

    private enum CancelID { case streaming }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.documentType == .category, state.categoryId != nil {
                    return .send(.startStreaming)
                }
                if state.documentType == .document, state.goalId != nil {
                    return .send(.startStreaming)
                }
                return .none

            case .startStreaming:
                state.isStreaming = true
                state.streamingText = ""
                if state.documentType == .category {
                    guard let id = state.categoryId else { return .none }
                    return .run { send in
                        do {
                            for try await event in apiClient.streamCategoryDocument(categoryId: id) {
                                await send(.streamEventReceived(event))
                            }
                        } catch {
                            await send(.streamFailed(error))
                        }
                    }.cancellable(id: CancelID.streaming, cancelInFlight: true)
                } else if state.documentType == .document {
                    guard let goalId = state.goalId else { return .none }
                    let docId = state.documentId
                    return .run { send in
                        do {
                            for try await event in apiClient.streamPDFSummary(goalId: goalId, documentId: docId) {
                                await send(.streamEventReceived(event))
                            }
                        } catch {
                            await send(.streamFailed(error))
                        }
                    }.cancellable(id: CancelID.streaming, cancelInFlight: true)
                }
                return .none

            case .streamEventReceived(let event):
                switch event {
                case .connected:
                    return .none
                case .textChunk(let s):
                    state.streamingText += s
                    return .none
                case .titleChunk:
                    return .none
                case .completed:
                    return .send(.streamCompleted)
                }

            case .streamCompleted:
                guard !state.streamingText.isEmpty else {
                    // 빈 스트림 → GET fallback + 타이핑 애니메이션
                    if state.documentType == .category {
                        guard let id = state.categoryId else {
                            state.isStreaming = false; return .none
                        }
                        return .run { send in
                            let result = await Result {
                                try await apiClient.fetchCategoryDocumentIfExists(categoryId: id)
                            }
                            await send(.fallbackResponse(result))
                        }
                    } else if state.documentType == .document {
                        guard let goalId = state.goalId else {
                            state.isStreaming = false; return .none
                        }
                        let docId = state.documentId
                        return .run { send in
                            let result = await Result {
                                try await apiClient.fetchPDFSummaryOnly(goalId: goalId, documentId: docId)
                            }
                            await send(.pdfFallbackResponse(result))
                        }
                    }
                    state.isStreaming = false
                    return .none
                }
                // 정상 스트리밍 완료
                state.summaryText = state.streamingText
                state.streamingText = ""   // Markdown 렌더링으로 전환
                state.isStreaming = false

                if state.documentType == .category {
                    // 퀴즈가 없으면(신규 문서) documentId GET 후 퀴즈 조회
                    guard state.quizzes.isEmpty, let categoryId = state.categoryId else {
                        return .none
                    }
                    state.isQuizLoading = true
                    return .run { send in
                        let result = await Result {
                            try await apiClient.fetchCategoryDocumentIfExists(categoryId: categoryId)
                        }
                        await send(.fetchDocumentMetaCompleted(result))
                    }
                } else if state.documentType == .document {
                    // PDF: SSE는 텍스트만 스트리밍, 퀴즈는 POST /summary 로 생성 필요
                    guard state.quizzes.isEmpty else { return .none }
                    state.isQuizLoading = true
                    guard let goalId = state.goalId else { return .none }
                    let docId = state.documentId
                    return .run { send in
                        let result = await Result {
                            try await apiClient.createAndFetchPDFQuizzes(goalId: goalId, documentId: docId)
                        }
                        await send(.fetchQuizzesCompleted(result))
                    }
                }
                return .none

            case .streamFailed(let error):
                print("[ContentSummary] streamFailed: \(error)")
                // QUIZ-002: 퀴즈 횟수 소진
                if let api = error as? APIError,
                   case .serverError(let code, let message, _) = api, code == "QUIZ-002" {
                    state.isStreaming = false
                    state.errorMessage = message.isEmpty ? "오늘의 퀴즈 횟수를 모두 소진했어요." : message
                    return .none
                }
                // QUIZ-003: 이미 생성된 문서 → GET fallback + 타이핑 애니메이션
                if let api = error as? APIError,
                   case .serverError(let code, _, _) = api, code == "QUIZ-003" {
                    if state.documentType == .category {
                        guard let id = state.categoryId else { return .none }
                        // isStreaming = true 유지 — fallback GET 동안 로딩 표시
                        return .run { send in
                            let result = await Result {
                                try await apiClient.fetchCategoryDocumentIfExists(categoryId: id)
                            }
                            await send(.fallbackResponse(result))
                        }
                    } else if state.documentType == .document {
                        guard let goalId = state.goalId else { return .none }
                        let docId = state.documentId
                        return .run { send in
                            let result = await Result {
                                try await apiClient.fetchPDFSummaryOnly(goalId: goalId, documentId: docId)
                            }
                            await send(.pdfFallbackResponse(result))
                        }
                    }
                }
                // 일반 에러 → 오버레이 표시
                state.isStreaming = false
                let overlayMsg = (error as? APIError)?.overlayMessage ?? "에러가 발생했습니다."
                state.errorOverlayMessage = overlayMsg
                state.showErrorOverlay = true
                state.isRetryingError = false
                return .none

            case .fallbackResponse(.success(let doc)):
                // 카테고리 fallback: 서버에서 받은 실제 값으로 업데이트
                state.documentId = doc.documentId
                state.isFirstTime = doc.isFirstTime
                state.hasSolvedToday = doc.hasSolvedToday
                state.summaryText = doc.content
                state.streamingText = ""
                state.isStreaming = false
                let needsQuizzesC = state.quizzes.isEmpty
                if needsQuizzesC { state.isQuizLoading = true }
                let docIdC = doc.documentId
                guard needsQuizzesC else { return .none }
                return .run { send in
                    let quizResult = await Result {
                        try await apiClient.fetchUserQuizzes(documentId: docIdC, documentType: .category)
                    }
                    await send(.fetchQuizzesCompleted(quizResult))
                }

            case .fallbackResponse(.failure):
                state.isStreaming = false
                return .none

            case .pdfFallbackResponse(.success(let summary)):
                // PDF fallback: 서버에서 받은 실제 값으로 업데이트
                state.documentId = summary.documentId
                state.isFirstTime = summary.isFirstTime
                state.hasSolvedToday = summary.hasSolvedToday
                state.summaryText = summary.summary
                state.streamingText = ""
                state.isStreaming = false
                let needsQuizzesP = state.quizzes.isEmpty
                if needsQuizzesP { state.isQuizLoading = true }
                let docIdP = summary.documentId
                guard needsQuizzesP else { return .none }
                return .run { send in
                    let quizResult = await Result {
                        try await apiClient.fetchUserQuizzes(documentId: docIdP, documentType: .document)
                    }
                    await send(.fetchQuizzesCompleted(quizResult))
                }

            case .pdfFallbackResponse(.failure):
                state.isStreaming = false
                return .none

            case .fetchDocumentMetaCompleted(.success(let doc)):
                state.documentId = doc.documentId
                state.isFirstTime = doc.isFirstTime
                state.hasSolvedToday = doc.hasSolvedToday
                // summaryText는 SSE로 이미 완성된 상태 — 서버 저장본으로 덮어쓰지 않음
                return .run { [docId = doc.documentId] send in
                    let result = await Result {
                        try await apiClient.fetchUserQuizzes(documentId: docId, documentType: .category)
                    }
                    await send(.fetchQuizzesCompleted(result))
                }

            case .fetchDocumentMetaCompleted(.failure(let error)):
                print("[ContentSummary] 문서 메타 조회 실패: \(error)")
                state.isQuizLoading = false
                return .none

            case .fetchQuizzesCompleted(.success(let quizzes)):
                state.quizzes = quizzes
                state.isQuizLoading = false
                print("[ContentSummary] 퀴즈 로딩 완료: \(quizzes.count)개")
                return .none

            case .fetchQuizzesCompleted(.failure(let error)):
                print("[ContentSummary] 퀴즈 로딩 실패: \(error)")
                state.isQuizLoading = false
                return .none

            case .errorAlertDismissed:
                state.errorMessage = nil
                return .send(.delegate(.cancelled))

            case .retryFromErrorOverlay:
                state.showErrorOverlay = false
                state.isRetryingError = true
                return .send(.startStreaming)

            case .dismissErrorOverlay:
                state.showErrorOverlay = false
                state.isRetryingError = false
                return .merge(
                    .cancel(id: CancelID.streaming),
                    .send(.delegate(.cancelled))
                )

            case .startQuizButtonTapped:
                return .send(.delegate(.startQuiz(
                    quizzes: state.quizzes,
                    isFirstTime: state.isFirstTime
                )))

            case .closeButtonTapped:
                return .merge(
                    .cancel(id: CancelID.streaming),
                    .send(.delegate(.cancelled))
                )

            case .delegate:
                return .none
            }
        }
    }
}
