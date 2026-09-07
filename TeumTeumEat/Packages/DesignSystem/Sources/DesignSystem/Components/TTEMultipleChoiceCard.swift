//
//  TTEMultipleChoiceCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

// MARK: - Private Layout

/// 최대 높이를 ViewThatFits에 제안하되, 실제 카드 높이는 선택된 콘텐츠의 자연스러운 높이로 반환
@available(iOS 16.0, *)
private struct NaturalCardHeightLayout: Layout {
    let maximumHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        return content.sizeThatFits(ProposedViewSize(width: proposal.width, height: maximumHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: maximumHeight)
        )
    }
}

// MARK: - Component

/// 객관식 퀴즈 카드
/// - 뒤쪽 회색 카드 3장 내장 (외부에서 추가 불필요)
/// - 내용에 따라 카드 높이 자동 결정, maxCardHeight 초과 시 글꼴 축소
/// - 기준 너비 360pt 기반 배율(s) 적용
public struct TTEMultipleChoiceCard: View {
    /// 부모 컨테이너의 전체 너비
    public let availableWidth: CGFloat
    /// 흰 카드 최대 허용 높이 (화면 여백 제외)
    public let maxCardHeight: CGFloat
    public let questionNumber: Int
    public let question: String
    public let choices: [String]
    @Binding public var selectedChoice: Int?
    public let onChoiceSelected: (Int) -> Void

    public init(
        availableWidth: CGFloat,
        maxCardHeight: CGFloat,
        questionNumber: Int,
        question: String,
        choices: [String],
        selectedChoice: Binding<Int?>,
        onChoiceSelected: @escaping (Int) -> Void = { _ in }
    ) {
        self.availableWidth = availableWidth
        self.maxCardHeight = maxCardHeight
        self.questionNumber = questionNumber
        self.question = question
        self.choices = choices
        self._selectedChoice = selectedChoice
        self.onChoiceSelected = onChoiceSelected
    }

    // 기준 너비 360 기반 배율
    private var s: CGFloat { availableWidth / 360 }
    // 흰 카드 최소 높이
    private var minCardHeight: CGFloat { min(426 * s, maxCardHeight) }

    public var body: some View {
        cardContentView
            .frame(width: 280 * s)
            .background {
                RoundedRectangle(cornerRadius: 32 * s, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.10), radius: 4 * s, x: 0, y: 2 * s)
            }
            .background {
                // 뒤쪽 회색 카드 3장 — 흰 카드 높이(GeometryReader)를 따라감
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

    private var cardContentView: some View {
        NaturalCardHeightLayout(maximumHeight: maxCardHeight) {
            // 큰 글꼴부터 순서대로 시도 — 처음으로 최대 높이 안에 들어오는 배율 선택
            ViewThatFits(in: .vertical) {
                contentLayout(textScale: 1.00)
                contentLayout(textScale: 0.95)
                contentLayout(textScale: 0.90)
                contentLayout(textScale: 0.85)
                contentLayout(textScale: 0.80)
                contentLayout(textScale: 0.75)
                contentLayout(textScale: 0.70)
                contentLayout(textScale: 0.65)
                contentLayout(textScale: 0.60)
                contentLayout(textScale: 0.55)
            }
        }
        .frame(width: 280 * s, alignment: .topLeading)
    }

    private func contentLayout(textScale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Q 번호 (배율 고정)
            Text("Q\(questionNumber)")
                .font(.system(size: 32 * s, weight: .bold))
                .foregroundColor(Color(hex: "2B8FFF"))
                .frame(height: 38 * s, alignment: .leading)
                .padding(.top, 20 * s)
                .padding(.leading, 28 * s)
                .padding(.trailing, 20 * s)

            // 질문 텍스트
            Text(question)
                .font(.system(size: 23 * s * textScale, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, questionTopPadding * s)
                .padding(.horizontal, 28 * s)

            Spacer(minLength: 16 * s)

            // 선택지 목록
            VStack(spacing: 12 * s) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(index: index, choice: choice, textScale: textScale)
                }
            }
            .padding(.horizontal, 20 * s)
            .padding(.bottom, 20 * s)
        }
        .frame(width: 280 * s)
        // 글꼴 축소가 필요했으면 카드가 다시 작아지지 않도록 최대 높이 유지
        .frame(minHeight: textScale < 1 ? maxCardHeight : minCardHeight, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// 질문과 선택지가 모두 짧을 때 더 넓은 상단 여백 적용
    private var questionTopPadding: CGFloat {
        question.count < 50 && choices.allSatisfy { $0.count < 50 } ? 40 : 24
    }

    // MARK: - Choice Button

    private func choiceButton(index: Int, choice: String, textScale: CGFloat) -> some View {
        // 선택지 50자 기준 기본 글꼴 (배율 s 미적용)
        let baseSize: CGFloat = choice.count < 50 ? 24 : 20
        let isSelected = selectedChoice == index

        return Button {
            selectedChoice = index
            onChoiceSelected(index)
        } label: {
            Text(choice)
                .font(.system(size: baseSize * textScale, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(red: 0.47, green: 0.49, blue: 0.52))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16 * s)
                .padding(.vertical, 10 * s)
                .frame(maxWidth: .infinity, minHeight: 45 * s, alignment: .leading)
                .background(
                    isSelected ? Color(hex: "2B8FFF") : Color(white: 0.97),
                    in: RoundedRectangle(cornerRadius: 18 * s)
                )
                .contentShape(RoundedRectangle(cornerRadius: 18 * s))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Rear Card

    private func rearCard(width: CGFloat, offset: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 40 * s, style: .continuous)
            .fill(color)
            .frame(width: width * s, height: height)
            .offset(y: offset * s)
    }
}
