//
//  RegisterFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct RegisterFeature {
    @ObservableState
    struct State: Equatable {
        // Register 관련 state
    }
    
    enum Action {
        // Register 관련 action
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            }
        }
    }
}

struct RegisterView: View {
    let store: StoreOf<RegisterFeature>
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("등록 화면")
                    .font(.largeTitle)
            }
            .navigationTitle("등록")
        }
    }
}
