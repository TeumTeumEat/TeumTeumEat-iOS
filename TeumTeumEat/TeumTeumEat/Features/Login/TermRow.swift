//
//  TermRow.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/9/26.
//

import SwiftUI

struct TermRow: View {
    @Binding var isAgreed: Bool
    let title: String
    let link: String?

    @Environment(\.openURL) private var openURL

    private let linkBlue = Color(red: 0.169, green: 0.561, blue: 1.0)

    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isAgreed ? linkBlue : Color(UIColor.systemGray))
            }

            // 텍스트 (링크가 있으면 탭 가능한 Button, 없으면 일반 Text)
            if let urlString = link, let url = URL(string: urlString) {
                Button {
                    openURL(url)
                } label: {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(linkBlue)
                        .underline()
                }
            } else {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.black)
            }

            Spacer()
        }
        .padding(.leading, 4)
    }
}
