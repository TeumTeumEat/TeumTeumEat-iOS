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
        NavigationStack {
            VStack {
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                if let time = selectedTime {
                    tempTime = time
                }
            }
            .onDisappear {
                selectedTime = tempTime
            }
        }
        .presentationDetents([.height(270)])
        .presentationDragIndicator(.visible)
    }
}
