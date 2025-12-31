//
//  OnboardingLoadingView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingLoadingView: View {
    @Bindable var store: StoreOf<OnboardingLoadingFeature>
    
    var body: some View {
        VStack(spacing: 0) {            
            Image("Group 213")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .padding(.top, 117)
            
            VStack(spacing: 0) {
                Text("틈틈잇을 생성하는 중")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("잠시만 기다려주세요")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.top, 29)
            
            Spacer()
            
            // 로딩 단계 표시
            VStack(spacing: 20) {
                ForEach(store.loadingSteps) { step in
                    LoadingStepRow(
                        title: step.title,
                        isCompleted: step.isCompleted
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 60)
        }
        .alert($store.scope(state: \.errorAlert, action: \.errorAlert))
        .alert($store.scope(state: \.confirmCancelAlert, action: \.confirmCancelAlert))
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct LoadingStepRow: View {
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(isCompleted ? .primary : .gray)
            
            Spacer()
            
            if !isCompleted {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
