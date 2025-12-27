//
//  UsageDurationFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct UsageDurationFeature {
    @ObservableState
    struct State: Equatable {
        var selectedDuration: Duration?
        
        var canProceed: Bool {
            selectedDuration != nil
        }
        
        enum Duration: Int, CaseIterable {
            case five = 5
            case seven = 7
            case ten = 10
            case fifteenPlus = 15
            
            var displayText: String {
                switch self {
                case .five: return "5분"
                case .seven: return "7분"
                case .ten: return "10분"
                case .fifteenPlus: return "15분+"
                }
            }
        }
    }
    
    enum Action {
        case durationSelected(State.Duration)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .durationSelected(duration):
                state.selectedDuration = duration
                return .none
                
            case .nextTapped:
                return .none
                
            case .backTapped:
                return .none
            }
        }
    }
}

import SwiftUI
import ComposableArchitecture

struct UsageDurationView: View {
    let store: StoreOf<UsageDurationFeature>
    
    var body: some View {
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
                    currentStep: 3,
                    totalSteps: 5,
                    height: 15
                )
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("하루 몇 분 이용할 건가요?")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
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
                    .padding(.top, 56.33)
                    .padding(.bottom, 72)
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            
            Spacer()
            
            // 하단 다음 버튼
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

struct DurationSelectButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
