//
//  MyPageFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture


import Foundation

import UIKit
@Reducer
struct MyPageFeature {
    @ObservableState
    struct State: Equatable {
        var selectedSubject: Subject?
        var subjectList: SubjectListFeature.State?
        var isNotificationEnabled: Bool = false
        var appSettings: AppSettingsFeature.State?
        var isLoadingSubject: Bool = false
        var isLoadingAccountInfo: Bool = false
        var isLoadingNotificationSetting: Bool = false
        var showNotificationSettingsAlert: Bool = false
        
        // 계정 정보
        var socialLoginType: SocialLoginType = .apple
        var email: String = ""
    }
    
    enum Action {
        case onAppear
        case scenePhaseChanged(ScenePhase)
        case selectedSubjectResponse(Result<Subject?, Error>)
        case accountInfoResponse(Result<UserAccountInfoData, Error>)
        case notificationSettingsResponse(Result<UserNotificationSettingsData, Error>)
        case closeTapped
        case viewAllSubjectsTapped
        case viewAppSettingsTapped
        case notificationToggled(Bool)
        case updateNotificationSettingResponse(Result<Void, Error>)
        case checkSystemNotificationStatus
        case systemNotificationStatusChecked(UNAuthorizationStatus)
        case openNotificationSettings
        case dismissNotificationAlert
        case subjectList(SubjectListFeature.Action)
        case appSettings(AppSettingsFeature.Action)
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
        }
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingSubject = true
                state.isLoadingAccountInfo = true
                state.isLoadingNotificationSetting = true
                
                return .run { send in
                    // 병렬로 세 API 호출
                    async let goalsTask: Void = {
                        do {
                            let goals = try await apiClient.fetchGoals()
                            let selectedSubject = goals.first.map { Subject(from: $0) }
                            await send(.selectedSubjectResponse(.success(selectedSubject)))
                        } catch {
                            await send(.selectedSubjectResponse(.failure(error)))
                        }
                    }()
                    
                    async let accountInfoTask: Void = {
                        do {
                            let accountInfo = try await apiClient.fetchUserAccountInfo()
                            await send(.accountInfoResponse(.success(accountInfo)))
                        } catch {
                            await send(.accountInfoResponse(.failure(error)))
                        }
                    }()
                    
                    async let notificationSettingsTask: Void = {
                        do {
                            let settings = try await apiClient.fetchNotificationSettings()
                            await send(.notificationSettingsResponse(.success(settings)))
                        } catch {
                            await send(.notificationSettingsResponse(.failure(error)))
                        }
                    }()
                    
                    // 세 작업 모두 완료 대기
                    await goalsTask
                    await accountInfoTask
                    await notificationSettingsTask
                }
                
            case .selectedSubjectResponse(.success(let subject)):
                state.isLoadingSubject = false
                state.selectedSubject = subject
                return .none
                
            case .selectedSubjectResponse(.failure(let error)):
                state.isLoadingSubject = false
                print("❌ Failed to load selected subject: \(error)")
                return .none
                
            case .accountInfoResponse(.success(let accountInfo)):
                state.isLoadingAccountInfo = false
                state.email = accountInfo.email
                
                if let loginType = SocialLoginType(from: accountInfo.socialProvider) {
                    state.socialLoginType = loginType
                    print("✅ Account info loaded - Type: \(loginType.rawValue), Email: \(accountInfo.email)")
                } else {
                    print("⚠️ Unknown social provider: \(accountInfo.socialProvider)")
                }
                return .none
                
            case .accountInfoResponse(.failure(let error)):
                state.isLoadingAccountInfo = false
                print("❌ Failed to load account info: \(error)")
                return .none
                
            case .notificationSettingsResponse(.success(let settings)):
                state.isLoadingNotificationSetting = false
                state.isNotificationEnabled = settings.pushEnabled
                print("✅ Notification settings loaded - pushEnabled: \(settings.pushEnabled)")
                return .none
                
            case .notificationSettingsResponse(.failure(let error)):
                state.isLoadingNotificationSetting = false
                print("❌ Failed to load notification settings: \(error)")
                return .none
                
            case .notificationToggled(let shouldEnable):
                if shouldEnable {
                    // ON으로 켜려고 할 때
                    return .run { send in
                        let status = await checkNotificationPermission()
                        
                        switch status {
                        case .authorized:
                            // 권한 있음 → 바로 서버 업데이트
                            do {
                                try await apiClient.updateNotificationSetting(pushEnabled: true)
                                await send(.updateNotificationSettingResponse(.success(())))
                            } catch {
                                await send(.updateNotificationSettingResponse(.failure(error)))
                            }
                            
                        case .denied:
                            // 권한 없음 → 설정 유도 Alert
                            await send(.openNotificationSettings)
                            
                        case .notDetermined:
                            // 권한 요청
                            do {
                                let granted = try await UNUserNotificationCenter.current()
                                    .requestAuthorization(options: [.alert, .sound, .badge])
                                
                                if granted {
                                    try await apiClient.updateNotificationSetting(pushEnabled: true)
                                    await send(.updateNotificationSettingResponse(.success(())))
                                } else {
                                    await send(.updateNotificationSettingResponse(.failure(
                                        NSError(domain: "Notification", code: -1, userInfo: [NSLocalizedDescriptionKey: "권한 거부됨"])
                                    )))
                                }
                            } catch {
                                await send(.updateNotificationSettingResponse(.failure(error)))
                            }
                            
                        default:
                            await send(.updateNotificationSettingResponse(.failure(
                                NSError(domain: "Notification", code: -1, userInfo: [NSLocalizedDescriptionKey: "알 수 없는 권한 상태"])
                            )))
                        }
                    }
                } else {
                    // OFF로 끄려고 할 때
                    return .run { send in
                        do {
                            try await apiClient.updateNotificationSetting(pushEnabled: false)
                            await send(.updateNotificationSettingResponse(.success(())))
                        } catch {
                            await send(.updateNotificationSettingResponse(.failure(error)))
                        }
                    }
                }
                
            case .updateNotificationSettingResponse(.success):
                // 서버 업데이트 성공 → 서버에서 다시 가져오기
                return .run { send in
                    do {
                        let settings = try await apiClient.fetchNotificationSettings()
                        await send(.notificationSettingsResponse(.success(settings)))
                    } catch {
                        await send(.notificationSettingsResponse(.failure(error)))
                    }
                }
                
            case .updateNotificationSettingResponse(.failure(let error)):
                print("❌ Failed to update notification setting: \(error)")
                return .none
                
            case .scenePhaseChanged(let phase):
                if phase == .active {
                    // 앱 복귀 시 시스템 권한 체크
                    return .send(.checkSystemNotificationStatus)
                }
                return .none
                
            case .checkSystemNotificationStatus:
                let currentToggleState = state.isNotificationEnabled
                
                return .run { send in
                    let status = await checkNotificationPermission()
                    await send(.systemNotificationStatusChecked(status))
                }
                
            case .systemNotificationStatusChecked(let status):
                // 케이스 2 감지: Toggle ON + 시스템 OFF
                if state.isNotificationEnabled && status != .authorized {
                    print("⚠️ 케이스 2 감지: Toggle ON이지만 시스템 권한 OFF → 서버 동기화")
                    return .run { send in
                        do {
                            try await apiClient.updateNotificationSetting(pushEnabled: false)
                            await send(.updateNotificationSettingResponse(.success(())))
                        } catch {
                            await send(.updateNotificationSettingResponse(.failure(error)))
                        }
                    }
                }
                return .none
                
            case .openNotificationSettings:
                state.showNotificationSettingsAlert = true
                return .none
                
            case .dismissNotificationAlert:
                state.showNotificationSettingsAlert = false
                return .none
                
            case .viewAllSubjectsTapped:
                state.subjectList = SubjectListFeature.State()
                return .none
                
            case .viewAppSettingsTapped:
                state.appSettings = AppSettingsFeature.State()
                return .none
                
            case .subjectList(.delegate(.subjectSelected(let subject))):
                state.selectedSubject = subject
                state.subjectList = nil
                return .none
                
            case .subjectList(.delegate(.dismissed)):
                state.subjectList = nil
                return .none
                
            case .appSettings(.delegate(.dismissed)):
                state.appSettings = nil
                return .none
                
            case .closeTapped:
                return .send(.delegate(.dismissed))
                
            case .subjectList:
                return .none
                
            case .appSettings:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.subjectList, action: \.subjectList) {
            SubjectListFeature()
        }
        .ifLet(\.appSettings, action: \.appSettings) {
            AppSettingsFeature()
        }
    }
}

// MARK: - Helper Functions
extension MyPageFeature {
    private func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}


struct SelectedSubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 맨 위: 기간, 난이도 태그
            tagSection
            
            // 제목
            Text(subject.name)
                .titleSemibold16()
                .foregroundColor(.black)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // 카테고리 경로 (CATEGORY 타입일 때만 표시)
            if !subject.category.isEmpty && subject.category != ["문서"] {
                categorySection
            }
            
            // 설명 (prompt가 있을 때만 표시)
            if !subject.description.isEmpty {
                Text(subject.description)
                    .bodyRegular14()
                    .foregroundColor(.gray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var tagSection: some View {
        HStack(spacing: 6) {
            Text(subject.duration)
                .bodyRegular14()
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
            
            Text("난이도 \(subject.difficulty)")
                .bodyRegular14()
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
            
            Spacer()
        }
    }
    
    private var categorySection: some View {
        HStack(spacing: 4) {
            ForEach(Array(subject.category.enumerated()), id: \.offset) { index, category in
                Text(category)
                    .bodyRegular14()
                    .foregroundColor(.gray)
                
                if index < subject.category.count - 1 {
                    Text(">")
                        .bodyRegular14()
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct AccountInfoCard: View {
    let socialLoginType: SocialLoginType
    let email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 소셜 로그인 아이콘과 타입
            HStack(spacing: 8) {
                Image(systemName: socialLoginType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(socialLoginType.iconColor)
                
                Text(socialLoginType.rawValue)
                    .bodyRegular16()
                    .foregroundColor(.black)
            }
            
            // 이메일
            HStack(spacing: 8) {
                Text("이메일")
                    .bodyRegular14()
                    .foregroundColor(.gray)
                
                Text(email)
                    .bodyRegular14()
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
extension Subject {
    init(from goal: GoalResponse) {
        self.id = "\(goal.goalId)"
        
        // 이름 결정
        if goal.type == "CATEGORY", let category = goal.category {
            // 카테고리 타입: "PM > 제품기획 > MVP 정의"
            let pathComponents = category.path
                .components(separatedBy: "/")
                .filter { !$0.isEmpty }
            
            // path의 마지막 부분들과 name을 결합
            if pathComponents.count >= 2 {
                let displayPath = Array(pathComponents.dropFirst()) // "IT" 제외
                self.name = (displayPath + [category.name]).joined(separator: " > ")
            } else {
                self.name = category.name
            }
        } else {
            // 문서 타입: 파일명 사용
            self.name = goal.fileName ?? "문서 기반 학습"
        }
        
        self.duration = goal.studyPeriod
        self.difficulty = goal.difficulty.displayText
        
        // category 배열은 빈 배열로 (표시 안 함)
        self.category = []
        
        // 설명: prompt가 있을 때만 사용 (CATEGORY든 DOCUMENT든)
        if let prompt = goal.prompt {
            // 여러 개의 연속된 \n을 하나로 정리
            let cleaned = prompt
                .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            self.description = cleaned.isEmpty ? "" : cleaned
        } else {
            self.description = ""
        }
    }
}


// Difficulty 변환을 위한 extension
extension String {
    var displayText: String {
        switch self {
        case "EASY": return "하"
        case "MEDIUM": return "중"
        case "HARD": return "상"
        default: return "중"
        }
    }
}
