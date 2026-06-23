//
//  OnboardingLoadingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import CoreNetwork

@Reducer
public struct OnboardingLoadingFeature {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        public var loadingSteps: [LoadingStep]
        public var currentStepIndex: Int = 0

        public var onboardingData: OnboardingData
        public var isOnboarding: Bool = true
        public var animationCompleted: Bool = false
        public var apiCompleted: Bool = false
        public var isFileUpload: Bool = false
        public var apiError: APIError?

        // SSE 관련
        public var sseGoalId: Int? = nil
        public var sseDocumentId: Int? = nil
        public var sseProgress: Double = 0.0
        public var remainingSeconds: Int? = nil
        public var totalInitialMs: Int? = nil
        public var isOverdue: Bool = false

        @Presents public var errorAlert: AlertState<Action.ErrorAlert>?
        @Presents public var confirmCancelAlert: AlertState<Action.ConfirmCancelAlert>?

        public var canProceed: Bool {
            if isFileUpload {
                return apiCompleted && apiError == nil
            }
            return animationCompleted && apiCompleted && apiError == nil
        }

        public init(onboardingData: OnboardingData, isOnboarding: Bool = true, isFileUpload: Bool = false) {
            self.onboardingData = onboardingData
            self.isOnboarding = isOnboarding
            self.isFileUpload = isFileUpload

            if isFileUpload {
                self.loadingSteps = [
                    LoadingStep(title: "PDF 파일 업로드 중", isCompleted: false),
                    LoadingStep(title: "문서 등록 중", isCompleted: false),
                    LoadingStep(title: "퀴즈 생성 중", isCompleted: false)
                ]
            } else {
                self.loadingSteps = [
                    LoadingStep(title: "카테고리 퀴즈 생성 중", isCompleted: false),
                    LoadingStep(title: "맞춤형 문제 준비 중", isCompleted: false),
                    LoadingStep(title: "최적화 진행 중", isCompleted: false)
                ]
            }
        }

        public struct LoadingStep: Equatable, Identifiable {
            public let id = UUID()
            public let title: String
            public var isCompleted: Bool
        }
    }

    public enum Action {
        case onAppear
        case updateProgress
        case animationCompleted

        // 공통 API
        case submitOnboardingData
        case apiSuccess
        case apiFailure(APIError)
        case checkCompletion
        case loadingCompleted

        // 파일 업로드 전용
        case uploadStepCompleted
        case sseStartRequested(goalId: Int, documentId: Int)
        case sseEventReceived(SSEDocumentStatus)
        case sseConnectionFailed(String)
        case sseTimeoutTriggered
        case tickTimer

        case errorAlert(PresentationAction<ErrorAlert>)
        case confirmCancelAlert(PresentationAction<ConfirmCancelAlert>)
        case delegate(Delegate)

        public enum ErrorAlert: Equatable {
            case retry
            case cancel
            case confirmNonRetryable
        }

        public enum ConfirmCancelAlert: Equatable {
            case confirmCancel
            case goBack
        }

        public enum Delegate: Equatable {
            case onboardingCancelled
        }
    }

    private enum CancelID: Hashable {
        case sseStream
        case timer
        case sseTimeout
    }

    private static let clientTimeoutSeconds: Int = 300 // 5분

    @Dependency(\.onboardingAPIClient) var apiClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: - onAppear
            case .onAppear:
                if state.isFileUpload {
                    return .send(.submitOnboardingData)
                } else {
                    return .merge(
                        .run { send in await send(.updateProgress) },
                        .send(.submitOnboardingData)
                    )
                }

            // MARK: - 카테고리 애니메이션
            case .updateProgress:
                guard state.currentStepIndex < state.loadingSteps.count else {
                    return .send(.animationCompleted)
                }
                state.loadingSteps[state.currentStepIndex].isCompleted = true
                state.currentStepIndex += 1
                return .run { send in
                    try await Task.sleep(for: .seconds(1.0))
                    await send(.updateProgress)
                }

            case .animationCompleted:
                state.animationCompleted = true
                return .send(.checkCompletion)

            // MARK: - API 호출
            case .submitOnboardingData:
                let data = state.onboardingData
                let isOnboarding = state.isOnboarding

                return .run { send in
                    do {
                        if isOnboarding {
                            guard let leaveTime = data.leaveHomeTime,
                                  let returnTime = data.returnHomeTime else {
                                throw APIError.serverError(
                                    code: "CLIENT-001",
                                    message: "출퇴근 시간이 설정되지 않았습니다.",
                                    details: nil
                                )
                            }
                            try await apiClient.updateCommuteInfo(
                                leaveTime.toString(format: "HH:mm:ss"),
                                returnTime.toString(format: "HH:mm:ss"),
                                data.dailyUsageMinutes
                            )
                            print("User info updated - Onboarding")
                        }

                        if data.contentType == .fileUpload {
                            guard let fileURL = data.uploadedFileURL else {
                                throw APIError.serverError(
                                    code: "CLIENT-002",
                                    message: "업로드할 파일이 선택되지 않았습니다.",
                                    details: nil
                                )
                            }
                            let fileName = fileURL.lastPathComponent
                            let fileSize = (try? fileURL.fileSize()) ?? 0

                            // Step 1: Presigned URL + S3 업로드
                            print("[UPLOAD] Step1: presigned URL 요청")
                            let presignedData = try await apiClient.getPresignedURL(fileName, fileSize)
                            print("[UPLOAD] Step1: S3 업로드 시작")
                            try await apiClient.uploadFileToS3(
                                fileURL,
                                presignedData.presignedUrl
                            )
                            print("[UPLOAD] Step1: S3 업로드 완료")
                            await send(.uploadStepCompleted)

                            // Step 2: 목표 생성 + 문서 등록
                            let difficulty = mapDifficulty(data.difficulty)
                            let prompt = data.customPrompt.isEmpty ? nil : data.customPrompt
                            print("[UPLOAD] Step2: 목표 생성")
                            try await apiClient.createGoal(
                                .document,
                                "\(data.programWeeks)주",
                                difficulty,
                                prompt,
                                nil
                            )

                            print("[UPLOAD] Step2: 목표 조회")
                            let goals = try await apiClient.fetchGoals()
                            guard let latestGoal = goals
                                .filter({ $0.type == "DOCUMENT" })
                                .max(by: { $0.goalId < $1.goalId }) else {
                                throw APIError.serverError(
                                    code: "CLIENT-003",
                                    message: "생성된 목표를 찾을 수 없습니다.",
                                    details: nil
                                )
                            }
                            print("[UPLOAD] Step2: latestGoal.goalId=\(latestGoal.goalId)")

                            print("[UPLOAD] Step3: 문서 등록")
                            try await apiClient.registerDocument(
                                latestGoal.goalId,
                                fileName,
                                presignedData.key
                            )
                            print("[UPLOAD] Step3: 현재 목표 조회")
                            let currentGoal = try await apiClient.fetchCurrentGoal()
                            guard let documentId = currentGoal.documentId else {
                                throw APIError.serverError(
                                    code: "CLIENT-005",
                                    message: "문서 ID를 찾을 수 없습니다.",
                                    details: nil
                                )
                            }
                            print("[UPLOAD] Step3: documentId=\(documentId), SSE 시작")
                            await send(.sseStartRequested(goalId: latestGoal.goalId, documentId: documentId))

                        } else {
                            try await handleCategoryFlow(data: data)
                            await send(.apiSuccess)
                        }

                    } catch let error as APIError {
                        await send(.apiFailure(error))
                    } catch {
                        await send(.apiFailure(.networkError(error)))
                    }
                }

            // MARK: - 파일 업로드 진행 단계
            case .uploadStepCompleted:
                state.loadingSteps[0].isCompleted = true
                return .none

            case .sseStartRequested(let goalId, let documentId):
                state.sseGoalId = goalId
                state.sseDocumentId = documentId
                state.loadingSteps[1].isCompleted = true
                print("[SSE] 연결 시작 - goalId: \(goalId), documentId: \(documentId)")

                let sseEffect = Effect<Action>.run { send in
                    do {
                        for try await event in apiClient.connectDocumentSSE(
                            goalId,
                            documentId,
                            nil
                        ) {
                            await send(.sseEventReceived(event))
                            if case .completed = event { break }
                            if case .failed = event { break }
                        }
                    } catch {
                        await send(.sseConnectionFailed(error.localizedDescription))
                    }
                }
                .cancellable(id: CancelID.sseStream)

                let timeoutEffect = Effect<Action>.run { send in
                    try await Task.sleep(for: .seconds(OnboardingLoadingFeature.clientTimeoutSeconds))
                    await send(.sseTimeoutTriggered)
                }
                .cancellable(id: CancelID.sseTimeout)

                return .merge(sseEffect, timeoutEffect)

            case .sseEventReceived(let event):
                switch event {
                case .connected:
                    print("[SSE] 연결됨")

                case .pending:
                    print("[SSE] 처리 대기 중")
                    state.sseProgress = 0.05

                case .processing(let remainMs):
                    print("[SSE] 처리 중 - 남은 시간: \(remainMs)ms")

                    // remain_ms = 0 → 서버가 예상 시간을 모름, 99%에서 대기
                    guard remainMs > 0 else {
                        state.sseProgress = 0.99
                        state.isOverdue = true
                        state.remainingSeconds = nil
                        return .cancel(id: CancelID.timer)
                    }

                    state.isOverdue = false
                    if state.totalInitialMs == nil {
                        state.totalInitialMs = remainMs
                    }
                    let total = state.totalInitialMs ?? remainMs
                    state.remainingSeconds = max(0, remainMs / 1000)
                    state.sseProgress = max(0.05, Double(total - remainMs) / Double(total))

                    let secondsToCount = remainMs / 1000
                    return .run { send in
                        for _ in 0..<secondsToCount {
                            try await Task.sleep(for: .seconds(1))
                            await send(.tickTimer)
                        }
                    }
                    .cancellable(id: CancelID.timer, cancelInFlight: true)

                case .completed:
                    print("[SSE] 완료")
                    state.sseProgress = 1.0
                    state.remainingSeconds = 0
                    state.isOverdue = false
                    state.loadingSteps[2].isCompleted = true
                    state.apiCompleted = true
                    return .merge(
                        .cancel(id: CancelID.timer),
                        .cancel(id: CancelID.sseTimeout),
                        .send(.checkCompletion)
                    )

                case .failed(let reason):
                    print("[SSE] 실패 - \(reason.userMessage)")
                    return .merge(
                        .cancel(id: CancelID.timer),
                        .cancel(id: CancelID.sseStream),
                        .cancel(id: CancelID.sseTimeout),
                        .send(.apiFailure(.serverError(
                            code: "SSE-FAILED",
                            message: reason.userMessage,
                            details: nil
                        )))
                    )
                }
                return .none

            case .sseConnectionFailed(let message):
                print("[SSE] 연결 실패: \(message)")
                return .merge(
                    .cancel(id: CancelID.sseTimeout),
                    .send(.apiFailure(.serverError(
                        code: "SSE-CONNECTION",
                        message: message,
                        details: nil
                    )))
                )

            case .sseTimeoutTriggered:
                print("[SSE] 클라이언트 타임아웃 (\(OnboardingLoadingFeature.clientTimeoutSeconds)초)")
                return .merge(
                    .cancel(id: CancelID.sseStream),
                    .cancel(id: CancelID.timer),
                    .send(.apiFailure(.serverError(
                        code: "SSE-CLIENT-TIMEOUT",
                        message: "처리 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.",
                        details: nil
                    )))
                )

            case .tickTimer:
                guard let remaining = state.remainingSeconds, remaining > 0 else { return .none }
                state.remainingSeconds = remaining - 1
                if let total = state.totalInitialMs, total > 0 {
                    let remainingMs = (remaining - 1) * 1000
                    state.sseProgress = max(0.05, min(0.95, Double(total - remainingMs) / Double(total)))
                }
                return .none

            // MARK: - 공통 완료 / 에러
            case .apiSuccess:
                state.apiCompleted = true
                state.apiError = nil
                return .send(.checkCompletion)

            case .apiFailure(let error):
                state.apiCompleted = false
                state.apiError = error
                print("API Error: \(error.localizedDescription)")

                if error.isNonRetryable {
                    state.errorAlert = AlertState {
                        TextState("파일 업로드 실패")
                    } actions: {
                        ButtonState(action: .confirmNonRetryable) { TextState("확인") }
                    } message: {
                        TextState(error.userFriendlyMessage)
                    }
                } else {
                    state.errorAlert = AlertState {
                        TextState("오류가 발생했습니다")
                    } actions: {
                        ButtonState(action: .retry) { TextState("다시 시도") }
                        ButtonState(role: .cancel, action: .cancel) { TextState("취소") }
                    } message: {
                        TextState(error.userFriendlyMessage)
                    }
                }
                return .none

            case .errorAlert(.presented(.retry)):
                state.errorAlert = nil
                state.apiError = nil
                state.apiCompleted = false

                for index in state.loadingSteps.indices {
                    state.loadingSteps[index].isCompleted = false
                }

                if state.isFileUpload {
                    state.sseProgress = 0.0
                    state.remainingSeconds = nil
                    state.totalInitialMs = nil
                    state.sseGoalId = nil
                    state.sseDocumentId = nil
                    state.isOverdue = false
                    return .merge(
                        .cancel(id: CancelID.sseStream),
                        .cancel(id: CancelID.timer),
                        .cancel(id: CancelID.sseTimeout),
                        .send(.submitOnboardingData)
                    )
                } else {
                    state.currentStepIndex = 0
                    state.animationCompleted = false
                    return .merge(
                        .run { send in await send(.updateProgress) },
                        .send(.submitOnboardingData)
                    )
                }

            case .errorAlert(.presented(.confirmNonRetryable)):
                state.errorAlert = nil
                return .send(.delegate(.onboardingCancelled))

            case .errorAlert(.presented(.cancel)):
                state.errorAlert = nil
                state.confirmCancelAlert = AlertState {
                    TextState("정말 취소하시겠어요?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmCancel) { TextState("취소") }
                    ButtonState(role: .cancel, action: .goBack) { TextState("돌아가기") }
                } message: {
                    TextState("처음부터 다시 입력해야 합니다.")
                }
                return .none

            case .errorAlert:
                return .none

            case .confirmCancelAlert(.presented(.confirmCancel)):
                state.confirmCancelAlert = nil
                return .send(.delegate(.onboardingCancelled))

            case .confirmCancelAlert(.presented(.goBack)):
                state.confirmCancelAlert = nil
                if let error = state.apiError {
                    state.errorAlert = AlertState {
                        TextState("오류가 발생했습니다")
                    } actions: {
                        ButtonState(action: .retry) { TextState("다시 시도") }
                        ButtonState(role: .cancel, action: .cancel) { TextState("취소") }
                    } message: {
                        TextState(error.userFriendlyMessage)
                    }
                }
                return .none

            case .confirmCancelAlert:
                return .none

            case .delegate:
                return .none

            case .checkCompletion:
                if state.canProceed {
                    return .send(.loadingCompleted)
                }
                return .none

            case .loadingCompleted:
                print("로딩 완료 - Complete 화면으로 이동")
                if UserDefaults.standard.bool(forKey: "shouldRegisterDeviceToken") {
                    return .run { _ in
                        await MainActor.run {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
                return .none
            }
        }
        .ifLet(\.$errorAlert, action: \.errorAlert)
        .ifLet(\.$confirmCancelAlert, action: \.confirmCancelAlert)
    }

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
        try await apiClient.createGoal(
            .category,
            "\(data.programWeeks)주",
            difficulty,
            prompt,
            categoryId
        )
    }

    private func mapDifficulty(_ difficulty: String?) -> CreateGoalRequest.Difficulty {
        switch difficulty {
        case "쉬움": return .easy
        case "보통": return .medium
        case "어려움": return .hard
        default: return .medium
        }
    }
}
