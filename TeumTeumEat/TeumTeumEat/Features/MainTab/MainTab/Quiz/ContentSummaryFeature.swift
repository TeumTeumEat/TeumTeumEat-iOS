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
        var documentId: Int = 1
        var summaryText: String = "# MVP 정의와 이해\n\nMVP(최소 기능 제품, Minimum Viable Product)는 스타트업과 제품 개발에서 핵심 개념입니다.\n\n## MVP의 정의\n- **MVP란**: 가장 적은 자원으로 최소한의 기능을 갖춘 제품을 의미합니다.\n- **목적**: 빠르게 시장의 반응을 확인하여 제품 개선에 기여합니다.\n\n## MVP의 중요성\n- **리스크 감소**: 초기 투자 비용을 최소화하여 실패 리스크를 줄입니다.\n- **고객 피드백**: 실제 사용자로부터 피드백을 통해 보완점을 파악할 수 있습니다.\n\n## MVP 개발 단계\n1. **아이디어 발굴**: 시장의 문제를 인식합니다.\n2. **기능 최소화**: 핵심 기능만을 선정합니다.\n3. **프로토타입 제작**: 기본적인 제품을 신속히 제작합니다.\n4. **시험 및 Feedback**: 사용자 반응을 분석하고 개선합니다.\n\nMVP를 통해 효과적인 제품 개발이 가능하니, 활용해보세요!"
        var hasSolvedToday: Bool = false
        var isFirstTime: Bool = false
        var isLoading: Bool = false
    }
    
    enum Action {
        case onAppear
        case startQuizButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuiz
        case cancelled
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .startQuizButtonTapped:
                return .send(.delegate(.startQuiz))
                
            case .closeButtonTapped:
                return .send(.delegate(.cancelled))
                
            case .delegate:
                return .none
            }
        }
    }
}
