//
//  QuizResultFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizResultFeature {
    @ObservableState
    struct State: Equatable {
        var submitResults: [Int: SubmitQuizAnswerData]
        var totalQuizCount: Int

        var correctCount: Int {
            submitResults.values.filter { $0.isCorrect }.count
        }
        
        var incorrectCount: Int {
            totalQuizCount - correctCount
        }
        
        var score: Int {
            guard totalQuizCount > 0 else { return 0 }
            return (correctCount * 100) / totalQuizCount
        }
        
        init(submitResults: [Int: SubmitQuizAnswerData], totalQuizCount: Int) {
            self.submitResults = submitResults
            self.totalQuizCount = totalQuizCount
        }
    }
    
    enum Action {
        case showDetailResultsButtonTapped
        case homeButtonTapped
        case historyButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case showDetailResults
        case navigateToHome
        case navigateToHistory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showDetailResultsButtonTapped:
                return .send(.delegate(.showDetailResults))
                
            case .homeButtonTapped:
                return .send(.delegate(.navigateToHome))
                
            case .historyButtonTapped:
                return .send(.delegate(.navigateToHistory))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizResultView: View {
    let store: StoreOf<QuizResultFeature>

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("char_exited_quiz_finish")
                .resizable()
                .scaledToFit()
                .frame(height: 240)

            Text("\(store.correctCount)문제를 맞췄어요!")
                .font(Font.custom("Pretendard-SemiBold", size: 30))
                .foregroundColor(.black)
                .padding(.top, 24)

            Text("아래 버튼을 눌러\n정답과 해설을 확인해보세요")
                .font(.body2_regular_16)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()

            // 결과 보기 버튼
            Button {
                store.send(.showDetailResultsButtonTapped)
            } label: {
                Text("결과 보기")
                    .btBold20_24()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 34)
        }
        .background(.white)
    }
}

struct CompletionCardView: View {
    let onGradeButtonTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()

            // 완료 이미지
            Image("character_complete 1")  // 완료 이미지
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(.bottom, 40)

            // 완료 텍스트
            Text("모든 퀴즈를 풀었어요!")
                .font(.t_bold_20)
                .foregroundColor(.black)
                .padding(.bottom, 32)

            // 채점하러 가기 버튼
            Button(action: onGradeButtonTapped) {
                Text("채점하러 가기")
                    .btSemiBold20_24()
                    .foregroundColor(Color(hex: "2B8FFF"))
                    .padding(.horizontal, 22.5)
                    .padding(.vertical, 18)
                    .background(Color(hex: "EAF4FF"))
                    .cornerRadius(16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 426)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
