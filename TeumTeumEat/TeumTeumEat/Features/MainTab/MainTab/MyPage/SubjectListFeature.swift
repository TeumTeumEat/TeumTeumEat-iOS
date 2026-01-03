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
    }
    
    enum Action {
        case onAppear
        case goalsResponse(Result<[GoalResponse], Error>)
        case backTapped
        case subjectTapped(Subject)
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
                print("API Response - Goals count: \(goals.count)")
                print("Goals data: \(goals)")
                state.subjects = goals.map { Subject(from: $0) }
                print("Goals loaded successfully - Count: \(goals.count)")
                print(" Final subjects count: \(state.subjects.count)")
                return .none
                
            case .goalsResponse(.failure(let error)):
                state.isLoading = false
                if let apiError = error as? APIError {
                    state.errorMessage = apiError.localizedDescription
                } else {
                    state.errorMessage = "목록을 불러오는데 실패했습니다."
                }
                print("Failed to load goals: \(error)")
                return .none
                
            case .subjectTapped(let subject):
                return .send(.delegate(.subjectSelected(subject)))
                
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
    let name: String
    let duration: String
    let difficulty: String
    let category: [String]
    let description: String
}

