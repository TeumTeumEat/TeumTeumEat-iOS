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
        Button {
            tempMinutes = minutes
        } label: {
            HStack {
                Spacer()
                Text("\(minutes)분")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tempMinutes == minutes ? .white : .primary)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(tempMinutes == minutes ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
