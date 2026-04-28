//
//  TimeSettingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import ComposableArchitecture
import Foundation
import UserNotifications
import UIKit

@Reducer
struct TimeSettingFeature {
    @ObservableState
    struct State: Equatable {
        var leaveTime: Date
        var returnTime: Date
        var isLeaveTimePickerPresented = false
        var isReturnTimePickerPresented = false
        var enableAlarm: Bool = false
        var showSettingsAlert = false
        var selectedDuration: Duration?

        init(leaveTime: Date? = nil, returnTime: Date? = nil) {
            self.leaveTime = leaveTime ?? State.defaultLeaveTime
            self.returnTime = returnTime ?? State.defaultReturnTime
        }

        static var defaultLeaveTime: Date {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }

        static var defaultReturnTime: Date {
            var components = DateComponents()
            components.hour = 18
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }

        var canProceed: Bool {
            enableAlarm && selectedDuration != nil
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
        
        var leaveTimeText: String {
            return formatTime(leaveTime)
        }

        var returnTimeText: String {
            return formatTime(returnTime)
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
        case durationSelected(State.Duration)
        case nextTapped
        case backTapped
        case alarmToggleTapped
        case notificationPermissionResponse(Bool)
        case checkNotificationStatus
        case openSettings
        case dismissSettingsAlert 
        case showSettingsAlertToggled
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
                
            case let .durationSelected(duration):
                state.selectedDuration = duration
                return .none

            case .nextTapped:
                return .none

            case .backTapped:
                return .none

            case .alarmToggleTapped:
                if !state.enableAlarm {
                    // 켜려고 할 때
                    return .run { send in
                        let status = await checkNotificationPermission()
                        
                        switch status {
                        case .authorized:
                            // 이미 허용됨 → 바로 ON
                            await send(.notificationPermissionResponse(true))
                            
                        case .denied:
                            // 거부됨 → 설정 유도 Alert
                            await send(.showSettingsAlertToggled)
                            
                        case .notDetermined:
                            // 처음 → 권한 요청
                            let granted = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .sound, .badge])
                            await send(.notificationPermissionResponse(granted ?? false))
                            
                        default:
                            await send(.notificationPermissionResponse(false))
                        }
                    }
                } else {
                    // 끄려고 할 때
                    state.enableAlarm = false
                    return .none
                }

            case .showSettingsAlertToggled:
                state.showSettingsAlert = true
                return .none
                   case .notificationPermissionResponse(let granted):
                       state.enableAlarm = granted
                
                if granted {
                    // 디바이스 토큰 전송 대기 플래그 저장
                    UserDefaults.standard.set(true, forKey: "shouldRegisterDeviceToken")
                    print("알림 권한 허용 - 온보딩 완료 시 토큰 전송 예정")
                }
                       return .none
                       
                   case .checkNotificationStatus:
                       // 앱 복귀 시 권한 상태 체크
                       return .run { send in
                           let status = await checkNotificationPermission()
                           await send(.notificationPermissionResponse(status == .authorized))
                       }
                       
                   case .openSettings:
                       state.showSettingsAlert = false
                       // 설정 앱 열기
                       return .run { _ in
                           await MainActor.run {
                               if let url = URL(string: UIApplication.openSettingsURLString) {
                                   UIApplication.shared.open(url)
                               }
                           }
                       }
                       
                   case .dismissSettingsAlert:
                       state.showSettingsAlert = false
                       return .none
            }
        }
    }
}

extension TimeSettingFeature {
    private func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("알림 권한 요청 실패: \(error)")
            return false
        }
    }
}

extension TimeSettingFeature {
    private func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
