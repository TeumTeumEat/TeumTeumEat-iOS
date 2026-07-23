//
//  TTETextField.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import SwiftUI

public struct TTETextField: View {
    @Binding public var text: String
    public let placeholder: String
    public let state: TextFieldState
    public let maxLength: Int
    public let height: CGFloat
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let allowSpaces: Bool
    public let showCharacterCount: Bool
    public let isLimitReached: Binding<Bool>

    @State private var displayText: String

    public init(
        text: Binding<String>,
        placeholder: String = "입력해주세요",
        state: TextFieldState = .default,
        maxLength: Int = 10,
        height: CGFloat = 50,
        borderColor: Color = .gray300,
        borderWidth: CGFloat = 2,
        cornerRadius: CGFloat = 16,
        allowSpaces: Bool = true,
        showCharacterCount: Bool = true,
        isLimitReached: Binding<Bool> = .constant(false)
    ) {
        self._text = text
        self._displayText = State(initialValue: text.wrappedValue)
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.height = height
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.allowSpaces = allowSpaces
        self.state = state
        self.showCharacterCount = showCharacterCount
        self.isLimitReached = isLimitReached
    }

    public var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder,
                      text: $displayText,
                      prompt: Text("입력해주세요")
                        .font(.bd_medium_16)
                        .foregroundStyle(Color.gray600)
            )
            .lineSpacing(TypographyHelper.calculateLineSpacing(
                fontSize: 16,
                weight: .medium,
                targetLineHeight: 22
            ))
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .onChange(of: displayText) { _, newValue in
                var filtered = newValue

                if !allowSpaces {
                    filtered = filtered.replacingOccurrences(of: " ", with: "")
                }

                if filtered.count > maxLength {
                    filtered = String(filtered.prefix(maxLength))
                    isLimitReached.wrappedValue = true
                } else if filtered.count < maxLength {
                    isLimitReached.wrappedValue = false
                }
                // count == maxLength: isLimitReached 유지 (타이핑 시도 후 상태 보존)

                if filtered != newValue {
                    displayText = filtered
                }
                if text != filtered {
                    text = filtered
                }
            }
            .onChange(of: text) { _, newValue in
                // 외부(TCA)에서 값이 바뀔 때 동기화
                if newValue != displayText {
                    displayText = newValue
                }
            }

            // 글자수 카운터
            if showCharacterCount {
                Text("\(displayText.count) / \(maxLength)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize()
            }
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

public enum TextFieldState {
    case `default`
    case valid
    case error(String)

    public var borderColor: Color {
        switch self {
        case .default:
            return .gray300
        case .valid:
            return .blue500
        case .error:
            return .red500
        }
    }

    public var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}
