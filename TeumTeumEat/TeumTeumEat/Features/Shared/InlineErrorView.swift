//
//  InlineErrorView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 6/21/26.
//

import SwiftUI

struct InlineErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.gray400)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray600)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("다시 시도")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue500)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue500, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
