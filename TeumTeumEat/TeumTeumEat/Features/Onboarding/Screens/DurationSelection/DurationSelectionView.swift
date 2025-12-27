//
//  DurationSelectionView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct DurationSelectionView: View {
    let store: StoreOf<DurationSelectionFeature>
    
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
                    currentStep: 5,
                    totalSteps: 5,
                    height: 15
                )
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("프로그램 기간을 선택하세요!")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                        .padding(.top, 20)
                    
                    // 기간 선택 버튼들
                    VStack(spacing: 16) {
                        ForEach(DurationSelectionFeature.State.Weeks.allCases, id: \.self) { weeks in
                            DurationSelectButton(
                                text: weeks.displayText,
                                isSelected: store.selectedWeeks == weeks
                            ) {
                                store.send(.weeksSelected(weeks))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56.33)
                    .padding(.bottom, 72)
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            
            Spacer()
            
            TTEButton(
                title: "다음",
                size: .large,
                isEnabled: store.canProceed
            ) {
                store.send(.nextTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}
