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
    }
    
    enum Action {
        case onAppear
        case fetchCurrentGoalResponse(Result<GoalResponse, Error>) 
        case settingTapped
        case toggleQuizStatus
        case characterEatTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case startQuizFlow
        case openMyPageRequested
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        let goal = try await apiClient.fetchCurrentGoal()
                        await send(.fetchCurrentGoalResponse(.success(goal)))
                    } catch {
                        await send(.fetchCurrentGoalResponse(.failure(error)))
                    }
                }
                
            case .fetchCurrentGoalResponse(.success(let goal)):
                print("현재 목표 조회 성공")
                print("Goal ID: \(goal.goalId)")
                print("Type: \(goal.type)")
                print("StudyPeriod: \(goal.studyPeriod)")
                print("Difficulty: \(goal.difficulty)")
                return .none
                
            case .fetchCurrentGoalResponse(.failure(let error)):
                print("현재 목표 조회 실패: \(error)")
                return .none
                
            case .settingTapped:
                return .send(.delegate(.openMyPageRequested))
                
            case .toggleQuizStatus:
                state.isTodayQuizCompleted.toggle()
                return .none
                
            case .characterEatTapped:
                return .send(.delegate(.startQuizFlow))
                
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
                
                CharacterImageView(
                    isTodayQuizCompleted: store.isTodayQuizCompleted,
                    onCharacterTapped: {
                        print("HomeView: 캐릭터 탭!")
                        store.send(.characterEatTapped)
                    }
                )
                                
                ScrollView {
                    VStack {
                        // TODO: 홈 콘텐츠
                    }
                }
            }
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
        if isTodayQuizCompleted {
            Image("character_eat")
                .resizable()
                .scaledToFit()
                .frame(height: 554)
                .padding(.leading, 30)
                .padding(.trailing, 8.47)
        } else {
            // 퀴즈 미완료 시 - Lottie + 오버레이
            ZStack(alignment: .center) {
                // Lottie 배경
                LottieView(animation: .named("home_dummy"))
                    .playing(loopMode: .loop)
                    .frame(height: 548)
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    // 햄버거 이미지
                    Image("hamburger")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    
                    // 안내 텍스트
                    Text("오늘의 냠냠지식이\n도착했어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            }
            .frame(height: 548)
            .padding(.leading, 30)
            .padding(.trailing, 3)
            .contentShape(Rectangle())
            .onTapGesture {
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
                    .foregroundColor(.primary)
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
                    .foregroundColor(.primary)
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
