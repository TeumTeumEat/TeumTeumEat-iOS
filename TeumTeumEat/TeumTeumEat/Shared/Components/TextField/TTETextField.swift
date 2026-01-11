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
    let state: TextFieldState
    let maxLength: Int
    let height: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let allowSpaces: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "입력해주세요",
        state: TextFieldState = .default,
        maxLength: Int = 10,
        height: CGFloat = 50,
        borderColor: Color = .gray300,
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
        self.state = state
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // TextField - 중앙 정렬
            TextField(placeholder,
                      text: $text,
                      prompt: Text("입력해주세요")
                        .font(.bd_medium_16)
                        .foregroundStyle(.gray600)
            )
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 16,
                weight: .medium,
                targetLineHeight: 22
            ))
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
                .stroke(state.borderColor, lineWidth: borderWidth)
        )
        
        if let errorMessage = state.errorMessage {
            HStack {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.red500)
                Spacer()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
        
        
    }
}

enum TextFieldState {
    case `default`
    case valid
    case error(String)
    
    var borderColor: Color {
        switch self {
        case .default:
            return .gray300
        case .valid:
            return .blue500
        case .error:
            return .red500
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}
