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
            Spacer()
                .frame(height: 24)

            
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    selectedTime = tempTime
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
        .background(Color.white)
        .onAppear {
            if let time = selectedTime {
                tempTime = time
            }
        }
        .presentationDetents([.height(270)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }
}
