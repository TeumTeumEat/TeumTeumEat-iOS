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

        var availableQuizCount: Int {
            quizStatus?.availableQuizCount ?? 0
        }
        
        var currentSnackImage: String {
            print("currentSnackImage 호출")
            print("- isTodayQuizCompleted: \(isTodayQuizCompleted)")
            print("- isExpired: \(isExpired)")
            print("- currentGoal.type: \(currentGoal?.type ?? "nil")")
            print("- categoryDocument: \(categoryDocument != nil)")
            print("- pdfSummary: \(pdfSummary != nil)")

            guard !isExpired else {
                print("만료 상태 - done 반환")
                return "done"
            }

            guard !isTodayQuizCompleted else {
                print("완료 상태 - done 반환")
                return "done"
            }
            
            // currentGoal의 type과 일치하는 문서만 사용
            guard let goal = currentGoal else {
                print("currentGoal 없음 - burger 반환")
                return "burger"
            }
            
            // Goal Type에 따라 올바른 문서만 체크
            if goal.type == "CATEGORY", let categoryDoc = categoryDocument {
                print("CATEGORY - categoryDocument 사용")
                print("- documentId: \(categoryDoc.documentId)")
                print("- createdAt: \(categoryDoc.createdAt)")
                
                let image = SnackImageMapper.snackImage(
                    for: categoryDoc.documentId,
                    createdAt: categoryDoc.createdAt
                )
                print("- 결과 이미지: \(image)")
                return image
            }
            
            if goal.type == "DOCUMENT", let pdfSum = pdfSummary {
                print("DOCUMENT - pdfSummary 사용")
                print("- documentId: \(pdfSum.documentId)")
                print("- createdAt: \(pdfSum.createdAt)")
                
                let image = SnackImageMapper.snackImage(
                    for: pdfSum.documentId,
                    createdAt: pdfSum.createdAt
                )
                print("- 결과 이미지: \(image)")
                return image
            }
            
            print("문서 로딩 중 - burger 반환")
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
                print("캘린더 조회 완료 - Fire: \(calendarData.currentStreak), Stamp: \(calendarData.totalStamps)")
                return .none
                
            case .fetchCalendarHistoryResponse(.failure(let error)):
                print("캘린더 조회 실패: \(error)")
                // 실패해도 다른 API에 영향 없음
                return .none
                
            // Step 1 완료 → Step 2 시작
            case .fetchCurrentGoalResponse(.success(let goal)):
                state.isExpired = goal.isExpired
                if goal.isExpired {
                    state.currentGoal = goal
                    state.isLoading = false
                    print("Step 1 완료 - Goal 만료됨, 조기 종료")
                    return .none
                }

                let previousGoal = state.currentGoal
                state.currentGoal = goal

                //  Goal이 실제로 바뀌었는지 확인
                let isNewGoal: Bool = {
                    guard let prev = previousGoal else { return true }
                    
                    if prev.type != goal.type { return true }
                    
                    if goal.type == "CATEGORY" {
                        return prev.category?.categoryId != goal.category?.categoryId
                    }
                    
                    if goal.type == "DOCUMENT" {
                        return prev.documentId != goal.documentId
                    }
                    
                    return false
                }()
                
                if isNewGoal {
                    print("새로운 Goal - 이전 데이터 초기화")
                    state.categoryDocument = nil
                    state.pdfSummary = nil
                    state.quizzes = []
                } else {
                    print("동일한 Goal - 데이터 유지")
                }
                
                print("Step 1 완료 - Goal Type: \(goal.type)")
                
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
                print("Step 1 실패: \(error)")
                return .none
                
            // Step 2 완료 → Step 3 시작
            case .fetchQuizStatusResponse(.success(let status)):
                let wasCompletedYesterday = state.isTodayQuizCompleted
                state.quizStatus = status
                state.isTodayQuizCompleted = status.hasSolvedToday
                
                print("Step 2 완료 - hasSolvedToday: \(status.hasSolvedToday)")
                
                //날짜 변경 감지: 어제는 완료였는데 오늘은 미완료
                if wasCompletedYesterday && !status.hasSolvedToday {
                    print("날짜 변경 감지 - 새로운 문서 필요")
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
                    // 문서가 이미 있으면 퀴즈만 조회
                    if let categoryDoc = state.categoryDocument {
                        print("categoryDocument 존재 - 퀴즈만 조회")
                        return .run { [docId = categoryDoc.documentId] send in
                            do {
                                let quizzes = try await apiClient.fetchUserQuizzes(
                                    documentId: docId,
                                    documentType: .category
                                )
                                await send(.fetchQuizzesResponse(.success(quizzes)))
                            } catch {
                                await send(.fetchQuizzesResponse(.failure(error)))
                            }
                        }
                    }
                    
                    // 카테고리 문서 조회
                    guard let categoryId = goal.category?.categoryId else {
                        state.errorMessage = "카테고리 ID가 없습니다"
                        state.isLoading = false
                        return .none
                    }
                    
                    return .run { send in
                        do {
                            let document = try await apiClient.fetchDailyCategoryDocument(categoryId: categoryId)
                            await send(.fetchCategoryDocumentResponse(.success(document)))
                        } catch {
                            await send(.fetchCategoryDocumentResponse(.failure(error)))
                        }
                    }
                    
                } else if goal.type == "DOCUMENT" {
                    // PDF 문서가 이미 있으면 퀴즈만 조회
                    if let pdfSum = state.pdfSummary {
                        print("pdfSummary 존재 - 퀴즈만 조회")
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
                    print("Step 2 실패 - GOAL-002: 학습 기간 만료")
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "퀴즈 상태 조회 실패: \(error.localizedDescription)"
                print("Step 2 실패: \(error)")
                return .none
                
            // Step 3-A 완료 (카테고리) → Step 4 시작
            case .fetchCategoryDocumentResponse(.success(let document)):
                state.categoryDocument = document
                print("Step 3 완료 (카테고리) - documentId: \(document.documentId)")
                
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
                   case .serverError(let code, _, _) = apiError, code == "GOAL-002" {
                    state.isExpired = true
                    state.isLoading = false
                    print("Step 3 실패 (카테고리) - GOAL-002: 학습 기간 만료")
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "카테고리 문서 조회 실패: \(error.localizedDescription)"
                print("Step 3 실패 (카테고리): \(error)")
                return .none
                
            // Step 3-B 완료 (PDF) → Step 4 시작
            case .fetchPDFSummaryResponse(.success(let summary)):
                state.pdfSummary = summary
                print("Step 3 완료 (PDF) - documentId: \(summary.documentId)")
                
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
                    print("Step 3 실패 (PDF) - GOAL-002: 학습 기간 만료")
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "PDF 요약 조회 실패: \(error.localizedDescription)"
                print("Step 3 실패 (PDF): \(error)")
                return .none
                
            // Step 4 완료
            case .fetchQuizzesResponse(.success(let quizzes)):
                state.quizzes = quizzes
                state.isLoading = false
                print("Step 4 완료 - 퀴즈 개수: \(quizzes.count)")
                print("전체 플로우 완료!")
                return .none
                
            case .fetchQuizzesResponse(.failure(let error)):
                if let apiError = error as? APIError,
                   case .serverError(let code, _, _) = apiError, code == "GOAL-002" {
                    state.isExpired = true
                    state.isLoading = false
                    print("Step 4 실패 - GOAL-002: 학습 기간 만료")
                    return .none
                }
                state.isLoading = false
                state.errorMessage = "퀴즈 조회 실패: \(error.localizedDescription)"
                print("Step 4 실패: \(error)")
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
                state.showCouponModal = false
                state.categoryDocument = nil
                state.pdfSummary = nil
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
                
                if let categoryDoc = state.categoryDocument {
                    let summaryData = ContentSummaryFeature.State(
                        documentId: categoryDoc.documentId,
                        summaryText: categoryDoc.content,
                        hasSolvedToday: categoryDoc.hasSolvedToday,
                        isFirstTime: categoryDoc.isFirstTime,
                        documentType: .category,
                        quizzes: state.quizzes
                    )
                    
                    return .send(.delegate(.startQuizFlow(
                        quizzes: state.quizzes,
                        summaryData: summaryData,
                        isFirstTime: categoryDoc.isFirstTime
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
    @State private var showAdTest = false

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
            // TODO: 광고 테스트 확인 후 삭제
            .overlay(alignment: .bottomTrailing) {
                Button("AD\n테스트") {
                    showAdTest = true
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.red)
                .clipShape(Circle())
                .padding(.bottom, 100)
                .padding(.trailing, 16)
            }
            .sheet(isPresented: $showAdTest) {
                AdTestView()
            }
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
        VStack(spacing: 0) {
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

            // 말풍선 꼬리
            Triangle()
                .fill(Color.white)
                .frame(width: 14, height: 8)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
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
