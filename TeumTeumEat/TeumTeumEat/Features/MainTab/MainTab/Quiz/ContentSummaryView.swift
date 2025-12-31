//
//  ContentSummaryView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentSummaryView: View {
    let store: StoreOf<ContentSummaryFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 상단 닫기 버튼
                HStack {
                    Spacer()
                    Button(action: {
                        store.send(.closeButtonTapped)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .padding()
                }
                
                // 요약 내용
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("콘텐츠 요약")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(store.summaryText)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineSpacing(8)
                    }
                    .padding(.horizontal, 20)
                }
                
                // 하단 퀴즈 풀기 버튼
                Button(action: {
                    store.send(.startQuizButtonTapped)
                }) {
                    Text("퀴즈 풀기")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
