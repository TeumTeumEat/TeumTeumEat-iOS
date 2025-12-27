//
//  OnboardingSummaryView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingSummaryView: View {
    let store: StoreOf<OnboardingSummaryFeature>
    
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
                    currentStep: 5,
                    totalSteps: 5,
                    height: 15
                )
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("설정을 확인해주세요!")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        SummaryRow(
                            icon: "sunrise.fill",
                            title: "집을 나오는 시간",
                            value: store.leaveTimeText
                        )
                        
                        SummaryRow(
                            icon: "sunset.fill",
                            title: "집에 돌아오는 시간",
                            value: store.returnTimeText
                        )
                        
                        SummaryRow(
                            icon: "clock.fill",
                            title: "목표 시간",
                            value: store.usageTimeText
                        )
                        
                        SummaryRow(
                            icon: "calendar.badge.clock",
                            title: "목표 기간",
                            value: store.durationText
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 56.33)
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            
            Spacer()
            
            TTEButton(
                title: "완료",
                size: .large,
                isEnabled: true
            ) {
                store.send(.completeTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
