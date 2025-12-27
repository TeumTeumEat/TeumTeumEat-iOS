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
                        currentStep: 1,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            Text("널 뭐라고 불러줄까?")
                                .titleSemibold18()
                        
                            Image("pose=front")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 80)
                                .padding(.top, 20)

                            VStack(spacing: 8) {
                                TTETextField(
                                    text: Binding(
                                        get: { store.name },
                                        set: { store.send(.nameChanged($0)) }
                                    ),
                                    placeholder: "이름을 입력하세요",
                                    allowSpaces: false
                                )
                                .focused($isNameFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    isNameFieldFocused = false
                                }
                                .padding(.horizontal, 30)
                                
                                // 유효성 검사 에러 메시지
                                if let errorMessage = store.validationError {
                                    HStack {
                                        Text(errorMessage)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 30)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.top, 56.33)
                            .id("textField")
                            
                            // 키보드 높이만큼만 여유 공간 확보
                            Color.clear
                                .frame(height: isNameFieldFocused ? geometry.size.height * 0.4 : 0)
                        }
                        .padding(.top, 60)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isNameFieldFocused = false
                    }
                    .onChange(of: isNameFieldFocused) { _, isFocused in
                        if isFocused {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("textField", anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer()
                
                TTEButton(
                    title: "다음으로",
                    size: .large,
                    isEnabled: store.canProceed
                ) {
                    isNameFieldFocused = false
                    store.send(.nextTapped)
                }
                .padding(.bottom, 32)
                .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
