//
//  QuizFinishedFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 3/14/26.
//

import SwiftUI
import ComposableArchitecture
import Lottie

@Reducer
struct QuizFinishedFeature {
    @ObservableState
    struct State: Equatable {
        var showFlowSelectionAlert: Bool = false
    }

    enum Action {
        case newStartTapped
        case alertCategorySelected
        case alertDocumentSelected
        case alertDismissed
        case delegate(Delegate)
    }

    enum Delegate {
        case startCategoryFlow
        case startDocumentFlow
        case dismissed
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .newStartTapped:
                state.showFlowSelectionAlert = true
                return .none

            case .alertCategorySelected:
                state.showFlowSelectionAlert = false
                return .send(.delegate(.startCategoryFlow))

            case .alertDocumentSelected:
                state.showFlowSelectionAlert = false
                return .send(.delegate(.startDocumentFlow))

            case .alertDismissed:
                state.showFlowSelectionAlert = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

struct QuizFinishedView: View {
    let store: StoreOf<QuizFinishedFeature>

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Spacer()
                }
                .frame(height: 48)
                .padding(.horizontal, 20)
                .background(Color.white)

                Divider()

                // Lottie + 텍스트 오버레이
                ZStack(alignment: .top) {
                    LottieView(animation: .named("home_v2_dummy"))
                        .playing(loopMode: .loop)
                        .frame(height: 537)

                    VStack(spacing: 24) {
                        Image("done")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)

                        Text("학습 기간이\n만료되었어요!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        Text("새로운 목표를 설정하고\n계속 공부해봐요!")
                            .font(.system(size: 16))
                            .foregroundColor(.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                }
                .padding(.horizontal, 15)

                Spacer()

                // 새로운 틈틈잇 시작하기 버튼
                Button(action: {
                    store.send(.newStartTapped)
                }) {
                    Text("새로운 틈틈잇 시작하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.blue500)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationBarHidden(true)

            // Dim overlay + Custom Alert
            if store.showFlowSelectionAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.alertDismissed)
                    }

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("학습 기간 만료")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        Text("학습 기간이 만료되었어요.\n새로운 목표를 설정하고\n계속 공부해봐요!")
                            .font(.system(size: 14))
                            .foregroundColor(.gray600)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    Divider()

                    VStack(spacing: 0) {
                        Button(action: {
                            store.send(.alertCategorySelected)
                        }) {
                            Text("카테고리로 시작")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue500)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }

                        Divider()

                        Button(action: {
                            store.send(.alertDocumentSelected)
                        }) {
                            Text("PDF로 시작")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue500)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }

                        Divider()

                        Button(action: {
                            store.send(.alertDismissed)
                        }) {
                            Text("취소")
                                .font(.system(size: 16))
                                .foregroundColor(.gray600)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 40)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            }
        }
    }
}
