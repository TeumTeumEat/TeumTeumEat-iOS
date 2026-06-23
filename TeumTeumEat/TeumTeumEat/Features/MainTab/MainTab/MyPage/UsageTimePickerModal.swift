//
//  UsageTimePickerModal.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI

struct UsageTimePickerModal: View {
    let title: String
    @Binding var selectedMinutes: Int
    let onDismiss: () -> Void
    
    @State private var tempMinutes: Int = 5
    
    let timeOptions = [5, 7, 10, 15]

    private func questionCount(for minutes: Int) -> String {
        switch minutes {
        case 5:  return "3문제"
        case 7:  return "5문제"
        case 10: return "7문제"
        case 15: return "10문제"
        default: return "\(minutes)분"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)
            
            headerSection
            
            timeOptionsSection
            
            Spacer()
        }
        .background(Color.white)
        .onAppear {
            tempMinutes = selectedMinutes
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }
    
    private var headerSection: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                selectedMinutes = tempMinutes
                onDismiss()
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
        .padding(.horizontal, 32)
        .padding(.top, 24)
    }
    
    private var timeOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(timeOptions, id: \.self) { minutes in
                timeOptionButton(minutes: minutes)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
    }
    
    private func timeOptionButton(minutes: Int) -> some View {
        let isSelected = tempMinutes == minutes
        return Button {
            tempMinutes = minutes
        } label: {
            HStack {
                Spacer()
                Text(questionCount(for: minutes))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .blue500 : .gray500)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue500 : Color.gray200, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
