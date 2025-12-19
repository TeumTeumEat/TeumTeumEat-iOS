//
//  FontTest.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/17/25.
//

import SwiftUI


struct SimpleFontTestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("폰트 테스트")
                    .font(.head_bold_26)
                    .padding(.bottom, 20)
                
                // Head
                Group {
                    Text("Head Bold 26")
                        .headBold26()
                    
                    Text("Head Bold 20")
                        .headBold20()
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Title
                Group {
                    Text("Title Semibold 22")
                        .titleSemibold22()
                    
                    Text("Title Semibold 20")
                        .titleSemibold20()
                    
                    Text("Title Semibold 18")
                        .titleSemibold18()
                    
                    Text("Title Semibold 16")
                        .titleSemibold16()
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Body Medium
                Group {
                    Text("Body Medium 18")
                        .bodyMedium18()
                    
                    Text("Body Medium 14")
                        .bodyMedium14()
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Body Regular
                Group {
                    Text("Body Regular 16")
                        .bodyRegular16()
                    
                    Text("Body Regular 14")
                        .bodyRegular14()
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // Caption
                Text("Caption Regular 12")
                    .captionRegular12()
                    .padding(.vertical, 4)
            }
            .padding(20)
        }
        .background(Color.white)
    }
}
