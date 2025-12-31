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
        var summaryText: String = ""  // 요약 내용
        var isLoading: Bool = false
        // TODO: 실제 데이터 모델로 변경 예정
    }
    
    enum Action {
        case onAppear
        case startQuizButtonTapped  // "퀴즈 풀기" 버튼
        case closeButtonTapped      // 닫기 버튼
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuiz    // 퀴즈 시작 요청
        case cancelled    // 취소 (홈으로 돌아가기)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // TODO: 요약 데이터 로드
                state.summaryText = "여기에 콘텐츠 요약이 표시됩니다."
                return .none
                
            case .startQuizButtonTapped:
                // 퀴즈 화면으로 이동
                return .send(.delegate(.startQuiz))
                
            case .closeButtonTapped:
                // 홈으로 돌아가기
                return .send(.delegate(.cancelled))
                
            case .delegate:
                return .none
            }
        }
    }
}
