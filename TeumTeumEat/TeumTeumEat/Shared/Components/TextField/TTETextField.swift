//
//  TTETextField.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

struct TTETextField: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    let height: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let allowSpaces: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "입력해주세요",
        maxLength: Int = 10,
        height: CGFloat = 50,
        borderColor: Color = Color(hex: "C4C4C4"),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 16,
        allowSpaces: Bool = true
    ) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.height = height
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.allowSpaces = allowSpaces
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // TextField - 중앙 정렬
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .onChange(of: text) { oldValue, newValue in
                    var filteredText = newValue
                    
                    // 공백 제거 (allowSpaces가 false일 때)
                    if !allowSpaces {
                        filteredText = filteredText.replacingOccurrences(of: " ", with: "")
                    }
                    
                    // 최대 글자수 제한
                    if filteredText.count > maxLength {
                        filteredText = String(filteredText.prefix(maxLength))
                    }
                    
                    // 변경된 값이 있으면 업데이트
                    if filteredText != newValue {
                        text = filteredText
                    }
                }
            
            // 글자수 카운터
            Text("\(text.count) / \(maxLength)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
}
