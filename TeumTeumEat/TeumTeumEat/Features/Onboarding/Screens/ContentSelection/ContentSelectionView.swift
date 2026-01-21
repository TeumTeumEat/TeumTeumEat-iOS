//
//  ContentSelectionView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct ContentSelectionView: View {
    let store: StoreOf<ContentSelectionFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 20)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_study")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 283)
                                .padding(.horizontal, 32)
                                .padding(.top, 10)
                            
                            HStack(spacing: 16) {
                                TTECategoryButton(
                                    icon: Image("files"),
                                    title: "파일 업로드",
                                    subtitle: "공부하고 싶은\n내용이 있어요",
                                    isSelected: store.selectedType == .fileUpload
                                ) {
                                    store.send(.contentTypeSelected(.fileUpload))
                                }
                                
                                TTECategoryButton(
                                    icon: Image("category"),
                                    title: "카테고리 선택",
                                    subtitle: "공부하고 싶은걸\n골라볼게요",
                                    isSelected: store.selectedType == .category
                                ) {
                                    store.send(.contentTypeSelected(.category))
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 11)
                            
                            Spacer()
                                .frame(minHeight: 30)
                            
                            TTEButton(
                                title: "다음으로",
                                size: .large,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(.white)
        }
        .colorScheme(.light)
    }
}
