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

    var body: some View {
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

            ScrollView {
                VStack(spacing: 0) {
                    Image("character_difficulty")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 263)
                        .padding(.horizontal, 32)
                        .padding(.top, 20)

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

                        Button(action: {
                            store.send(.promptButtonTapped)
                        }) {
                            HStack {
                                Text(store.customPrompt.isEmpty ? "원하는 퀴즈 스타일을 선택해주세요 (선택)" : store.customPrompt)
                                    .bdMedium14_20()
                                    .foregroundColor(store.customPrompt.isEmpty ? .gray600 : .gray900)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray600)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(store.customPrompt.isEmpty ? Color.gray300 : Color.blue500, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
            }

            TTEButton(
                title: "다음으로",
                size: .largeFull,
                isEnabled: store.canProceed
            ) {
                store.send(.nextTapped)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .background(.white)
        .colorScheme(.light)
        .sheet(isPresented: Binding(
            get: { store.isPromptPickerPresented },
            set: { if !$0 { store.send(.promptPickerDismissed) } }
        )) {
            PromptPickerModal(
                selectedPrompt: store.customPrompt,
                options: DifficultySelectionFeature.promptOptions,
                onSelect: { store.send(.promptOptionSelected($0)) },
                onDismiss: { store.send(.promptPickerDismissed) }
            )
        }
    }
}

struct PromptPickerModal: View {
    let selectedPrompt: String
    let options: [String]
    let onSelect: (String?) -> Void
    let onDismiss: () -> Void

    @State private var tempSelection: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("요청 프롬프트 (선택)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button {
                    onSelect(tempSelection)
                } label: {
                    Text("완료")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 8) {
                    // 선택 안함
                    Button(action: { tempSelection = nil }) {
                        HStack {
                            Text("선택 안함")
                                .bdMedium14_20()
                                .foregroundColor(tempSelection == nil ? .blue500 : .gray600)
                            Spacer()
                            if tempSelection == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue500)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.gray100)
                        .cornerRadius(10)
                    }

                    ForEach(options, id: \.self) { option in
                        Button(action: { tempSelection = option }) {
                            HStack {
                                Text(option)
                                    .bdMedium14_20()
                                    .foregroundColor(tempSelection == option ? .blue500 : .gray900)
                                Spacer()
                                if tempSelection == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue500)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.gray100)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            tempSelection = selectedPrompt.isEmpty ? nil : selectedPrompt
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.white)
        .colorScheme(.light)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
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
