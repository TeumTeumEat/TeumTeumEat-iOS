//
//  GoalClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import OnboardingFeature

/// 학습 목표(주제) API
@DependencyClient
struct GoalClient {
    var fetchCurrentGoal: @Sendable () async throws -> GoalResponse
    var fetchGoals: @Sendable () async throws -> [GoalResponse]
    var updateCurrentGoal: @Sendable (_ goalId: Int) async throws -> Void
}

extension GoalClient: DependencyKey {
    static let liveValue: GoalClient = {
        let api = APIClient.liveValue
        return GoalClient(
            fetchCurrentGoal: { try await api.fetchCurrentGoal() },
            fetchGoals: { try await api.fetchGoals() },
            updateCurrentGoal: { try await api.updateCurrentGoal(goalId: $0) }
        )
    }()

    // 테스트에서 override하지 않은 API가 호출되면 테스트 실패
    static let testValue = GoalClient()
}

extension DependencyValues {
    var goalClient: GoalClient {
        get { self[GoalClient.self] }
        set { self[GoalClient.self] = newValue }
    }
}
