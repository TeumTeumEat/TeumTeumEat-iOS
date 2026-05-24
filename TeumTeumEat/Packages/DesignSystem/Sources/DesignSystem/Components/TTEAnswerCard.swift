//
//  TTEAnswerCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

enum AnswerStatus {
    case correct   // 정답
    case wrong     // 오답
    
    var text: String {
        switch self {
        case .correct: return "정답"
        case .wrong: return "오답"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .correct: return Color(hex: "EDF0FF")
        case .wrong: return Color(hex: "FFEBEE")
        }
    }
    
    var textColor: Color {
        switch self {
        case .correct: return Color(hex: "2B8FFF")
        case .wrong: return Color(hex: "F44336")
        }
    }
}

struct TTEAnswerCard: View {
    let questionNumber: Int
    let question: String
    let correctAnswer: String
    let explanation: String
    let status: AnswerStatus
    
    // 디자인 옵션
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowRadius: CGFloat
    
    init(
        questionNumber: Int,
        question: String,
        correctAnswer: String,
        explanation: String,
        status: AnswerStatus,
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 8
    ) {
        self.questionNumber = questionNumber
        self.question = question
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.status = status
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Q\(questionNumber)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "2B8FFF"))
                
                Spacer()
                
                Text(status.text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(status.textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(status.backgroundColor)
                    )
            }
            
            // 문제
            Text(question)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // 정답 표시
            HStack(spacing: 4) {
                Text("정답: \(correctAnswer)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(status.textColor)
            }
            
            // 해설
            VStack(alignment: .leading, spacing: 8) {
                Text("해설")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "7A7A7A"))
                
                Text(explanation)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "7A7A7A"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(padding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
        )
    }
}
