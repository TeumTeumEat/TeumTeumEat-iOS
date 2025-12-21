//
//  TTEMultipleChoiceCard.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

struct TTEMultipleChoiceCard: View {
    let questionNumber: Int
    let question: String
    let choices: [String]
    @Binding var selectedChoice: Int?
    let onChoiceSelected: (Int) -> Void
    
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    let shadowRadius: CGFloat
    let minHeight: CGFloat
    
    let choiceSpacing: CGFloat
    let selectedChoiceColor: Color
    let unselectedChoiceColor: Color
    let selectedTextColor: Color
    let unselectedTextColor: Color
    let borderColor: Color
    
    init(
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
    
    var body: some View {
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
