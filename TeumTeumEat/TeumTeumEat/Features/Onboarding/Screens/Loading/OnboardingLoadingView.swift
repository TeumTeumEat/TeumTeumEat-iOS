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
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 원형 프로그레스바
                CircularProgressView(progress: progress)
                
                // 중앙에 캐릭터 이미지
                Image("character")
                    .resizable()
                    .scaledToFit()
                    .padding(40)
            }
            .frame(width: 280, height: 280)
            .padding(.top, 117)
            .onAppear {
                startAnimation()
            }
            
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
        .colorScheme(.light)
        .alert($store.scope(state: \.errorAlert, action: \.errorAlert))
        .alert($store.scope(state: \.confirmCancelAlert, action: \.confirmCancelAlert))
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            progress = 1.0
        }
    }
}

struct CircularProgressView: View {
    let progress: CGFloat
    let lineWidth: CGFloat = 12
    
    var body: some View {
        ZStack {
            // 배경 원 (회색)
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // 진행 원
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue500,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))  // 12시 방향부터 시작
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: progress)
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
        .colorScheme(.light)
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
