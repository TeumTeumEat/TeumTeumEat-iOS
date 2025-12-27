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
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation
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
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("난이도를 선택하세요!")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("난이도")
                            .bodyMedium18()
                            .foregroundColor(.black)
                        
                        Button(action: {
                            store.send(.difficultyButtonTapped)
                        }) {
                            HStack {
                                Spacer()
                                Text(store.difficultyText)
                                    .font(.system(size: 16))
                                    .foregroundColor(store.selectedDifficulty != nil ? .primary : .gray)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.selectedDifficulty != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 56.33)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("퀴즈 커스텀 설정 (선택)")
                            .bodyMedium18()
                            .foregroundColor(.black)
                        
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                if store.customPrompt.isEmpty {
                                    Text("퀴즈에 필요한 프롬포트 있으면 설정해주세요")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: Binding(
                                    get: { store.customPrompt },
                                    set: { store.send(.customPromptChanged($0)) }
                                ))
                                .font(.system(size: 14))
                                .focused($isTextEditorFocused)
                                .frame(height: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                            }
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextEditorFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            
                            HStack {
                                Spacer()
                                Text("\(store.characterCount) / 30")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 24)
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isTextEditorFocused = false
            }
            
            Spacer()
            
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
        .sheet(isPresented: Binding(
            get: { store.isDifficultyPickerPresented },
            set: { if !$0 { store.send(.difficultyPickerDismissed) } }
        )) {
            DifficultyPickerModal(
                selectedDifficulty: Binding(
                    get: { store.selectedDifficulty },
                    set: { if let difficulty = $0 { store.send(.difficultySelected(difficulty)) } }
                ),
                onDismiss: {
                    store.send(.difficultyPickerDismissed)
                }
            )
        }
    }
}

struct DifficultyPickerModal: View {
    @Binding var selectedDifficulty: DifficultySelectionFeature.State.Difficulty?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 난이도 선택 버튼들
                VStack(spacing: 16) {
                    ForEach(DifficultySelectionFeature.State.Difficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            selectedDifficulty = difficulty
                            onDismiss()
                        }) {
                            HStack(spacing: 16) {
                                // 아이콘
                                Image(systemName: difficulty.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedDifficulty == difficulty ? .blue : .primary)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // 난이도 이름
                                    Text(difficulty.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    // 설명
                                    Text(difficulty.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // 체크마크
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedDifficulty == difficulty ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle("난이도 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}
