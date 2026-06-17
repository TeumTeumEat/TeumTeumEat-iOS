//
//  QuizGuideFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/2/26.
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

@Reducer
struct QuizGuideFeature {
    @ObservableState
    struct State: Equatable {
        // 안내 화면 상태
        var isCheckboxSelected: Bool = false
        var isSubmitting: Bool = false
        var quizCount: Int = 3
    }

    enum Action {
        case onAppear
        case commuteInfoLoaded(Result<CommuteInfoData, Error>)
        case checkboxToggled
        case startQuizButtonTapped
        case updateQuizGuideResponse(Result<Void, Error>)
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuiz  // 퀴즈 시작
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.commuteInfoLoaded(
                        Result { try await apiClient.fetchCommuteInfo() }
                    ))
                }

            case .commuteInfoLoaded(.success(let info)):
                switch info.usageTime {
                case 5:  state.quizCount = 3
                case 7:  state.quizCount = 5
                case 10: state.quizCount = 7
                default: state.quizCount = info.usageTime >= 15 ? 10 : 3
                }
                return .none

            case .commuteInfoLoaded(.failure):
                return .none

            case .checkboxToggled:
                state.isCheckboxSelected.toggle()
                print("체크박스 토글: \(state.isCheckboxSelected)")
                return .none
                
            case .startQuizButtonTapped:
                // 체크박스가 선택된 경우에만 API 호출
                if state.isCheckboxSelected {
                    state.isSubmitting = true
                    return .run { send in
                        do {
                            try await apiClient.updateQuizGuideSeen()
                            await send(.updateQuizGuideResponse(.success(())))
                        } catch {
                            await send(.updateQuizGuideResponse(.failure(error)))
                        }
                    }
                } else {
                    // 체크박스 미선택 시 바로 퀴즈 시작
                    return .send(.delegate(.startQuiz))
                }
                
            case .updateQuizGuideResponse(.success):
                state.isSubmitting = false
                print("퀴즈 가이드 설정 업데이트 성공")
                return .send(.delegate(.startQuiz))
                
            case .updateQuizGuideResponse(.failure(let error)):
                state.isSubmitting = false
                print("퀴즈 가이드 설정 업데이트 실패: \(error)")
                // 실패해도 퀴즈는 진행
                return .send(.delegate(.startQuiz))
                
            case .delegate:
                return .none
            }
        }
    }
}
