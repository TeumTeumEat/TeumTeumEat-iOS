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
    
    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isAgreed ? .blue : .gray)
            }
            
            // 텍스트 (링크가 있으면 Link, 없으면 일반 Text)
            if let urlString = link, let url = URL(string: urlString) {
                Link(destination: url) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .underline()
                }
            } else {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.leading, 4)
    }
}
