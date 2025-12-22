//
//  TimePickerModal.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI

struct TimePickerModal: View {
    let title: String
    @Binding var selectedTime: Date?
    let onDismiss: () -> Void
    
    @State private var tempTime: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button("취소") {
                    onDismiss()
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("확인") {
                    selectedTime = tempTime
                    onDismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            DatePicker(
                "",
                selection: $tempTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .padding()
            
            Spacer()
        }
        .frame(height: 350)
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .onAppear {
            if let time = selectedTime {
                tempTime = time
            }
        }
    }
}


struct TimeSelectionButton: View {
    let label: String
    let timeText: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(timeText)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .primary : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}
