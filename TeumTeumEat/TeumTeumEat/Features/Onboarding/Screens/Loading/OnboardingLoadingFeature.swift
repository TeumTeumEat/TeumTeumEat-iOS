//
//  OnboardingLoadingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct OnboardingLoadingFeature {
    @ObservableState
    struct State: Equatable {
        var loadingSteps: [LoadingStep] = [
            LoadingStep(title: "카테고리 퀴즈 생성 중", isCompleted: false),
            LoadingStep(title: "맞춤형 문제 준비 중", isCompleted: false),
            LoadingStep(title: "최적화 진행 중", isCompleted: false)
        ]
        var currentStepIndex: Int = 0
        
        // API 관련 상태
        var onboardingData: OnboardingData
        var isOnboarding: Bool = true
        var animationCompleted: Bool = false
        var apiCompleted: Bool = false
        var apiError: APIError?
        
        // 완료 여부
        var canProceed: Bool {
            animationCompleted && apiCompleted && apiError == nil
        }
        
        struct LoadingStep: Equatable, Identifiable {
            let id = UUID()
            let title: String
            var isCompleted: Bool
        }
    }
    
    enum Action {
        case onAppear
        case updateProgress
        case animationCompleted
        
        // API 관련 액션
        case submitOnboardingData
        case apiSuccess
        case apiFailure(APIError)
        case checkCompletion
        
        case loadingCompleted
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 애니메이션과 API 호출 병렬 처리
                return .merge(
                    // 1. 애니메이션 (3초 고정)
                    .run { send in
                        await send(.updateProgress)
                    },
                    // 2. API 호출
                    .send(.submitOnboardingData)
                )
                
            case .updateProgress:
                guard state.currentStepIndex < state.loadingSteps.count else {
                    return .send(.animationCompleted)
                }
                
                state.loadingSteps[state.currentStepIndex].isCompleted = true
                state.currentStepIndex += 1
                
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.updateProgress)
                }
                
            case .animationCompleted:
                state.animationCompleted = true
                return .send(.checkCompletion)
                
            case .submitOnboardingData:
                let data = state.onboardingData
                let isOnboarding = state.isOnboarding
                
                return .run { send in
                    do {
                        // 온보딩일 때만 유저 정보 업데이트
                        if isOnboarding {
                            // Step 1 & 2: 유저 이름 + 출퇴근 정보 병렬 처리
                            try await withThrowingTaskGroup(of: Void.self) { group in
                                // Task 1: 이름 수정
                                group.addTask {
                                    try await apiClient.updateUserName(name: data.userName)
                                }
                                
                                // Task 2: 출퇴근 정보 수정
                                group.addTask {
                                    guard let leaveTime = data.leaveHomeTime,
                                          let returnTime = data.returnHomeTime else {
                                        throw APIError.serverError(
                                            code: "CLIENT-001",
                                            message: "출퇴근 시간이 설정되지 않았습니다.",
                                            details: nil
                                        )
                                    }
                                    
                                    let startTimeString = leaveTime.toString(format: "HH:mm:ss")
                                    let endTimeString = returnTime.toString(format: "HH:mm:ss")
                                    
                                    try await apiClient.updateCommuteInfo(
                                        startTime: startTimeString,
                                        endTime: endTimeString,
                                        usageTime: data.dailyUsageMinutes
                                    )
                                }
                                
                                // 모든 Task 완료 대기
                                try await group.waitForAll()
                            }
                            
                            print("User info updated (parallel) - Onboarding")
                        } else {
                            print("Skipping user info update - Adding subject")
                        }
                        
                        // Step 3-7: contentType에 따라 분기 (공통)
                        if data.contentType == .fileUpload {
                            // 파일 업로드 플로우
                            try await handleFileUploadFlow(data: data)
                        } else {
                            // 카테고리 선택 플로우
                            try await handleCategoryFlow(data: data)
                        }
                        
                        await send(.apiSuccess)
                        
                    } catch let error as APIError {
                        await send(.apiFailure(error))
                    } catch {
                        await send(.apiFailure(.networkError(error)))
                    }
                }
                
            case .apiSuccess:
                state.apiCompleted = true
                state.apiError = nil
                return .send(.checkCompletion)
                
            case .apiFailure(let error):
                state.apiCompleted = false
                state.apiError = error
                print("API Error: \(error.localizedDescription)")
                // TODO: 에러 UI 표시
                return .none
                
            case .checkCompletion:
                if state.canProceed {
                    return .send(.loadingCompleted)
                }
                return .none
                
            case .loadingCompleted:
                print("온보딩 완료! Complete 화면으로 이동")
                return .none
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 파일 업로드 플로우
    private func handleFileUploadFlow(data: OnboardingData) async throws {
        guard let fileURL = data.uploadedFileURL else {
            throw APIError.serverError(
                code: "CLIENT-002",
                message: "업로드할 파일이 선택되지 않았습니다.",
                details: nil
            )
        }
        
        let fileName = fileURL.lastPathComponent
        
        // Step 3: presignedURL 요청
        let presignedData = try await apiClient.getPresignedURL(fileName: fileName)
        
        // Step 4: S3에 파일 업로드
        try await apiClient.uploadFileToS3(
            fileURL: fileURL,
            presignedURL: presignedData.presignedUrl
        )
        
        // Step 5: 목표 생성 (DOCUMENT)
        let difficulty = mapDifficulty(data.difficulty)
        let prompt = data.customPrompt.isEmpty ? nil : data.customPrompt
        
        try await apiClient.createGoal(
            type: .document,
            studyPeriod: "\(data.programWeeks)주",
            difficulty: difficulty,
            prompt: prompt,
            categoryId: nil  // DOCUMENT 타입은 categoryId 없음
        )
        
        // Step 6: 전체 목표 조회 → goalId 가져오기
        let goals = try await apiClient.fetchGoals()
        guard let latestGoal = goals
            .filter({ $0.type == "DOCUMENT" })     // DOCUMENT만 필터링
            .max(by: { $0.goalId < $1.goalId })    // goalId가 가장 큰 것
        else {
            throw APIError.serverError(
                code: "CLIENT-003",
                message: "생성된 목표를 찾을 수 없습니다.",
                details: nil
            )
        }
        
        print("Latest DOCUMENT goal found - goalId: \(latestGoal.goalId)")
        
        // Step 7: 문서 등록
        try await apiClient.registerDocument(
            goalId: latestGoal.goalId,
            fileName: fileName,
            fileKey: presignedData.key
        )
    }
    
    /// 카테고리 선택 플로우
    private func handleCategoryFlow(data: OnboardingData) async throws {
        guard let categoryId = data.selectedDetailCategory?.id else {
            throw APIError.serverError(
                code: "CLIENT-004",
                message: "카테고리가 선택되지 않았습니다.",
                details: nil
            )
        }
        
        let difficulty = mapDifficulty(data.difficulty)
        let prompt = data.customPrompt.isEmpty ? nil : data.customPrompt
        
        // Step 3: 목표 생성 (CATEGORY)
        try await apiClient.createGoal(
            type: .category,
            studyPeriod: "\(data.programWeeks)주",
            difficulty: difficulty,
            prompt: prompt,
            categoryId: categoryId
        )
    }
    
    /// 난이도 매핑
    private func mapDifficulty(_ difficulty: String?) -> CreateGoalRequest.Difficulty {
        switch difficulty {
        case "쉬움": return .easy
        case "보통": return .medium
        case "어려움": return .hard
        default: return .medium
        }
    }
}
