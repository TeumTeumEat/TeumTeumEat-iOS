//
//  HomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    
    @ObservableState
    struct State: Equatable {
        // Home 관련 state
    }
    
    enum Action {
        // Home 관련 action
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            }
            
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("홈 화면")
                    .font(.largeTitle)
            }
            .navigationTitle("홈")
        }
    }
}
