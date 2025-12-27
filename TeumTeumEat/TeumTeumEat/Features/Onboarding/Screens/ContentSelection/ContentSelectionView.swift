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
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
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
                        height: 15,
                        showStepText: false
                    )
                    
                    Text("4/5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                VStack(spacing: 24) {
                    Text("학습 방법을 선택해주세요")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                    
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
                }
                .padding(.top, 40)
                
                Spacer()
                
                Button {
                    hideKeyboard()
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
        }
    }
}
