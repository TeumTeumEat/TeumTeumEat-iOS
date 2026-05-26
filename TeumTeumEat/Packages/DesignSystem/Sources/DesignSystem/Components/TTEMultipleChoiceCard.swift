//
//  TTEMultipleChoiceCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

public struct TTEMultipleChoiceCard: View {
    public let questionNumber: Int
    public let question: String
    public let choices: [String]
    @Binding public var selectedChoice: Int?
    public let onChoiceSelected: (Int) -> Void

    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    public let padding: CGFloat
    public let shadowRadius: CGFloat
    public let minHeight: CGFloat

    public let choiceSpacing: CGFloat
    public let selectedChoiceColor: Color
    public let unselectedChoiceColor: Color
    public let selectedTextColor: Color
    public let unselectedTextColor: Color
    public let borderColor: Color

    public init(
        questionNumber: Int,
        question: String,
        choices: [String],
        selectedChoice: Binding<Int?>,
        onChoiceSelected: @escaping (Int) -> Void = { _ in },
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        minHeight: CGFloat = 426,
        choiceSpacing: CGFloat = 14,
        selectedChoiceColor: Color = Color(hex: "2B8FFF"),
        unselectedChoiceColor: Color = .white,
        selectedTextColor: Color = .white,
        unselectedTextColor: Color = .black,
        borderColor: Color = Color(hex: "C4C4C4")
    ) {
        self.questionNumber = questionNumber
        self.question = question
        self.choices = choices
        self._selectedChoice = selectedChoice
        self.onChoiceSelected = onChoiceSelected
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.minHeight = minHeight
        self.choiceSpacing = choiceSpacing
        self.selectedChoiceColor = selectedChoiceColor
        self.unselectedChoiceColor = unselectedChoiceColor
        self.selectedTextColor = selectedTextColor
        self.unselectedTextColor = unselectedTextColor
        self.borderColor = borderColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Q\(questionNumber)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "2B8FFF"))
                .padding(.leading, 28)
                .padding(.top, 28)
                .padding(.bottom, 40)
            
            Text(question)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 28)
                .padding(.trailing, 20)
            
            Spacer(minLength: 40)
            
            VStack(spacing: choiceSpacing) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    Button(action: {
                        selectedChoice = index 
                        onChoiceSelected(index)
                    }) {
                        Text(choice)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedChoice == index ? selectedTextColor : unselectedTextColor)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(selectedChoice == index ? selectedChoiceColor : unselectedChoiceColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedChoice == index ? Color.clear : borderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedChoice)
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
