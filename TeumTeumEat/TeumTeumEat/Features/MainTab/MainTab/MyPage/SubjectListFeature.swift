//
//  SubjectListFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SubjectListFeature {
    @ObservableState
    struct State: Equatable {
        var subjects: [Subject] = []
        var isLoading: Bool = false
        var errorMessage: String?
        var isUpdating: Bool = false  // 👈 추가 (업데이트 중 상태)
    }
    
    enum Action {
        case onAppear
        case goalsResponse(Result<[GoalResponse], Error>)
        case backTapped
        case subjectTapped(Subject)
        case updateGoalResponse(Result<Void, Error>)  // 👈 추가
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
            case subjectSelected(Subject)
        }
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let goals = try await apiClient.fetchGoals()
                        await send(.goalsResponse(.success(goals)))
                    } catch {
                        await send(.goalsResponse(.failure(error)))
                    }
                }
                
            case .goalsResponse(.success(let goals)):
                state.isLoading = false
                print("✅ API Response - Goals count: \(goals.count)")
                state.subjects = goals.map { Subject(from: $0) }
                print("✅ Final subjects count: \(state.subjects.count)")
                return .none
                
            case .goalsResponse(.failure(let error)):
                state.isLoading = false
                if let apiError = error as? APIError {
                    state.errorMessage = apiError.localizedDescription
                } else {
                    state.errorMessage = "목록을 불러오는데 실패했습니다."
                }
                print("❌ Failed to load goals: \(error)")
                return .none
                
            case .subjectTapped(let subject):
                print("🔍 Subject tapped - goalId: \(subject.goalId)")
                state.isUpdating = true
                
                return .run { send in
                    do {
                        try await apiClient.updateCurrentGoal(goalId: subject.goalId)
                        await send(.updateGoalResponse(.success(())))
                    } catch {
                        await send(.updateGoalResponse(.failure(error)))
                    }
                }
                
            case .updateGoalResponse(.success):
                state.isUpdating = false
                print("✅ Goal updated successfully")
                // 성공 시 delegate로 선택된 subject 전달하고 화면 닫기
                return .run { [subjects = state.subjects] send in
                    // 업데이트된 목표 찾기
                    if let updatedSubject = subjects.first(where: { $0.goalId == $0.goalId }) {
                        await send(.delegate(.subjectSelected(updatedSubject)))
                    }
                }
                
            case .updateGoalResponse(.failure(let error)):
                state.isUpdating = false
                print("❌ Failed to update goal: \(error)")
                if let apiError = error as? APIError {
                    state.errorMessage = apiError.localizedDescription
                } else {
                    state.errorMessage = "목표 업데이트에 실패했습니다."
                }
                return .none
                
            case .backTapped:
                return .send(.delegate(.dismissed))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct Subject: Equatable, Identifiable {
    let id: String
    let goalId: Int
    let name: String
    let duration: String
    let difficulty: String
    let category: [String]
    let description: String
}

