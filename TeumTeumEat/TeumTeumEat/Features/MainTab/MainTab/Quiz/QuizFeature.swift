//
//  QuizFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizFeature {
    @ObservableState
    struct State: Equatable {
        // Quiz 관련 state
    }
    
    enum Action {
        // Quiz 관련 action
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            }
        }
    }
}

struct QuizView: View {
    let store: StoreOf<QuizFeature>
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("퀴즈 화면")
                    .font(.largeTitle)
            }
            .navigationTitle("퀴즈")
        }
    }
}
