//
//  TTEQuizCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

struct TTEQuizCard: View {
    let questionNumber: Int
    let question: String
    @Binding var selectedAnswer: QuizAnswer
    let onAnswerSelected: (QuizAnswer) -> Void
    
    // 디자인 옵션
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowRadius: CGFloat
    let minHeight: CGFloat
    
    init(
        questionNumber: Int,
        question: String,
        selectedAnswer: Binding<QuizAnswer>,
        onAnswerSelected: @escaping (QuizAnswer) -> Void = { _ in },
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        minHeight: CGFloat = 426
    ) {
        self.questionNumber = questionNumber
        self.question = question
        self._selectedAnswer = selectedAnswer
        self.onAnswerSelected = onAnswerSelected
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.minHeight = minHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question Number
            Text("Q\(questionNumber)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "2B8FFF"))
                .padding(.leading, 28)
                .padding(.top, 28)
                .padding(.bottom, 40)
            
            // Question Text
            Text(question)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 28)
                .padding(.trailing, 20)
            
            Spacer(minLength: 40)
            
            // O/X Buttons
            HStack(spacing: 12) {
                TTEQuizButton(
                    type: .correct,
                    currentAnswer: selectedAnswer
                ) {
                    selectedAnswer = .correct
                    onAnswerSelected(.correct)
                }
                .frame(maxWidth: .infinity)
                
                TTEQuizButton(
                    type: .wrong,
                    currentAnswer: selectedAnswer
                ) {
                    selectedAnswer = .wrong
                    onAnswerSelected(.wrong)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
        )
    }
}
