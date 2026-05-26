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
                .foregroundColor(isSelected ? .white : .gray700)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isSelected ? Color.blue500 : Color.gray100)
                .cornerRadius(12)
        }
    }
}
