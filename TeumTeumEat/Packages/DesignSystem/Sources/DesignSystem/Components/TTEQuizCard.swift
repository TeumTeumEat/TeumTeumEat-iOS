//
//  TTEQuizCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

/// OX 퀴즈 카드
/// - 뒤쪽 회색 카드 3장 내장 (TTEMultipleChoiceCard와 동일 구조)
/// - 기준 너비 360pt 기반 배율(s) 적용
public struct TTEQuizCard: View {
    /// 부모 컨테이너의 전체 너비
    public let availableWidth: CGFloat
    /// 흰 카드 최대 허용 높이
    public let maxCardHeight: CGFloat
    public let questionNumber: Int
    public let question: String
    @Binding public var selectedAnswer: QuizAnswer
    public let onAnswerSelected: (QuizAnswer) -> Void

    public init(
        availableWidth: CGFloat,
        maxCardHeight: CGFloat,
        questionNumber: Int,
        question: String,
        selectedAnswer: Binding<QuizAnswer>,
        onAnswerSelected: @escaping (QuizAnswer) -> Void = { _ in }
    ) {
        self.availableWidth = availableWidth
        self.maxCardHeight = maxCardHeight
        self.questionNumber = questionNumber
        self.question = question
        self._selectedAnswer = selectedAnswer
        self.onAnswerSelected = onAnswerSelected
    }

    private var s: CGFloat { availableWidth / 360 }
    private var minCardHeight: CGFloat { min(426 * s, maxCardHeight) }

    public var body: some View {
        cardContent
            .frame(width: 280 * s)
            .background {
                RoundedRectangle(cornerRadius: 32 * s, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.10), radius: 4 * s, x: 0, y: 2 * s)
            }
            .background {
                // 뒤쪽 회색 카드 3장 — 흰 카드 높이를 따라감
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        rearCard(width: 216, offset: -34, height: geo.size.height,
                                 color: Color(white: 195 / 255))
                        rearCard(width: 228, offset: -28, height: geo.size.height,
                                 color: Color(red: 204 / 255, green: 206 / 255, blue: 208 / 255))
                        rearCard(width: 248, offset: -18, height: geo.size.height,
                                 color: Color(red: 227 / 255, green: 228 / 255, blue: 229 / 255))
                    }
                    .frame(width: geo.size.width, alignment: .top)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .padding(.top, 34 * s) // 뒤쪽 카드가 위로 드러나는 여백
            .frame(width: availableWidth)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Q 번호
            Text("Q\(questionNumber)")
                .font(.system(size: 32 * s, weight: .bold))
                .foregroundColor(Color(hex: "2B8FFF"))
                .frame(height: 38 * s, alignment: .leading)
                .padding(.top, 20 * s)
                .padding(.leading, 28 * s)
                .padding(.trailing, 20 * s)

            // 질문 텍스트
            Text(question)
                .font(.system(size: 20 * s, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24 * s)
                .padding(.leading, 28 * s)
                .padding(.trailing, 20 * s)

            Spacer(minLength: 40 * s)

            // O / X 버튼
            HStack(spacing: 12 * s) {
                TTEQuizButton(type: .correct, currentAnswer: selectedAnswer) {
                    selectedAnswer = .correct
                    onAnswerSelected(.correct)
                }
                .frame(maxWidth: .infinity)

                TTEQuizButton(type: .wrong, currentAnswer: selectedAnswer) {
                    selectedAnswer = .wrong
                    onAnswerSelected(.wrong)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20 * s)
            .padding(.bottom, 20 * s)
        }
        .frame(width: 280 * s)
        .frame(minHeight: minCardHeight, alignment: .topLeading)
    }

    // MARK: - Rear Card

    private func rearCard(width: CGFloat, offset: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 40 * s, style: .continuous)
            .fill(color)
            .frame(width: width * s, height: height)
            .offset(y: offset * s)
    }
}
