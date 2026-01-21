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
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24,alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 1,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 20)

                GeometryReader { scrollGeometry in
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                Image("character_nameInput")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 264)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 20)

                                VStack(spacing: 8) {
                                    TTETextField(
                                        text: Binding(
                                            get: { store.name },
                                            set: { store.send(.nameChanged($0)) }
                                        ),
                                        placeholder: "입력해주세요",
                                        state: store.textFieldState,
                                        allowSpaces: false
                                    )
                                    .focused($isNameFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        isNameFieldFocused = false
                                    }
                                    .padding(.horizontal, 30)
                                    
//                                    if let errorMessage = store.validationError {
//                                        HStack {
//                                            Text(errorMessage)
//                                                .font(.system(size: 12, weight: .regular))
//                                                .foregroundColor(.red)
//                                            Spacer()
//                                        }
//                                        .padding(.horizontal, 30)
//                                        .transition(.opacity.combined(with: .move(edge: .top)))
//                                    }
                                }
                                .padding(.top, 56.33)
                                .padding(.bottom, isNameFieldFocused ? keyboardHeight - 90 : 0)
                                .id("textField")
                                
                                Spacer()
                                    .frame(minHeight: 30)
                                
                                TTEButton(
                                    title: "다음으로",
                                    size: .large,
                                    isEnabled: store.canProceed
                                ) {
                                    isNameFieldFocused = false
                                    store.send(.nextTapped)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                            }
                            .frame(minHeight: scrollGeometry.size.height)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            isNameFieldFocused = false
                        }
                        .onChange(of: isNameFieldFocused) { _, isFocused in
                            if isFocused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("textField", anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(.white)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
        .colorScheme(.light)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
