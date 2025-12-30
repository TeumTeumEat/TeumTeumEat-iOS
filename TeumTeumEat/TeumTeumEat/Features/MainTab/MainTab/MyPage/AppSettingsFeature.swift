//
//  AppSettingsFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppSettingsFeature {
    @ObservableState
    struct State: Equatable {
        var nickname: String = "재현"
        var leaveTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        var returnTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        var usageMinutes: Int = 5 // 기본값 5분
        
        var isLeaveTimePickerPresented: Bool = false
        var isReturnTimePickerPresented: Bool = false
        var isUsageTimePickerPresented: Bool = false
        
        var leaveTimeText: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "a hh:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: leaveTime)
        }
        
        var returnTimeText: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "a hh:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: returnTime)
        }
    }
    
    enum Action {
        case backTapped
        case nicknameChanged(String)
        case leaveTimeButtonTapped
        case returnTimeButtonTapped
        case usageTimeButtonTapped
        case leaveTimeChanged(Date)
        case returnTimeChanged(Date)
        case usageTimeChanged(Int)
        case leaveTimePickerDismissed
        case returnTimePickerDismissed
        case usageTimePickerDismissed
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.dismissed))
                
            case .nicknameChanged(let nickname):
                state.nickname = nickname
                print("닉네임 변경: \(nickname)")
                return .none
                
            case .leaveTimeButtonTapped:
                state.isLeaveTimePickerPresented = true
                return .none
                
            case .returnTimeButtonTapped:
                state.isReturnTimePickerPresented = true
                return .none
                
            case .usageTimeButtonTapped:
                state.isUsageTimePickerPresented = true
                return .none
                
            case .leaveTimeChanged(let time):
                state.leaveTime = time
                print("출근 시간 변경: \(state.leaveTimeText)")
                return .none
                
            case .returnTimeChanged(let time):
                state.returnTime = time
                print("퇴근 시간 변경: \(state.returnTimeText)")
                return .none
                
            case .usageTimeChanged(let minutes):
                state.usageMinutes = minutes
                print("사용 시간 변경: \(minutes)분")
                return .none
                
            case .leaveTimePickerDismissed:
                state.isLeaveTimePickerPresented = false
                return .none
                
            case .returnTimePickerDismissed:
                state.isReturnTimePickerPresented = false
                return .none
                
            case .usageTimePickerDismissed:
                state.isUsageTimePickerPresented = false
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
