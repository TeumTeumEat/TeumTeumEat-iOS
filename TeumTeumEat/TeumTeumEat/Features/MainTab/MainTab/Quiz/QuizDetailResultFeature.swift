//
//  QuizDetailResultFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct QuizDetailResultFeature {
    @ObservableState
    struct State: Equatable {
        var quizzes: [UserQuiz]
        var submitResults: [Int: SubmitQuizAnswerData]
        var totalQuizCount: Int
        
        // 정렬된 결과 리스트
        var sortedResults: [(index: Int, result: SubmitQuizAnswerData)] {
            submitResults
                .sorted { $0.key < $1.key }
                .map { (index: $0.key, result: $0.value) }
        }
        
        init(
            quizzes: [UserQuiz],
            submitResults: [Int: SubmitQuizAnswerData],
            totalQuizCount: Int
        ) {
            self.quizzes = quizzes
            self.submitResults = submitResults
            self.totalQuizCount = totalQuizCount
        }
    }
    
    enum Action {
        case reviewSummaryButtonTapped
        case nextButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case showReviewSummary
        case showComplete
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .reviewSummaryButtonTapped:
                Log.quiz.debug("QuizDetailResult: 글 보기 → 요약본으로")
                return .send(.delegate(.showReviewSummary))
                
            case .nextButtonTapped:
                Log.quiz.debug("QuizDetailResult: 다음으로 → 완료 화면으로")
                return .send(.delegate(.showComplete))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizDetailResultView: View {
    let store: StoreOf<QuizDetailResultFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Navigation Bar
                    navigationBar
                    
                    // 문제별 결과 리스트
                    resultsList
                }
                
                // 그라디언트 + 버튼
                bottomButtons
            }
        }
        .navigationBarHidden(true)
    }
    
    // Navigation Bar
    private var navigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                
                Text("오늘의 정답 확인")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color.white)
    }
    
    // 결과 리스트
    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<store.submitResults.count, id: \.self) { index in
                    if let result = store.submitResults[index] {
                        answerCardView(index: index, result: result)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 180)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
    }
    
    // 답안 카드
    private func answerCardView(index: Int, result: SubmitQuizAnswerData) -> some View {
        TTEAnswerCard(
            questionNumber: index + 1,
            question: getQuestionText(for: index),
            correctAnswer: result.correctAnswer,
            explanation: result.explanation,
            status: result.isCorrect ? .correct : .wrong
        )
    }
    
    // 하단 버튼 영역
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.8),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            
            buttonsRow
                .padding(.bottom, 34)
                .background(Color.white)
        }
    }
    
    // 버튼 Row
    private var buttonsRow: some View {
        HStack(spacing: 12) {
            reviewButton
            nextButton
        }
        .padding(.horizontal, 20)
    }
    
    // 글 보기 버튼
    private var reviewButton: some View {
        Button {
            store.send(.reviewSummaryButtonTapped)
        } label: {
            Text("요약 글 보기")
                .btSemiBold20_24()
                .foregroundColor(Color(hex: "2B8FFF"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "EAF4FF"))
                .cornerRadius(16)
        }
    }
    
    // 다음으로 버튼
    private var nextButton: some View {
        Button {
            store.send(.nextButtonTapped)
        } label: {
            Text("다음으로")
                .btSemiBold20_24()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(16)
        }
    }
    
    // 문제 텍스트 가져오기
    private func getQuestionText(for index: Int) -> String {
        guard index < store.quizzes.count else { return "" }
        return store.quizzes[index].question
    }
}

// 각 문제별 결과 아이템
struct QuizResultItemView: View {
    let questionNumber: Int
    let result: SubmitQuizAnswerData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 문제 번호 + 정답/오답
            HStack {
                Text("Q\(questionNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                if result.isCorrect {
                    Label("정답", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    Label("오답", systemImage: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            // 정답 표시
            if !result.isCorrect {
                HStack(spacing: 8) {
                    Text("정답:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(result.correctAnswer)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            // 해설
            VStack(alignment: .leading, spacing: 4) {
                Text("해설")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text(result.explanation)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
