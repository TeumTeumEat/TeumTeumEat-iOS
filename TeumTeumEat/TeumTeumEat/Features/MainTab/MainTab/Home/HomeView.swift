//
//  HomeView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture
import Lottie
import CoreNetwork
import OnboardingFeature

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    var body: some View {
        VStack(spacing: 0) {
            HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                        store.send(.settingTapped)
                    }
                )
                
                Spacer()
                    .frame(height: topSpacing)
                
                characterSection
                                
                ScrollView {
                    VStack {
                        // TODO: 홈 콘텐츠
                    }
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .trackScreen(.home)
            .onAppear {
                store.send(.onAppear)
                RewardedAdManager.shared.loadAd()
                RewardedAdManager.shared.onAdInterrupted = {
                    store.send(.adInterrupted)
                }
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
                            store.send(.couponChargeTapped)
                            RewardedAdManager.shared.showAd {
                                store.send(.adRewardEarned)
                            }
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.showCouponModal)
            // 주제 완료 알럿 (강제 - 배경 탭으로 닫기 불가)
            .overlay {
                if store.showGoalCompletedAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    GoalCompletedAlertView(
                        hasActiveSubjects: store.hasActiveSubjects,
                        onNewGoal: { store.send(.goalCompletedNewGoalTapped) },
                        onSelectExisting: { store.send(.goalCompletedSelectExistingTapped) }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.showGoalCompletedAlert)
            // 에러 오버레이
            .overlay {
                if store.showErrorOverlay {
                    ErrorOverlayView(
                        message: store.errorOverlayMessage,
                        isRetrying: store.isRetryingError,
                        onRetry: { store.send(.retryFromErrorOverlay) },
                        onBack: nil
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: store.showErrorOverlay)
            // 재시도 토스트
            .tteToast(
                isPresented: Binding(
                    get: { store.showRetryToast },
                    set: { if !$0 { store.send(.retryToastDismissed) } }
                ),
                message: "잠시 후 다시 시도해 주세요."
            )
            // 광고 중단 토스트
            .tteToast(
                isPresented: Binding(
                    get: { store.showAdInterruptedToast },
                    set: { if !$0 { store.send(.adInterruptedToastDismissed) } }
                ),
                message: "광고를 끝까지 시청해야 쿠폰이 지급돼요."
            )
    }

    private var topSpacing: CGFloat {
        (store.isTodayQuizCompleted || store.isGoalCompleted) ? 5 : 11
    }

    @ViewBuilder
    private var characterSection: some View {
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
                    
                    Text(store.isPreparingSnack ? "간식을 준비 중이에요..." : "퀴즈를 불러오는 중입니다...")
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
                isGoalCompleted: store.isGoalCompleted,
                currentSnackImage: store.currentSnackImage,
                onCharacterTapped: {
                    store.send(.characterEatTapped)
                },
                onSpeechBubbleTapped: {
                    store.send(.speechBubbleTapped)
                }
            )
        }
    }
}

// MARK: - Character Image View
struct CharacterImageView: View {
    let isTodayQuizCompleted: Bool
    let isGoalCompleted: Bool
    let currentSnackImage: String
    let onCharacterTapped: () -> Void
    let onSpeechBubbleTapped: () -> Void

    var body: some View {
        ZStack(alignment: .center) {
            // Lottie 배경
            LottieView(animation: .named((isTodayQuizCompleted || isGoalCompleted) ? "home_v2_dummy" : "home_dummy"))
                .playing(loopMode: .loop)
                .frame(height: 548)
                .offset(x: -10)

            VStack(spacing: 16) {
                Spacer()

                if isGoalCompleted {
                    // 주제 전체 완료
                    Image("done")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("이 주제의 모든 지식을\n다 먹었어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                } else if isTodayQuizCompleted {
                    // 오늘 완료
                    SpeechBubbleView()
                        .onTapGesture { onSpeechBubbleTapped() }

                    Image("done")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)

                    Text("오늘의 지식을\n다 먹었어요!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                } else {
                    // 미완료 - 퀴즈 대기 중
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


// MARK: - Goal Completed Alert View
struct GoalCompletedAlertView: View {
    let hasActiveSubjects: Bool
    let onNewGoal: () -> Void
    let onSelectExisting: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("이 주제를 모두 완료했어요!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Text("새로운 지식을 먹으러 가볼까요?")
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
                        .foregroundColor(hasActiveSubjects ? .white : .gray400)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(hasActiveSubjects ? Color.blue500 : Color.gray200)
                        .cornerRadius(12)
                }
                .disabled(!hasActiveSubjects)
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
