//
//  UserClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import OnboardingFeature

/// 사용자 계정 / 설정 / 디바이스 토큰 API
@DependencyClient
struct UserClient {
    var fetchUserAccountInfo: @Sendable () async throws -> UserAccountInfoData
    var fetchNotificationSettings: @Sendable () async throws -> UserNotificationSettingsData
    var updateNotificationSetting: @Sendable (_ pushEnabled: Bool) async throws -> Void
    var fetchUserName: @Sendable () async throws -> String
    var updateUserName: @Sendable (_ name: String) async throws -> Void
    var fetchCommuteInfo: @Sendable () async throws -> CommuteInfoData
    var updateCommuteInfo: @Sendable (_ startTime: String, _ endTime: String, _ usageTime: Int) async throws -> Void
    var withdrawUser: @Sendable () async throws -> Void
    var fetchOnboardingStatus: @Sendable () async throws -> Bool
    var registerDeviceToken: @Sendable (_ token: String, _ deviceType: String) async throws -> Void
    var deleteDeviceToken: @Sendable (_ token: String, _ deviceType: String) async throws -> Void
}

extension UserClient: DependencyKey {
    static let liveValue: UserClient = {
        let api = APIClient.liveValue
        return UserClient(
            fetchUserAccountInfo: { try await api.fetchUserAccountInfo() },
            fetchNotificationSettings: { try await api.fetchNotificationSettings() },
            updateNotificationSetting: { try await api.updateNotificationSetting(pushEnabled: $0) },
            fetchUserName: { try await api.fetchUserName() },
            updateUserName: { try await api.updateUserName(name: $0) },
            fetchCommuteInfo: { try await api.fetchCommuteInfo() },
            updateCommuteInfo: { try await api.updateCommuteInfo(startTime: $0, endTime: $1, usageTime: $2) },
            withdrawUser: { try await api.withdrawUser() },
            fetchOnboardingStatus: { try await api.fetchOnboardingStatus() },
            registerDeviceToken: { try await api.registerDeviceToken(token: $0, deviceType: $1) },
            deleteDeviceToken: { try await api.deleteDeviceToken(token: $0, deviceType: $1) }
        )
    }()

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = UserClient()
}

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}
