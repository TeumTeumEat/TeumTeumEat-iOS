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
        WithViewStore(store, observe: { $0 }) { viewStore in
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
            .alert("업데이트가 필요합니다", isPresented: Binding(
                get: { viewStore.showForceUpdateAlert },
                set: { _ in }
            )) {
                Button("확인") {
                    viewStore.send(.openAppStore)
                }
            } message: {
                Text("서비스 이용을 위해 최신 버전으로 업데이트해 주세요.")
            }
        }
    }
}

