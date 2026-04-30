//
//  TimePickerModal.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import UIKit

struct TimePickerModal: View {
    let title: String
    @Binding var selectedTime: Date?
    let onDismiss: () -> Void
    var minuteInterval: Int = 1

    @State private var tempTime: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)

            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)

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

            if minuteInterval == 1 {
                DatePicker(
                    "",
                    selection: $tempTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .foregroundStyle(.black)
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .padding()
            } else {
                WheelDatePickerView(date: $tempTime, minuteInterval: minuteInterval)
                    .frame(height: 180)
                    .padding()
            }

            Spacer()
        }
        .background(Color.white)
        .colorScheme(.light)
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

struct WheelDatePickerView: UIViewRepresentable {
    @Binding var date: Date
    let minuteInterval: Int

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = minuteInterval
        picker.locale = Locale(identifier: "ko_KR")
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = date
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: WheelDatePickerView
        init(_ parent: WheelDatePickerView) { self.parent = parent }

        @objc func dateChanged(_ picker: UIDatePicker) {
            parent.date = picker.date
        }
    }
}
