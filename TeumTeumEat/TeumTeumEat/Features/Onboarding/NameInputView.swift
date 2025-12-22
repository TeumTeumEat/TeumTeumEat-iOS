//
//  NameInputView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import ComposableArchitecture

struct NameInputView: View {
    let store: StoreOf<NameInputFeature>
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // 배경 탭 영역
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // 상단 네비게이션 영역
                HStack(spacing: 16) {
                    // 뒤로가기 버튼
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    // Progress Bar
                    TTEProgressBar(
                        currentStep: 1,
                        totalSteps: 5,
                        height: 15,
                        showStepText: false
                    )
                    
                    // Step Text
                    Text("1/5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 컨텐츠 영역
                VStack(spacing: 24) {
                    Text("널 뭐라고 불러줄까?")
                        .titleSemibold18()
                
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)

                    TTETextField(
                        text: Binding(
                            get: { store.name },
                            set: { store.send(.nameChanged($0)) }
                        ),
                        placeholder: "이름을 입력하세요"
                    )
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
