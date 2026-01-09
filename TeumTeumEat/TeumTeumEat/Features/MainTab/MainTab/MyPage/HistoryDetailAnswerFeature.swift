//
//  HistoryDetailAnswerFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/7/26.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HistoryDetailAnswerFeature {
    @ObservableState
    struct State: Equatable {
        var historyId: Int
        var documentType: DocumentType
        var date: String  // ✅ date 추가
        var quizzes: [QuizDetailItem] = []
        var isLoading: Bool = true
        var errorMessage: String?
        
        init(historyId: Int, documentType: DocumentType, date: String) {  // ✅ date 파라미터 추가
            self.historyId = historyId
            self.documentType = documentType
            self.date = date
        }
    }
    
    enum Action {
        case onAppear
        case fetchQuizDetailsResponse(Result<QuizHistoryDetailData, Error>)
        case closeButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case dismissed
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                
                // ✅ date 추가
                return .run { [type = state.documentType, id = state.historyId, date = state.date] send in
                    do {
                        let detail = try await apiClient.fetchQuizHistoryDetails(
                            type: type,
                            id: id,
                            date: date
                        )
                        await send(.fetchQuizDetailsResponse(.success(detail)))
                    } catch {
                        await send(.fetchQuizDetailsResponse(.failure(error)))
                    }
                }
            case .fetchQuizDetailsResponse(.success(let detail)):
                state.isLoading = false
                state.quizzes = detail.quizzes
                print("✅ Quiz history loaded: \(detail.quizzes.count) quizzes")
                return .none
                
            case .fetchQuizDetailsResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "퀴즈 정보를 불러오는데 실패했습니다."
                print("❌ Failed to load quiz history: \(error)")
                return .none
                
            case .closeButtonTapped:
                return .send(.delegate(.dismissed))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct HistoryDetailAnswerView: View {
    let store: StoreOf<HistoryDetailAnswerFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            if store.isLoading {
                loadingView
            } else if let errorMessage = store.errorMessage {
                errorView(message: errorMessage)
            } else {
                resultsList
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    store.send(.closeButtonTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("오늘의 정답 확인")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.white)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .foregroundColor(.red)
            Button("다시 시도") {
                store.send(.onAppear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Results List
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(store.quizzes.enumerated()), id: \.offset) { index, quiz in
                    answerCardView(index: index, quiz: quiz)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
    }
    
    // MARK: - Answer Card (바인딩 수정)
    private func answerCardView(index: Int, quiz: QuizDetailItem) -> some View {
        TTEAnswerCard(
            questionNumber: index + 1,
            question: quiz.question,
            correctAnswer: quiz.answer,  // ✅ answer 필드 사용
            explanation: quiz.explanation,
            status: quiz.isCorrect ? .correct : .wrong  // ✅ isCorrect 필드 사용
        )
    }
}   
