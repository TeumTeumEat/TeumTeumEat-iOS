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
                        currentStep: 5,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 24)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_duration")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 283)
                                .padding(.horizontal, 32)
                                .padding(.top, 10)
                            
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
