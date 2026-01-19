//
//  QuizReviewSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI
import ComposableArchitecture
import Lottie

@Reducer
struct QuizReviewSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var summaryText: String
        
        init(summaryText: String) {
            self.summaryText = summaryText
        }
    }
    
    enum Action {
        case backButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case back  // 뒤로가기
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                print("QuizReviewSummary: 뒤로가기")
                return .send(.delegate(.back))
                
            case .delegate:
                return .none
            }
        }
    }
}

import MarkdownUI

struct QuizReviewSummaryView: View {
    let store: StoreOf<QuizReviewSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Custom Navigation Bar
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            store.send(.backButtonTapped)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("콘텐츠 요약")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Spacer()
                        
                        // 우측 빈 공간 (중앙 정렬용)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                }
                .background(Color.white)
                
                // Markdown 콘텐츠
                ScrollView {
                    Markdown(store.summaryText)
                        .markdownTheme(.gitHub)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.white)
            }
        }
        .background(.white)
        .navigationBarHidden(true)
    }
}


@Reducer
struct QuizCompleteFeature {
    @ObservableState
    struct State: Equatable {
        // 필요한 경우 완료 관련 데이터 추가
    }
    
    enum Action {
        case homeButtonTapped
        case historyButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case navigateToHome
        case navigateToHistory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .homeButtonTapped:
                print("QuizComplete: 홈으로 이동")
                return .send(.delegate(.navigateToHome))
                
            case .historyButtonTapped:
                print("QuizComplete: 히스토리로 이동")
                return .send(.delegate(.navigateToHistory))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizCompleteView: View {
    let store: StoreOf<QuizCompleteFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                
                LottieView(animation: .named("quiz_fin"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .frame(width: 280, height: 280)
                
                Text("오늘의 틈틈잇 \n완료!")
                    .font(.system(size: 30, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // 히스토리로
                Button {
                    store.send(.historyButtonTapped)
                } label: {
                    Text("내 스탬프")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue100, lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
                
                // 홈으로
                Button {
                    store.send(.homeButtonTapped)
                } label: {
                    Text("홈으로")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue500)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
    }
}
