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
        // 현재 값
        var nickname: String = ""
        var leaveTime: Date = Date()
        var returnTime: Date = Date()
        var usageMinutes: Int = 5
        
        // 원본 값 (변경 감지용)
        var originalNickname: String = ""
        var originalLeaveTime: Date = Date()
        var originalReturnTime: Date = Date()
        var originalUsageMinutes: Int = 5
        
        // UI 상태
        var isLeaveTimePickerPresented: Bool = false
        var isReturnTimePickerPresented: Bool = false
        var isUsageTimePickerPresented: Bool = false
        
        var isLoading: Bool = false
        var isSaving: Bool = false
        var errorMessage: String?
        
        // 닉네임 검증 로직 추가
        var nicknameValidationError: String? {
            let trimmedName = nickname.trimmingCharacters(in: .whitespaces)
            
            // 입력이 없으면 에러 메시지 표시 안 함
            if nickname.isEmpty {
                return nil
            }
            
            // 길이 체크
            if trimmedName.count > 10 {
                return "닉네임은 10글자 이하로 입력해주세요"
            }
            
            // 완성된 한글, 영문, 숫자만 허용
            let allowedPattern = "^[a-zA-Z0-9가-힣]+$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", allowedPattern)
            
            if !predicate.evaluate(with: trimmedName) {
                return "한글, 영문, 숫자만 사용 가능해요"
            }
            
            return nil
        }
        
        // 닉네임 유효성 체크
        var isNicknameValid: Bool {
            let trimmedName = nickname.trimmingCharacters(in: .whitespaces)
            
            guard !trimmedName.isEmpty else { return false }
            guard trimmedName.count >= 1 && trimmedName.count <= 10 else { return false }
            guard !nickname.contains(" ") else { return false }
            
            let allowedPattern = "^[a-zA-Z0-9가-힣]+$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", allowedPattern)
            
            return predicate.evaluate(with: trimmedName)
        }
        
        // Computed Properties
        var hasChanges: Bool {
            nickname != originalNickname ||
            leaveTime != originalLeaveTime ||
            returnTime != originalReturnTime ||
            usageMinutes != originalUsageMinutes
        }
        
        // canSave 수정 - 닉네임 유효성 체크 추가
        var canSave: Bool {
            hasChanges && isNicknameValid 
        }
        
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

        var usageMinutesText: String {
            switch usageMinutes {
            case 5: return "3문제"
            case 7: return "5문제"
            case 10: return "7문제"
            case 15: return "10문제"
            default: return "\(usageMinutes)분"
            }
        }
    }
    
    enum Action {
        case onAppear
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
        
        case saveButtonTapped
        case userNameResponse(Result<String, Error>)
        case commuteInfoResponse(Result<CommuteInfoData, Error>)
        case updateNameResponse(Result<Void, Error>)
        case updateCommuteResponse(Result<Void, Error>)
        
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
        }
    }
    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - onAppear (데이터 로드)
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    // 병렬로 두 API 호출
                    async let nameTask: Void = {
                        do {
                            let name = try await apiClient.fetchUserName()
                            await send(.userNameResponse(.success(name)))
                        } catch {
                            await send(.userNameResponse(.failure(error)))
                        }
                    }()
                    
                    async let commuteTask: Void = {
                        do {
                            let commuteInfo = try await apiClient.fetchCommuteInfo()
                            await send(.commuteInfoResponse(.success(commuteInfo)))
                        } catch {
                            await send(.commuteInfoResponse(.failure(error)))
                        }
                    }()
                    
                    await nameTask
                    await commuteTask
                }
                
            // MARK: - API 응답 처리
            case .userNameResponse(.success(let name)):
                state.nickname = name
                state.originalNickname = name
                print("유저 이름 로드: \(name)")
                return .none
                
            case .userNameResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "이름을 불러오는데 실패했습니다"
                print("유저 이름 로드 실패: \(error)")
                return .none
                
            case .commuteInfoResponse(.success(let commuteInfo)):
                state.isLoading = false
                
                // "08:00:00" -> Date 변환
                if let leaveDate = commuteInfo.startTime.toTimeDate() {
                    state.leaveTime = leaveDate
                    state.originalLeaveTime = leaveDate
                }
                
                if let returnDate = commuteInfo.endTime.toTimeDate() {
                    state.returnTime = returnDate
                    state.originalReturnTime = returnDate
                }
                
                state.usageMinutes = commuteInfo.usageTime
                state.originalUsageMinutes = commuteInfo.usageTime
                
                print("출퇴근 정보 로드 완료")
                return .none
                
            case .commuteInfoResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "출퇴근 정보를 불러오는데 실패했습니다"
                print("출퇴근 정보 로드 실패: \(error)")
                return .none
                
            // MARK: - 저장하기
            case .saveButtonTapped:
                guard state.canSave else { return .none }
                
                state.isSaving = true
                state.errorMessage = nil
                
                var effects: [Effect<Action>] = []
                
                // 이름 변경됐으면
                if state.nickname != state.originalNickname {
                    effects.append(.run { [nickname = state.nickname] send in
                        await send(.updateNameResponse(
                            Result { try await apiClient.updateUserName(name: nickname) }
                        ))
                    })
                }
                
                // 출퇴근 정보 변경됐으면
                if state.leaveTime != state.originalLeaveTime ||
                   state.returnTime != state.originalReturnTime ||
                   state.usageMinutes != state.originalUsageMinutes {
                    
                    let startTime = state.leaveTime.toString(format: "HH:mm:ss")
                    let endTime = state.returnTime.toString(format: "HH:mm:ss")
                    let usageTime = state.usageMinutes
                    
                    effects.append(.run { send in
                        await send(.updateCommuteResponse(
                            Result {
                                try await apiClient.updateCommuteInfo(
                                    startTime: startTime,
                                    endTime: endTime,
                                    usageTime: usageTime
                                )
                            }
                        ))
                    })
                }
                
                return .merge(effects)
                
            // MARK: - 업데이트 응답
            case .updateNameResponse(.success):
                print("이름 업데이트 성공")
                state.originalNickname = state.nickname
                
                // 출퇴근도 같이 업데이트 중이 아니면 저장 완료
                if state.leaveTime == state.originalLeaveTime &&
                   state.returnTime == state.originalReturnTime &&
                   state.usageMinutes == state.originalUsageMinutes {
                    state.isSaving = false
                    return .send(.delegate(.dismissed))
                }
                return .none
                
            case .updateNameResponse(.failure(let error)):
                state.isSaving = false
                state.errorMessage = "이름 변경에 실패했습니다"
                print("이름 업데이트 실패: \(error)")
                return .none
                
            case .updateCommuteResponse(.success):
                print("출퇴근 정보 업데이트 성공")
                state.originalLeaveTime = state.leaveTime
                state.originalReturnTime = state.returnTime
                state.originalUsageMinutes = state.usageMinutes
                
                // 이름도 같이 업데이트 중이 아니면 저장 완료
                if state.nickname == state.originalNickname {
                    state.isSaving = false
                    return .send(.delegate(.dismissed))
                }
                return .none
                
            case .updateCommuteResponse(.failure(let error)):
                state.isSaving = false
                state.errorMessage = "출퇴근 정보 변경에 실패했습니다"
                print("출퇴근 정보 업데이트 실패: \(error)")
                return .none
                
            // MARK: - 기존 액션들
            case .backTapped:
                return .send(.delegate(.dismissed))
                
            case .nicknameChanged(let nickname):
                state.nickname = nickname
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
                return .none
                
            case .returnTimeChanged(let time):
                state.returnTime = time
                return .none
                
            case .usageTimeChanged(let minutes):
                state.usageMinutes = minutes
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


extension String {
    /// "HH:mm:ss" 형식을 Date로 변환 (오늘 날짜 기준)
    func toTimeDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")
        
        guard let time = formatter.date(from: self) else { return nil }
        
        // 오늘 날짜에 해당 시간 적용
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: components.minute ?? 0,
                            second: components.second ?? 0,
                            of: now)
    }
}

extension AppSettingsFeature.State {
    var textFieldState: TextFieldState {
        if let error = nicknameValidationError {
            return .error(error)
        } else {
            return .default
        }
    }
}
