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
    
    init(
        text: Binding<String>,
        placeholder: String = "입력해주세요",
        maxLength: Int = 10,
        height: CGFloat = 50,
        borderColor: Color = Color(hex: "C4C4C4"),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 16
    ) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.height = height
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // TextField - 중앙 정렬
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.center)
                .onChange(of: text) { oldValue, newValue in
                    // 최대 글자수 제한
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
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
