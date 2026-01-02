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

struct ExpandableSummaryRow: View {
    let categories: [String] // ["앱 개발자", "Swift", "SwiftUI"]
    let items: [QuizHistoryItem]
    @State private var isExpanded: Bool = false
    let onItemTapped: (QuizHistoryItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 - 카테고리 계층 표시
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    // 카테고리 계층 표시
                    HStack(spacing: 4) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            Text(category)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            if index < categories.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .cornerRadius(12)
            
            // 확장된 항목들 - 달력 셀 스타일
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        Button(action: {
                            onItemTapped(item)
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(item.dateText)
                                    .font(.system(size: 16, weight: .bold))
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("퀴즈 완료")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if item.isStreak {
                                        HStack(spacing: 4) {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                            Text("연속 달성")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                Text(item.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "EAF4FF"))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

struct QuizHistoryItem: Identifiable {
    let id: String
    let title: String
    let dateText: String
    var isStreak: Bool = false // 연속 달성 여부
}
