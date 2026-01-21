//
//  QuizGuideView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/2/26.
//

import SwiftUI
import ComposableArchitecture
import Lottie

struct QuizGuideView: View {
    let store: StoreOf<QuizGuideFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            VStack(spacing: 0) {
                HStack {
                    Button {
                        // 뒤로가기 필요하면 추가
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .opacity(0)  // 숨김 (균형용)
                    
                    Spacer()
                    
                    Text("퀴즈 안내")
                        .titleSemibold20()
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
            }
            .background(Color.white)
            
            // Lottie + 텍스트 오버레이
            ZStack(alignment: .top) {
                // Lottie 배경
                LottieView(animation: .named("home_dummy"))
                    .playing(loopMode: .loop)
                    .frame(height: 537)
                
                VStack(spacing: 16) {
                    // O/X 퀴즈 텍스트
                    Text("O/X 퀴즈")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue500)
                        )
                        .padding(.horizontal, 86.5)
                        .padding(.top, 4)
                    
                    // 오늘의 지식 텍스트
                    Text("오늘의 지식과 관련한\n퀴즈 맞춰봐요")
                        .font(.system(size: 24,weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
//                        .lineSpacing(4)
                    
                    // 안내 카드
                    VStack(spacing: 16) {
                        // 안내 리스트
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 10) {
                                Image("number1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("총 3문제가 등장해요")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image("number2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("문제가 끝나면 정답 확인이 가능해요")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                            }
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image("number3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("지난 문제는 히스토리에서 확인해봐요")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        // 체크박스
                        HStack(spacing: 8) {
                            Button(action: {
                                store.send(.checkboxToggled)
                            }) {
                                Image(systemName: store.isCheckboxSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(store.isCheckboxSelected ? .blue : .gray300)
                            }
                            
                            Text("안내 다시 보지 않기")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        
                        // 퀴즈 시작 버튼
                        Button(action: {
                            store.send(.startQuizButtonTapped)
                        }) {
                            HStack {
                                if store.isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(store.isSubmitting ? "저장 중..." : "퀴즈 풀러가기")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(.blue500)
                            .cornerRadius(12)
                        }
                        .disabled(store.isSubmitting)  // API 호출 중에는 비활성화
                        .padding(.horizontal, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    )
                    .padding(.horizontal, 36)
                }
                .padding(.top, 112)
            }
            .padding(.top, 2)
            .padding(.leading, 15)
            .padding(.trailing, 15)
            
            Spacer()
        }
        .background(.white)
        .navigationBarHidden(true)
    }
}
