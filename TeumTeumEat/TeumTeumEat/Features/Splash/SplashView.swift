//
//  SplashView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI
import ComposableArchitecture

struct SplashView: View {
    let store: StoreOf<SplashFeature>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Image("logo_login")
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

