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
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 4,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
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
                                    subtitle: "PDF 파일을\n업로드해요",
                                    isSelected: store.selectedType == .fileUpload
                                ) {
                                    store.send(.contentTypeSelected(.fileUpload))
                                }
                                
                                TTECategoryButton(
                                    icon: Image("files"),
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
                            
                            Button {
                                store.send(.nextTapped)
                            } label: {
                                Text("다음")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(store.canProceed ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!store.canProceed)
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
