//
//  OnboardingSummaryView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingSummaryView: View {
    let store: StoreOf<OnboardingSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Button {
                            store.send(.backTapped)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        
                        TTEProgressBar(
                            currentStep: 5,
                            totalSteps: 5,
                            height: 15
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_summary")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 283)
                                .padding(.horizontal, 32)
                                .padding(.top, 5)
                            
                            VStack(spacing: 16) {
                                SummaryRow(
                                    title: "이름",
                                    value: store.userName
                                )
                                
                                SummaryRow(
                                    title: "집에서 나오는 시간",
                                    value: store.leaveTimeText
                                )
                                
                                SummaryRow(
                                    title: "집에 돌아가는 시간",
                                    value: store.returnTimeText
                                )
                                
                                SummaryRow(
                                    title: "틈틈잇 사용 시간",
                                    value: store.usageTimeText
                                )
                                
                                if store.contentType == .category {
                                    SummaryRow(
                                        title: "관심 분야",
                                        value: store.categoryText
                                    )
                                } else {
                                    SummaryRow(
                                        title: "업로드 파일",
                                        value: store.fileNameText
                                    )
                                }
                                
                                SummaryRow(
                                    title: "난이도",
                                    value: store.difficultyText
                                )
                                
                                if !store.customPrompt.isEmpty {
                                    SummaryRow(
                                        title: "요청 프롬프트",
                                        value: store.customPrompt
                                    )
                                }
                                
                                SummaryRow(
                                    title: "공부기간",
                                    value: store.durationText
                                )
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            .padding(.bottom, 180)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground).opacity(0),
                            Color(UIColor.systemBackground).opacity(0.8),
                            Color(UIColor.systemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("입력한 정보는 마이페이지에서 수정할 수 있어요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TTEButton(
                            title: "다음으로",
                            size: .large,
                            isEnabled: true
                        ) {
                            store.send(.completeTapped)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .bodyMedium18()
                .foregroundColor(.black)
            
            HStack {
                Spacer()
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}
