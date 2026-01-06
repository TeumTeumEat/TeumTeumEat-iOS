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
        var quizzes: [UserQuiz]  // ✅ 추가
        var isLoading: Bool = false
        
        init(
            documentId: Int,
            summaryText: String,
            hasSolvedToday: Bool,
            isFirstTime: Bool,
            documentType: DocumentType,
            quizzes: [UserQuiz]  // ✅ 추가
        ) {
            self.documentId = documentId
            self.summaryText = summaryText
            self.hasSolvedToday = hasSolvedToday
            self.isFirstTime = isFirstTime
            self.documentType = documentType
            self.quizzes = quizzes  // ✅ 추가
        }
    }
    
    enum Action {
        case onAppear
        case startQuizButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuiz(quizzes: [UserQuiz], isFirstTime: Bool)  // ✅ 수정
        case cancelled
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .startQuizButtonTapped:
                // ✅ quizzes와 isFirstTime 전달
                return .send(.delegate(.startQuiz(
                    quizzes: state.quizzes,
                    isFirstTime: state.isFirstTime
                )))
                
            case .closeButtonTapped:
                return .send(.delegate(.cancelled))
                
            case .delegate:
                return .none
            }
        }
    }
}
