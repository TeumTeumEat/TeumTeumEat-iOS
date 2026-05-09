//
//  HomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import Lottie

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        var isTodayQuizCompleted: Bool = false
        var isExpired: Bool = false
        var showExpiredAlert: Bool = false
        
        // API 관련 상태
        var currentGoal: GoalResponse?
        var quizStatus: UserQuizStatusData?
        var categoryDocument: CategoryDocumentData?
        var pdfSummary: PDFSummaryData?
        var quizzes: [UserQuiz] = []
        var calendarData: CalendarHistoryData?
        
        var isLoading: Bool = false
        var errorMessage: String?

        var showCouponModal: Bool = false
        var isUsingCoupon: Bool = false

        var availableQuizCount: Int {
            quizStatus?.availableQuizCount ?? 0
        }

        var canIssueCoupon: Bool {
            quizStatus?.canIssueCoupon ?? true
        }
        
        var currentSnackImage: String {
            guard !isExpired else { return "done" }
            guard !isTodayQuizCompleted else { return "done" }
            guard let goal = currentGoal else { return "burger" }

            if goal.type == "CATEGORY", let categoryDoc = categoryDocument {
                return SnackImageMapper.snackImage(for: categoryDoc.documentId, createdAt: categoryDoc.createdAt)
            }

            if goal.type == "DOCUMENT", let pdfSum = pdfSummary {
                return SnackImageMapper.snackImage(for: pdfSum.documentId, createdAt: pdfSum.createdAt)
            }

            return "burger"
        }
    }
    
    enum Action {
        case onAppear
        
        case fetchCalendarHistoryResponse(Result<CalendarHistoryData, Error>)
        
        // Step 1: 현재 목표 조회
        case fetchCurrentGoalResponse(Result<GoalResponse, Error>)
        
        // Step 2: 퀴즈 상태 확인
        case fetchQuizStatusResponse(Result<UserQuizStatusData, Error>)
        
        // Step 3: 요약글 조회 (Goal Type에 따라)
        case fetchCategoryDocumentResponse(Result<CategoryDocumentData, Error>)
        case fetchPDFSummaryResponse(Result<PDFSummaryData, Error>)
        
        // Step 4: 퀴즈 조회
        case fetchQuizzesResponse(Result<[UserQuiz], Error>)
        
        case settingTapped
        case toggleQuizStatus
        case characterEatTapped
        case speechBubbleTapped
        case dismissCouponModal
        case couponUseTapped
        case adRewardEarned
        case postAdRewardResponse(Result<Void, Error>)
        case refreshQuizStatusResponse(Result<UserQuizStatusData, Error>)
        case expiredAlertDismissed
        case expiredNewGoalTapped
        case expiredSelectExistingTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case startQuizFlow(
            quizzes: [UserQuiz],
            summaryData: ContentSummaryFeature.State,
            isFirstTime: Bool
        )
        case openMyPageRequested
        case startNewGoalTapped
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                
                // 병렬 처리: 캘린더 조회 + 목표 조회
                let now = Date()
                let calendar = Calendar.current
                let year = calendar.component(.year, from: now)
                let month = calendar.component(.month, from: now)
                
                return .merge(
                    // 캘린더 조회 (독립적)
                    .run { send in
                        do {
                            let calendarData = try await apiClient.fetchCalendarHistory(year: year, month: month)
                            await send(.fetchCalendarHistoryResponse(.success(calendarData)))
                        } catch {
                            await send(.fetchCalendarHistoryResponse(.failure(error)))
                        }
                    },
                    // 목표 조회 (Step 1 시작)
                    .run { send in
                        do {
                            let goal = try await apiClient.fetchCurrentGoal()
                            await send(.fetchCurrentGoalResponse(.success(goal)))
                        } catch {
                            await send(.fetchCurrentGoalResponse(.failure(error)))
                        }
                    }
                )
                
            // 캘린더 조회 완료 (독립적 처리)
            case .fetchCalendarHistoryResponse(.success(let calendarData)):
                state.calendarData = calendarData
                state.fireCount = calendarData.currentStreak
                state.stampCount = calendarData.totalStamps
                return .none

            case .fetchCalendarHistoryResponse(.failure(let error)):
                print("[Home] 캘린더 조회 실패: \(error)")
                return .none
                
            // Step 1 완료 → Step 2 시작
            case .fetchCurrentGoalResponse(.success(let goal)):
                state.isExpired = goal.isExpired
                if goal.isExpired {
                    state.currentGoal = goal
                    state.isLoading = false
                    print("[Home] Goal 만료")
                    return .none
                }

                let previousGoal = state.currentGoal
                state.currentGoal = goal

                let isNewGoal: Bool = {
                    guard let prev = previousGoal else { return true }
                    if prev.type != goal.type { return true }
                    if goal.type == "CATEGORY" { return prev.category?.categoryId != goal.category?.categoryId }
                    if goal.type == "DOCUMENT" { return prev.documentId != goal.documentId }
                    return false
                }()

                if isNewGoal {
                    state.categoryDocument = nil
                    state.pdfSummary = nil
                    state.quizzes = []
                }

                print("[Home] Step1 완료 - type: \(goal.type)")
                
                // Step 2: 퀴즈 상태는 항상 확인 (날짜 변경 감지용)
                return .run { send in
                    do {
                        let status = try await apiClient.fetchUserQuizStatus()
                        await send(.fetchQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.fetchQuizStatusResponse(.failure(error)))
                    }
                }
                
            case .fetchCurrentGoalResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "목표 조회 실패: \(error.localizedDescription)"
                print("[Home] Step1 실패: \(error)")
                return .none
                
            // Step 2 완료 → Step 3 시작
            case .fetchQuizStatusResponse(.success(let status)):
                let wasCompletedYesterday = state.isTodayQuizCompleted
                state.quizStatus = status
                if !state.isUsingCoupon {
                    state.isTodayQuizCompleted = status.hasSolvedToday
                }
                state.isUsingCoupon = false

                print("[Home] Step2 완료 - hasSolvedToday: \(status.hasSolvedToday)")

                if status.isCompleted {
                    state.isExpired = true
                    state.isLoading = false
                    print("[Home] Goal 완료 - 모든 퀴즈 세트 완료")
                    return .none
                }

                if wasCompletedYesterday && !status.hasSolvedToday {
                    state.categoryDocument = nil
                    state.pdfSummary = nil
                    state.quizzes = []
                }
                
                guard let goal = state.currentGoal else {
                    state.errorMessage = "목표 정보가 없습니다"
                    state.isLoading = false
                    return .none
                }
                
                // Step 3: Goal Type에 따라 요약글 조회
                if goal.type == "CATEGORY" {
                    // 카테고리는 ContentSummaryFeature가 SSE로 직접 처리
                    state.isLoading = false
                    return .none

                } else if goal.type == "DOCUMENT" {
                    if let pdfSum = state.pdfSummary {
                        return .run { [docId = pdfSum.documentId] send in
                            do {
                                let quizzes = try await apiClient.fetchUserQuizzes(
                                    documentId: docId,
                                    documentType: .document
                                )
                                await send(.fetchQuizzesResponse(.success(quizzes)))
                            } catch {
                                await send(.fetchQuizzesResponse(.failure(error)))
                            }
                        }
                    }
                    
                    // PDF 문서 조회
                    guard let documentId = goal.documentId else {
                        state.errorMessage = "문서 ID가 없습니다"
                        state.isLoading = false
                        return .none
                    }
                    
                    return .run { [goalId = goal.goalId] send in
                        do {
                            let summary = try await apiClient.fetchDailyPDFSummary(
                                goalId: goalId,
                                documentId: documentId
                            )
                            await send(.fetchPDFSummaryResponse(.success(summary)))
                        } catch {
                            await send(.fetchPDFSummaryResponse(.failure(error)))
                        }
                    }
                    
                } else {
                    // 알 수 없는 타입
                    state.errorMessage = "알 수 없는 Goal Type: \(goal.type)"
                    state.isLoading = false
                    return .none
                }
                
            case .fetchQuizStatusResponse(.failure(let error)):
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError, code == "GOAL-002" {
                    state.isExpired = true
                    state.isLoading = false
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "퀴즈 상태 조회 실패: \(error.localizedDescription)"
                print("[Home] Step2 실패: \(error)")
                return .none
                
            // Step 3-A 완료 (카테고리) → Step 4 시작
            case .fetchCategoryDocumentResponse(.success(let document)):
                state.categoryDocument = document
                print("[Home] Step3 완료 - CATEGORY documentId: \(document.documentId)")
                
                // Step 4: 퀴즈 조회
                return .run { send in
                    do {
                        let quizzes = try await apiClient.fetchUserQuizzes(
                            documentId: document.documentId,
                            documentType: .category
                        )
                        await send(.fetchQuizzesResponse(.success(quizzes)))
                    } catch {
                        await send(.fetchQuizzesResponse(.failure(error)))
                    }
                }
                
            case .fetchCategoryDocumentResponse(.failure(let error)):
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError {
                    if code == "GOAL-002" {
                        state.isExpired = true
                        state.isLoading = false
                        return .none
                    }
                    if code == "COMMON-005" {
                        // 오늘 문서가 아직 없음 — ContentSummaryFeature가 SSE로 생성
                        print("[Home] Step3 - 카테고리 문서 없음, SSE에서 생성 예정")
                        state.categoryDocument = nil
                        state.quizzes = []
                        state.isLoading = false
                        return .none
                    }
                }
                state.isLoading = false
                state.errorMessage = "카테고리 문서 조회 실패: \(error.localizedDescription)"
                print("[Home] Step3 실패 (CATEGORY): \(error)")
                return .none
                
            // Step 3-B 완료 (PDF) → Step 4 시작
            case .fetchPDFSummaryResponse(.success(let summary)):
                state.pdfSummary = summary
                print("[Home] Step3 완료 - PDF documentId: \(summary.documentId)")
                
                // Step 4: 퀴즈 조회
                return .run { send in
                    do {
                        let quizzes = try await apiClient.fetchUserQuizzes(
                            documentId: summary.documentId,
                            documentType: .document
                        )
                        await send(.fetchQuizzesResponse(.success(quizzes)))
                    } catch {
                        await send(.fetchQuizzesResponse(.failure(error)))
                    }
                }
                
            case .fetchPDFSummaryResponse(.failure(let error)):
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError, code == "GOAL-002" {
                    state.isExpired = true
                    state.isLoading = false
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "PDF 요약 조회 실패: \(error.localizedDescription)"
                print("[Home] Step3 실패 (PDF): \(error)")
                return .none
                
            // Step 4 완료
            case .fetchQuizzesResponse(.success(let quizzes)):
                state.quizzes = quizzes
                state.isLoading = false
                print("[Home] Step4 완료 - 퀴즈 \(quizzes.count)개, 플로우 종료")
                return .none

            case .fetchQuizzesResponse(.failure(let error)):
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError,
                   code == "GOAL-002" || code == "GOAL-003" {
                    state.isExpired = true
                    state.isLoading = false
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "퀴즈 조회 실패: \(error.localizedDescription)"
                print("[Home] Step4 실패: \(error)")
                return .none
                
            case .settingTapped:
                return .send(.delegate(.openMyPageRequested))

            case .toggleQuizStatus:
                state.isTodayQuizCompleted.toggle()
                return .none

            case .speechBubbleTapped:
                state.showCouponModal = true
                return .none

            case .dismissCouponModal:
                state.showCouponModal = false
                return .none

            case .couponUseTapped:
                guard state.availableQuizCount > 0 else { return .none }
                state.isTodayQuizCompleted = false
                state.isUsingCoupon = true
                state.showCouponModal = false
                state.quizzes = []
                state.isLoading = true
                return .run { send in
                    do {
                        let status = try await apiClient.fetchUserQuizStatus()
                        await send(.fetchQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.fetchQuizStatusResponse(.failure(error)))
                    }
                }

            case .adRewardEarned:
                return .run { send in
                    do {
                        try await apiClient.postAdReward()
                        await send(.postAdRewardResponse(.success(())))
                    } catch {
                        await send(.postAdRewardResponse(.failure(error)))
                    }
                }

            case .postAdRewardResponse(.success):
                return .run { send in
                    do {
                        let status = try await apiClient.fetchUserQuizStatus()
                        await send(.refreshQuizStatusResponse(.success(status)))
                    } catch {
                        await send(.refreshQuizStatusResponse(.failure(error)))
                    }
                }

            case .postAdRewardResponse(.failure(let error)):
                print("광고 보상 API 실패: \(error)")
                return .none

            case .refreshQuizStatusResponse(.success(let status)):
                state.quizStatus = status
                state.showCouponModal = true
                return .none

            case .refreshQuizStatusResponse(.failure(let error)):
                print("퀴즈 상태 새로고침 실패: \(error)")
                return .none

            case .expiredAlertDismissed:
                state.showExpiredAlert = false
                return .none

            case .expiredNewGoalTapped:
                state.showExpiredAlert = false
                return .send(.delegate(.startNewGoalTapped))

            case .expiredSelectExistingTapped:
                state.showExpiredAlert = false
                return .send(.delegate(.openMyPageRequested))

            case .characterEatTapped:
                if state.isExpired {
                    state.showExpiredAlert = true
                    return .none
                }

                // summaryData 생성 후 QuizFlow에 전달

                if state.isTodayQuizCompleted {
                    print("오늘 퀴즈를 이미 완료했습니다")
                    return .none
                }
                
                if let goal = state.currentGoal,
                   goal.type == "CATEGORY",
                   let categoryId = goal.category?.categoryId {
                    // SSE 스트리밍은 ContentSummaryFeature가 전담
                    let summaryData = ContentSummaryFeature.State(
                        documentId: 0,
                        summaryText: "",
                        hasSolvedToday: state.quizStatus?.hasSolvedToday ?? false,
                        isFirstTime: true,
                        documentType: .category,
                        quizzes: [],
                        categoryId: categoryId
                    )
                    return .send(.delegate(.startQuizFlow(
                        quizzes: [],
                        summaryData: summaryData,
                        isFirstTime: true
                    )))

                } else if let pdfSum = state.pdfSummary {
                    let summaryData = ContentSummaryFeature.State(
                        documentId: pdfSum.documentId,
                        summaryText: pdfSum.summary,
                        hasSolvedToday: pdfSum.hasSolvedToday,
                        isFirstTime: pdfSum.isFirstTime,
                        documentType: .document,
                        quizzes: state.quizzes
                    )
                    
                    return .send(.delegate(.startQuizFlow(
                        quizzes: state.quizzes,
                        summaryData: summaryData,
                        isFirstTime: pdfSum.isFirstTime
                    )))
                    
                } else {
                    print("요약 데이터가 아직 없습니다")
                    return .none
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                        store.send(.settingTapped)
                    }
                )
                
                Spacer()
                    .frame(height: (store.isTodayQuizCompleted || store.isExpired) ? 5 : 11)
                
                if store.isLoading {
                    
                    ZStack(alignment: .center) {
                        // Lottie 배경
                        LottieView(animation: .named("home_dummy"))
                            .playing(loopMode: .loop)
                            .frame(height: 548)
                            .offset(x: -10)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("퀴즈를 불러오는 중입니다...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray600)
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(height: 548)
                    .padding(.leading, 30)
                    .padding(.trailing, 3)
                } else {
                    CharacterImageView(
                        isTodayQuizCompleted: store.isTodayQuizCompleted,
                        isExpired: store.isExpired,
                        currentSnackImage: store.currentSnackImage,
                        onCharacterTapped: {
                            store.send(.characterEatTapped)
                        },
                        onSpeechBubbleTapped: {
                            store.send(.speechBubbleTapped)
                        }
                    )
                }
                                
                ScrollView {
                    VStack {
                        // TODO: 홈 콘텐츠
                    }
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .onAppear {
                store.send(.onAppear)
                RewardedAdManager.shared.loadAd()
            }
            // 쿠폰 모달
            .overlay {
                if store.showCouponModal {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { store.send(.dismissCouponModal) }

                    CouponModalView(
                        couponCount: store.availableQuizCount,
                        canIssueCoupon: store.canIssueCoupon,
                        onUse: { store.send(.couponUseTapped) },
                        onCharge: {
                            store.send(.dismissCouponModal)
                            RewardedAdManager.shared.showAd {
                                store.send(.adRewardEarned)
                            }
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.showCouponModal)
            // 만료 알럿
            .overlay {
                if store.showExpiredAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { store.send(.expiredAlertDismissed) }

                    ExpiredAlertView(
                        onNewGoal: { store.send(.expiredNewGoalTapped) },
                        onSelectExisting: { store.send(.expiredSelectExistingTapped) }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.showExpiredAlert)
        }
    }
}

// MARK: - Character Image View
struct CharacterImageView: View {
    let isTodayQuizCompleted: Bool
    let isExpired: Bool
    let currentSnackImage: String
    let onCharacterTapped: () -> Void
    let onSpeechBubbleTapped: () -> Void

    var body: some View {
        ZStack(alignment: .center) {
            // Lottie 배경 (항상 동일한 위치)
            LottieView(animation: .named((isTodayQuizCompleted || isExpired) ? "home_v2_dummy" : "home_dummy"))
                .playing(loopMode: .loop)
                .frame(height: 548)
                .offset(x: -10)

            // 오버레이 (만료/완료/미완료에 따라 다름)
            VStack(spacing: 16) {
                Spacer()

                if isExpired {
                    // 만료 시 - done 이미지
                    Image("done")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("학습 기간이\n만료되었어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                } else if isTodayQuizCompleted {
                    // 말풍선
                    SpeechBubbleView()
                        .onTapGesture { onSpeechBubbleTapped() }

                    // 완료 시 - done 이미지
                    Image("done")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("오늘의 지식을\n다 먹었어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                } else {
                    // 미완료 시 - 햄버거 + 텍스트
                    Image(currentSnackImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("오늘의 냠냠지식이\n도착했어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .offset(x: -12)
        }
        .frame(height: 548)
        .padding(.leading, 30)
        .padding(.trailing, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            // 만료 시에는 항상 터치 가능, 완료 시에만 막음
            if !isTodayQuizCompleted || isExpired {
                onCharacterTapped()
            }
        }
    }
}

struct HomeNavigationBar: View {
    let fireCount: Int
    let stampCount: Int
    let onSettingTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 로고
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 22)
                

            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("fire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(fireCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("stamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(stampCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // 설정 버튼
            Button(action: onSettingTapped) {
                Image("setting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

// MARK: - Speech Bubble
struct SpeechBubbleView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // 말풍선 꼬리 - 오른쪽 상단, 위를 향함
            TriangleUp()
                .fill(Color.white)
                .frame(width: 14, height: 8)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: -2)
                .padding(.trailing, 16)

            Text("음냐냐.. 퀴즈 더 풀고싶다~ click!")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                )
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct TriangleUp: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Expired Alert View
struct ExpiredAlertView: View {
    let onNewGoal: () -> Void
    let onSelectExisting: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("풀고 있는 틈틈잇이 없어요")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Text("먹을 간식이 없어요!\n새로운 지식을 먹여줄래요?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                Button(action: onNewGoal) {
                    Text("새로운 틈틈잇 시작하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue500.opacity(0.12))
                        .cornerRadius(12)
                }

                Button(action: onSelectExisting) {
                    Text("진행중인 틈틈잇 선택하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue500)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 32)
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }
}

enum SocialLoginType: String, Equatable {
    case apple = "Apple"
    case kakao = "Kakao"
    
    var icon: String {
        switch self {
        case .apple:
            return "apple.logo"
        case .kakao:
            return "message.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .apple:
            return .black
        case .kakao:
            return .yellow
        }
    }
    
    // API 응답 매핑용 initializer
    init?(from apiString: String) {
        switch apiString.uppercased() {
        case "APPLE":
            self = .apple
        case "KAKAO":
            self = .kakao
        default:
            return nil
        }
    }
}
