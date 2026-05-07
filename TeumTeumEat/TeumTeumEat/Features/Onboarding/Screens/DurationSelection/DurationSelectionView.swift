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
                    Image("character_period")
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
                }
            }
            .scrollDismissesKeyboard(.interactively)

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
    }
}
