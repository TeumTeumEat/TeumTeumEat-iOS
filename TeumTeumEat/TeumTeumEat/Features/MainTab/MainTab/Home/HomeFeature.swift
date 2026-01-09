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
        
        // API 관련 상태
        var currentGoal: GoalResponse?
        var quizStatus: UserQuizStatusData?
        var categoryDocument: CategoryDocumentData?
        var pdfSummary: PDFSummaryData?
        var quizzes: [UserQuiz] = []
        var calendarData: CalendarHistoryData?
        
        var isLoading: Bool = false
        var errorMessage: String?
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
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuizFlow(
            quizzes: [UserQuiz],
            summaryData: ContentSummaryFeature.State,
            isFirstTime: Bool
        )
        case openMyPageRequested
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
                
            // ✅ 캘린더 조회 완료 (독립적 처리)
            case .fetchCalendarHistoryResponse(.success(let calendarData)):
                state.calendarData = calendarData
                state.fireCount = calendarData.currentStreak
                state.stampCount = calendarData.totalStamps
                print("캘린더 조회 완료 - Fire: \(calendarData.currentStreak), Stamp: \(calendarData.totalStamps)")
                return .none
                
            case .fetchCalendarHistoryResponse(.failure(let error)):
                print("❌ 캘린더 조회 실패: \(error)")
                // 실패해도 다른 API에 영향 없음
                return .none
                
                
            // Step 1 완료 → Step 2 시작
            case .fetchCurrentGoalResponse(.success(let goal)):
                state.currentGoal = goal
                print("Step 1 완료 - Goal Type: \(goal.type)")
                
                // Step 2: 퀴즈 상태 확인
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
                state.quizStatus = status
                state.isTodayQuizCompleted = status.hasSolvedToday
                print("Step 2 완료 - hasSolvedToday: \(status.hasSolvedToday)")
                
                // Step 3: Goal Type에 따라 요약글 조회
                guard let goal = state.currentGoal else {
                    state.errorMessage = "목표 정보가 없습니다"
                    state.isLoading = false
                    return .none
                }
                
                if goal.type == "CATEGORY" {
                    // 카테고리 타입
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
                    // PDF 타입
                    guard let documentId = goal.documentId else {
                        state.errorMessage = "문서 ID가 없습니다"
                        state.isLoading = false
                        return .none
                    }
                    
                    return .run { send in
                        do {
                            let summary = try await apiClient.fetchDailyPDFSummary(
                                goalId: goal.goalId,
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
                state.isLoading = false
                state.errorMessage = "퀴즈 조회 실패: \(error.localizedDescription)"
                print("Step 4 실패: \(error)")
                return .none
                
            case .settingTapped:
                return .send(.delegate(.openMyPageRequested))
                
            case .toggleQuizStatus:
                state.isTodayQuizCompleted.toggle()
                return .none
                
            case .characterEatTapped:
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
                    print("⚠️ 요약 데이터가 아직 없습니다")
                    return .none
                }
                
            // ContentSummary Delegate 처리
            
                
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
                    .frame(height: store.isTodayQuizCompleted ? 5 : 11)
                
                if store.isLoading {
                    ProgressView()
                        .frame(height: 548)
                } else {
                    CharacterImageView(
                        isTodayQuizCompleted: store.isTodayQuizCompleted,
                        onCharacterTapped: {
                            store.send(.characterEatTapped)
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
            }

        }
    }
}

// MARK: - Character Image View
struct CharacterImageView: View {
    let isTodayQuizCompleted: Bool
    let onCharacterTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .center) {
            // Lottie 배경 (항상 동일한 위치)
            LottieView(animation: .named(isTodayQuizCompleted ? "home_v2_dummy" : "home_dummy"))
                .playing(loopMode: .loop)
                .frame(height: 548)
            
            // 오버레이 (완료/미완료에 따라 다름)
            VStack(spacing: 16) {
                Spacer()
                
                if isTodayQuizCompleted {
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
                    Image("hamburger")
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
        }
        .frame(height: 548)
        .padding(.leading, 30)
        .padding(.trailing, 3)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isTodayQuizCompleted {
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
