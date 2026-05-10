//
//  ContentSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
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
        var typingFullText: String = ""
        var typingIndex: Int = 0

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
        case delegate(Delegate)

        case startStreaming
        case streamEventReceived(CategoryStreamEvent)
        case streamCompleted
        case streamFailed(Error)
        case fallbackResponse(Result<CategoryDocumentData, Error>)
        case pdfFallbackResponse(Result<PDFSummaryData, Error>)
        case typingTick

        // 스트리밍 완료 후 quizzes 로딩 (신규 문서 케이스 - 카테고리)
        case fetchDocumentMetaCompleted(Result<CategoryDocumentData, Error>)
        case fetchQuizzesCompleted(Result<[UserQuiz], Error>)
    }

    enum Delegate {
        case startQuiz(quizzes: [UserQuiz], isFirstTime: Bool)
        case cancelled
    }

    private enum CancelID { case streaming, typing }

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
                state.isStreaming = false
                return .none

            case .fallbackResponse(.success(let doc)):
                // 카테고리 fallback: 서버에서 받은 실제 값으로 업데이트
                state.documentId = doc.documentId
                state.isFirstTime = doc.isFirstTime
                state.hasSolvedToday = doc.hasSolvedToday
                state.typingFullText = doc.content
                state.typingIndex = 0
                state.streamingText = ""
                state.isStreaming = true
                // quizzes가 없으면 타이핑 중에 병렬로 조회
                let needsQuizzesC = state.quizzes.isEmpty
                if needsQuizzesC { state.isQuizLoading = true }
                let docIdC = doc.documentId
                return .run { send in
                    let chars = Array(doc.content)
                    if needsQuizzesC {
                        let quizTask = Task {
                            try await apiClient.fetchUserQuizzes(
                                documentId: docIdC, documentType: .category
                            )
                        }
                        for _ in chars {
                            try await Task.sleep(for: .milliseconds(15))
                            await send(.typingTick)
                        }
                        await send(.typingTick)
                        let quizResult = await Result { try await quizTask.value }
                        await send(.fetchQuizzesCompleted(quizResult))
                    } else {
                        for _ in chars {
                            try await Task.sleep(for: .milliseconds(15))
                            await send(.typingTick)
                        }
                        await send(.typingTick)
                    }
                }.cancellable(id: CancelID.typing, cancelInFlight: true)

            case .fallbackResponse(.failure):
                state.isStreaming = false
                return .none

            case .pdfFallbackResponse(.success(let summary)):
                // PDF fallback: 서버에서 받은 실제 값으로 업데이트
                state.documentId = summary.documentId
                state.isFirstTime = summary.isFirstTime
                state.hasSolvedToday = summary.hasSolvedToday
                state.typingFullText = summary.summary
                state.typingIndex = 0
                state.streamingText = ""
                state.isStreaming = true
                let needsQuizzesP = state.quizzes.isEmpty
                if needsQuizzesP { state.isQuizLoading = true }
                let docIdP = summary.documentId
                return .run { send in
                    let chars = Array(summary.summary)
                    if needsQuizzesP {
                        let quizTask = Task {
                            try await apiClient.fetchUserQuizzes(
                                documentId: docIdP, documentType: .document
                            )
                        }
                        for _ in chars {
                            try await Task.sleep(for: .milliseconds(15))
                            await send(.typingTick)
                        }
                        await send(.typingTick)
                        let quizResult = await Result { try await quizTask.value }
                        await send(.fetchQuizzesCompleted(quizResult))
                    } else {
                        for _ in chars {
                            try await Task.sleep(for: .milliseconds(15))
                            await send(.typingTick)
                        }
                        await send(.typingTick)
                    }
                }.cancellable(id: CancelID.typing, cancelInFlight: true)

            case .pdfFallbackResponse(.failure):
                state.isStreaming = false
                return .none

            case .typingTick:
                let chars = Array(state.typingFullText)
                guard state.typingIndex < chars.count else {
                    state.summaryText = state.typingFullText
                    state.streamingText = ""   // Markdown 렌더링으로 전환
                    state.isStreaming = false
                    return .none
                }
                state.streamingText += String(chars[state.typingIndex])
                state.typingIndex += 1
                return .none

            case .fetchDocumentMetaCompleted(.success(let doc)):
                state.documentId = doc.documentId
                state.isFirstTime = doc.isFirstTime
                state.hasSolvedToday = doc.hasSolvedToday
                // SSE로 이어붙인 텍스트 대신 서버에 저장된 원본으로 교체
                state.summaryText = doc.content
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

            case .startQuizButtonTapped:
                return .send(.delegate(.startQuiz(
                    quizzes: state.quizzes,
                    isFirstTime: state.isFirstTime
                )))

            case .closeButtonTapped:
                return .merge(
                    .cancel(id: CancelID.streaming),
                    .cancel(id: CancelID.typing),
                    .send(.delegate(.cancelled))
                )

            case .delegate:
                return .none
            }
        }
    }
}
