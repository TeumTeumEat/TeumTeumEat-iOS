//
//  ContentSummaryView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture
import MarkdownUI

struct ContentSummaryView: View {
    let store: StoreOf<ContentSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                store.send(.closeButtonTapped)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            Text("콘텐츠 요약")
                                .titleSemibold20()
                            
                            Spacer()
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .opacity(0)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        Divider()
                    }
                    .background(Color.white)
                    
                    // Markdown 콘텐츠
                    ScrollView {
                        Markdown(store.summaryText)
//                            .markdownTheme(.custom)
                            .markdownTheme(.gitHub)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 180)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(Color.white)
                }
                
                // 그라디언트 + 버튼 영역
                VStack(spacing: 0) {
                    // 그라디언트
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.8),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    // 버튼 영역
                    VStack(spacing: 0) {
                        Button(action: {
                            store.send(.startQuizButtonTapped)
                        }) {
                            Text("퀴즈 풀기")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 34)
                    .background(Color.white)
                }
            }
        }
        .background(.white)
        .navigationBarHidden(true)
        .onAppear {
            store.send(.onAppear)
        }
    }
}

extension Theme {
    static let custom = Theme()
        .text {
            FontSize(16)
            ForegroundColor(.primary)
        }
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 0, bottom: 16)
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(2))
                    }
            }
        }
        .heading2 { configuration in
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownMargin(top: 0, bottom: 12)
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(.em(1.5))
                    }
            }
        }
}
