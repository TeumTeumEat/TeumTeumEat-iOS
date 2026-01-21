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
                                .foregroundColor(.black)
                                .frame(width: 24, height: 24, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        
                        TTEProgressBar(
                            currentStep: 5,
                            totalSteps: 5,
                            height: 15
                        )
                    }
                    .padding(.horizontal, 20)
                    
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
        .background(.white)
        .colorScheme(.light)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .stSemibold16()
                .foregroundColor(.gray900)
            
            HStack {
                Spacer()
                Text(value)
                    .btMedium18_24()
                    .foregroundColor(.gray900)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray300, lineWidth: 2)
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
                                .foregroundColor(.black)
                            
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
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        Button(action: {
                            onItemTapped(item)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                // 상단: 타이틀 + 날짜
                                HStack(alignment: .top, spacing: 8) {
                                    Text(item.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "333333"))
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(item.dateText))
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(hex: "999999"))
                                }
                                
                                // 하단: 요약 스니펫
                                Text(item.summarySnippet)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(hex: "666666"))
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "F8F9FA"))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "M월 d일"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // 파싱 실패 시 앞부분만 잘라서 표시
        if dateString.count >= 10 {
            let dateOnly = String(dateString.prefix(10)) // "2026-01-04"
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd"
            if let date = fallbackFormatter.date(from: dateOnly) {
                return outputFormatter.string(from: date)
            }
        }
        
        return dateString
    }
}

struct QuizHistoryItem: Identifiable {
    let id: String
    let title: String
    let dateText: String
    let summarySnippet: String
    var isStreak: Bool = false // 연속 달성 여부
}
