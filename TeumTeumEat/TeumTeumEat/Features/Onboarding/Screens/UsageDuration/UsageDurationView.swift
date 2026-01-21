//
//  UsageDurationView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct UsageDurationView: View {
    let store: StoreOf<UsageDurationFeature>
    
    var body: some View {
        GeometryReader { geometry in
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
                        currentStep: 3,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 20)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_clock")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 264)
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                            
                            VStack(spacing: 16) {
                                DurationSelectButton(
                                    text: "5분",
                                    isSelected: store.selectedDuration == .five
                                ) {
                                    store.send(.durationSelected(.five))
                                }
                                
                                DurationSelectButton(
                                    text: "7분",
                                    isSelected: store.selectedDuration == .seven
                                ) {
                                    store.send(.durationSelected(.seven))
                                }
                                
                                DurationSelectButton(
                                    text: "10분",
                                    isSelected: store.selectedDuration == .ten
                                ) {
                                    store.send(.durationSelected(.ten))
                                }
                                
                                DurationSelectButton(
                                    text: "15분+",
                                    isSelected: store.selectedDuration == .fifteenPlus
                                ) {
                                    store.send(.durationSelected(.fifteenPlus))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
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

struct DurationSelectButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .btSemiBold18_24()
                .foregroundColor(isSelected ? .blue500 : .gray600)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue500 : Color.gray300, lineWidth: 2)
                )
        }
        .colorScheme(.light)
    }
}
