//
//  DifficultySelectionView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct DifficultySelectionView: View {
    let store: StoreOf<DifficultySelectionFeature>
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var keyboardHeight: CGFloat = 0
    
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
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                Image("character_difficulty")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 283)
                                    .padding(.horizontal, 32)
                                    .padding(.top, 0)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("퀴즈 난이도 설정")
                                        .titleSemibold16()
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 16) {
                                        
                                        DifficultyButton(
                                            title: "상",
                                            isSelected: store.selectedDifficulty == .hard
                                        ) {
                                            store.send(.difficultySelected(.hard))
                                        }
                                        

                                        DifficultyButton(
                                            title: "중",
                                            isSelected: store.selectedDifficulty == .normal
                                        ) {
                                            store.send(.difficultySelected(.normal))
                                        }
                                        
                                        DifficultyButton(
                                            title: "하",
                                            isSelected: store.selectedDifficulty == .easy
                                        ) {
                                            store.send(.difficultySelected(.easy))
                                        }
                                    }
                                    .frame(height: 50)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("요청 프롬프트")
                                        .titleSemibold16()
                                        .foregroundColor(.black)
                                    
                                    VStack(spacing: 0) {
                                        ZStack(alignment: .topLeading) {
                                            if store.customPrompt.isEmpty {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("상황설정 예시가 필요합니다.")
                                                        .bdMedium14_20()
                                                        .foregroundColor(.gray600)
                                                    Text("어떤 식으로 할지 어떤 상황인지 입력해주세요.")
                                                        .bdMedium14_20()
                                                        .foregroundColor(.gray600)
                                                    Text("ex) IT 트렌드나 프로그래밍 관련 퀴즈를")
                                                        .bdMedium14_20()
                                                        .foregroundColor(.gray600)
                                                    Text("풀고 싶어요")
                                                        .bdMedium14_20()
                                                        .foregroundColor(.gray600)
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.top, 12)
                                                .allowsHitTesting(false)
                                            }
                                            
                                            TextEditor(text: Binding(
                                                get: { store.customPrompt },
                                                set: { store.send(.customPromptChanged($0)) }
                                            ))
                                            .font(.system(size: 14))
                                            .focused($isTextEditorFocused)
                                            .frame(height: 96)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .scrollContentBackground(.hidden)
                                        }
                                        
                                        HStack {
                                            Spacer()
                                            Text("\(store.characterCount) / 30")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                                .padding(.trailing, 16)
                                                .padding(.bottom, 12)
                                        }
                                    }
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(isTextEditorFocused ? Color.blue500 : Color.gray300, lineWidth: 2) 
                                    )
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 30)
                                .padding(.top, 24)
                                .padding(.bottom, isTextEditorFocused ? keyboardHeight - 100 : 0)
                                .id("textEditor")

                                Spacer()
                                    .frame(minHeight: isTextEditorFocused ? 0 : 30)
                                
                                TTEButton(
                                    title: "다음",
                                    size: .large,
                                    isEnabled: store.canProceed
                                ) {
                                    isTextEditorFocused = false
                                    store.send(.nextTapped)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                            }
                            .frame(minHeight: scrollGeometry.size.height)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture {
                            isTextEditorFocused = false
                        }
                        .onChange(of: isTextEditorFocused) { _, isFocused in
                            if isFocused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("textEditor", anchor: .center)
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
    }
}

struct DifficultyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .blue500 : .gray600)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    // stroke 대신 strokeBorder를 사용하세요
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.blue500 : Color.gray300, lineWidth: 2)
                )
                // .cornerRadius(12)는 overlay 안의 RoundedRectangle과
                // background가 이미 12라면 굳이 중복해서 쓸 필요 없습니다. (필요시 위치 조정)
        }
    }
}
