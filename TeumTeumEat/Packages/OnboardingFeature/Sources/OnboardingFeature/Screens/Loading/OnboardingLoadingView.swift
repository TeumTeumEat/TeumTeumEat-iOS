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
    @State private var spinningProgress: CGFloat = 0.0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if store.isFileUpload {
                    CircularProgressView(
                        progress: CGFloat(store.sseProgress),
                        isSpinning: false
                    )
                } else {
                    CircularProgressView(
                        progress: spinningProgress,
                        isSpinning: true
                    )
                }

                Image("character")
                    .resizable()
                    .scaledToFit()
                    .padding(40)
            }
            .frame(width: 280, height: 280)
            .padding(.top, 117)
            .onAppear {
                if !store.isFileUpload {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        spinningProgress = 1.0
                    }
                }
            }

            VStack(spacing: 6) {
                Text(store.isFileUpload ? "PDF 분석 중" : "틈틈잇을 생성하는 중")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                if store.isFileUpload {
                    if let remaining = store.remainingSeconds, remaining > 0 {
                        Text("약 \(remaining)초 남았어요")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    } else {
                        Text("잠시만 기다려주세요")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }

                    Text("\(Int(store.sseProgress * 100))% 완료")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue500)
                        .padding(.top, 4)
                } else {
                    Text("잠시만 기다려주세요")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 29)

            Spacer()

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
        .background(.white)
        .colorScheme(.light)
        .alert($store.scope(state: \.errorAlert, action: \.errorAlert))
        .alert($store.scope(state: \.confirmCancelAlert, action: \.confirmCancelAlert))
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct CircularProgressView: View {
    let progress: CGFloat
    var isSpinning: Bool = false
    let lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue500,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    isSpinning
                        ? .linear(duration: 2.0).repeatForever(autoreverses: false)
                        : .easeInOut(duration: 0.5),
                    value: progress
                )
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
