//
//  TimeSettingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TimeSettingFeature {
    @ObservableState
    struct State: Equatable {
        var leaveTime: Date?
        var returnTime: Date?
        var isLeaveTimePickerPresented = false
        var isReturnTimePickerPresented = false
        var enableAlarm: Bool = false
        
        var canProceed: Bool {
            leaveTime != nil && returnTime != nil
        }
        
        var leaveTimeText: String {
            guard let time = leaveTime else { return "오전 00시 00분" }
            return formatTime(time)
        }
        
        var returnTimeText: String {
            guard let time = returnTime else { return "오전 00시 00분" }
            return formatTime(time)
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "a hh시 mm분"
            return formatter.string(from: date)
        }
    }
    
    enum Action {
        case leaveTimeButtonTapped
        case returnTimeButtonTapped
        case leaveTimeChanged(Date)
        case returnTimeChanged(Date)
        case leaveTimePickerDismissed
        case returnTimePickerDismissed
        case nextTapped
        case backTapped
        case alarmToggleTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .leaveTimeButtonTapped:
                state.isLeaveTimePickerPresented = true
                return .none
                
            case .returnTimeButtonTapped:
                state.isReturnTimePickerPresented = true
                return .none
                
            case let .leaveTimeChanged(time):
                state.leaveTime = time
                return .none
                
            case let .returnTimeChanged(time):
                state.returnTime = time
                return .none
                
            case .leaveTimePickerDismissed:
                state.isLeaveTimePickerPresented = false
                return .none
                
            case .returnTimePickerDismissed:
                state.isReturnTimePickerPresented = false
                return .none
                
            case .nextTapped:
                return .none
                
            case .backTapped:
                return .none
            case .alarmToggleTapped:
                state.enableAlarm.toggle()
                return .none
            }
        }
    }
}
