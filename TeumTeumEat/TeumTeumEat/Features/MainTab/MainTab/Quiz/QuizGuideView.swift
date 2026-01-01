//
//  QuizGuideView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/2/26.
//

import SwiftUI
import ComposableArchitecture

struct QuizGuideView: View {
    let store: StoreOf<QuizGuideFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("퀴즈 안내")
                .font(.system(size: 24, weight: .bold))
            
            Text("처음 퀴즈를 시작하시는군요!\n간단한 안내를 확인하세요.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // TODO: 실제 안내 내용 추가
            
            Spacer()
            
            Button(action: {
                store.send(.startQuizButtonTapped)
            }) {
                Text("퀴즈 시작하기")
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
    }
}
