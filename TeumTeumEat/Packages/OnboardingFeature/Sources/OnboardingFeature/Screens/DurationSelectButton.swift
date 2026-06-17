//
//  DurationSelectButton.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import DesignSystem

struct DurationSelectButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .stSemibold16()
                .foregroundColor(isSelected ? .blue500 : .gray700)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue500 : Color.gray200, lineWidth: 1.5)
                )
        }
    }
}
