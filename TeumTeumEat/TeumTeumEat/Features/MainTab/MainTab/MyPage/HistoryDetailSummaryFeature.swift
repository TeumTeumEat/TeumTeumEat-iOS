//
//  HistoryDetailSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/7/26.
//

import SwiftUI
import ComposableArchitecture
import MarkdownUI

@Reducer
struct HistoryDetailSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var historyId: Int
        var documentType: DocumentType
        var date: String
        var summaryText: String = ""
        var title: String = ""
        var isLoading: Bool = true
        var errorMessage: String?
        var detailAnswer: HistoryDetailAnswerFeature.State?
        
        init(historyId: Int, documentType: DocumentType, date: String) {
             self.historyId = historyId
             self.documentType = documentType
             self.date = date
         }
    }
    
    enum Action {
        case onAppear
        case fetchDetailResponse(Result<HistorySummaryDetailData, Error>)
        case closeButtonTapped
        case checkQuizButtonTapped
        case detailAnswer(HistoryDetailAnswerFeature.Action)
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
                
                // type, id, date 모두 전달
                return .run { [type = state.documentType, id = state.historyId, date = state.date] send in
                    do {
                        let detail = try await apiClient.fetchHistorySummaryDetail(
                            type: type,
                            id: id,
                            date: date
                        )
                        await send(.fetchDetailResponse(.success(detail)))
                    } catch {
                        await send(.fetchDetailResponse(.failure(error)))
                    }
                }
                
            case .fetchDetailResponse(.success(let detail)):
                state.isLoading = false
                state.title = detail.title
                state.summaryText = detail.summary
                print("History detail loaded: \(detail.title)")
                return .none
                
            case .fetchDetailResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "상세 정보를 불러오는데 실패했습니다."
                print("Failed to load history detail: \(error)")
                return .none
                
            case .closeButtonTapped:
                return .send(.delegate(.dismissed))
                
            case .checkQuizButtonTapped:
                state.detailAnswer = HistoryDetailAnswerFeature.State(
                    historyId: state.historyId,
                    documentType: state.documentType,
                    date: state.date
                )
                print(" 퀴즈 확인 버튼 클릭 - ID: \(state.historyId), Type: \(state.documentType), Date: \(state.date)")
                return .none
                
            case .detailAnswer(.delegate(.dismissed)):
                state.detailAnswer = nil
                print("Quiz detail dismissed")
                return .none
                
            case .detailAnswer:
                          return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.detailAnswer, action: \.detailAnswer) {
            HistoryDetailAnswerFeature()
        }
    }
}

struct HistoryDetailSummaryView: View {
    let store: StoreOf<HistoryDetailSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Custom Navigation Bar
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
                            
                            Text("오늘의 냠냠지식")
                                .titleSemibold20()
                                .foregroundStyle(.black)
                            
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
                    
                    // 로딩 또는 에러 상태
                    if store.isLoading {
                        VStack {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    } else if let errorMessage = store.errorMessage {
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                            Button("다시 시도") {
                                store.send(.onAppear)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    } else {
                        // Markdown 콘텐츠
                        ScrollView {
                            Markdown(store.summaryText)
                                .markdownTheme(.gitHub)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                .padding(.bottom, 180)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .background(Color.white)
                    }
                }
                
                // 그라디언트 + 버튼 영역 (로딩 중이 아닐 때만)
                if !store.isLoading && store.errorMessage == nil {
                    VStack(spacing: 0) {
                        // 그라디언트
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.8),
                                Color.white
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        
                        // 버튼 영역
                        VStack(spacing: 0) {
                            Button(action: {
                                store.send(.checkQuizButtonTapped)
                            }) {
                                Text("퀴즈 확인")  
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 34)
                        .background(Color.white)
                    }
                }
            }
        }
        .background(.white)
        .navigationBarHidden(true)
        .navigationDestination(
            isPresented: Binding(
                get: { store.detailAnswer != nil },
                set: { if !$0 { store.send(.detailAnswer(.delegate(.dismissed))) } }
            )
        ) {
            if let answerStore = store.scope(state: \.detailAnswer, action: \.detailAnswer) {
                HistoryDetailAnswerView(store: answerStore)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .preferredColorScheme(.light)
    }
}
