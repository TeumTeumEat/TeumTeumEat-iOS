//
//  MyPageVIew.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

struct MyPageView: View {
    let store: StoreOf<MyPageFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            VStack(spacing: 0) {
                HStack {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("내 정보")
                        .titleSemibold20()
                    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 학습주제 섹션
                    HStack {
                        Text("학습주제")
                            .titleSemibold16()
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button {
                            store.send(.viewAllSubjectsTapped)
                        } label: {
                            HStack(spacing: 4) {
                                Text("전체보기")
                                    .bodyRegular14()
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 선택된 주제 카드
                    if store.isLoadingSubject {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let selectedSubject = store.selectedSubject {
                        SelectedSubjectCard(subject: selectedSubject)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                    } else {
                        Text("등록된 학습주제가 없습니다")
                            .bodyRegular14()
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                    
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    // 알림설정
                    HStack {
                        Text("알림설정")
                            .bodyRegular16()
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { store.isNotificationEnabled },
                            set: { store.send(.notificationToggled($0)) }
                        ))
                        .labelsHidden()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    // 틈틈잇 사용 설정
                    HStack {
                        Text("틈틈잇 사용 설정")
                            .bodyRegular16()
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button {
                            store.send(.viewAppSettingsTapped)
                        } label: {
                            HStack(spacing: 4) {
                                Text("전체보기")
                                    .bodyRegular14()
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    // 계정정보
                    VStack(alignment: .leading, spacing: 0) {
                        Text("계정정보")
                            .bodyRegular16()
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if store.isLoadingAccountInfo {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            AccountInfoCard(
                                socialLoginType: store.socialLoginType,
                                email: store.email
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    // 기타
                    VStack(alignment: .leading, spacing: 0) {
                        Text("기타")
                            .bodyRegular16()
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // 이용약관
                            Button {
                                print("이용약관 탭")
                            } label: {
                                HStack {
                                    Text("이용약관")
                                        .bodyRegular16()
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // 고객센터
                            Button {
                                print("고객센터 탭")
                            } label: {
                                HStack {
                                    Text("고객센터")
                                        .bodyRegular16()
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // 버전정보
                            Button {
                                print("버전정보 탭")
                            } label: {
                                HStack {
                                    Text("버전정보")
                                        .bodyRegular16()
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // 하단 구분선 + 로그아웃/탈퇴하기 영역
                    Color.gray.opacity(0.2)
                        .overlay(
                            // 로그아웃 / 탈퇴하기
                            HStack(spacing: 40) {
                                Spacer()
                                
                                Button {
                                    print("로그아웃 탭")
                                } label: {
                                    Text("로그아웃")
                                        .bodyRegular14()
                                        .foregroundColor(.gray)
                                }
                                
                                Button {
                                    print("탈퇴하기 탭")
                                } label: {
                                    Text("탈퇴하기")
                                        .bodyRegular14()
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 150)
                            .padding(.bottom, 20)
                            , alignment: .top
                        )
                        .frame(minHeight: 250)
                }
            }
            .background(Color.white)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
             store.send(.onAppear)
         }
        .navigationDestination(
            isPresented: Binding(
                get: { store.subjectList != nil },
                set: { if !$0 { store.send(.subjectList(.delegate(.dismissed))) } }
            )
        ) {
            if let subjectListStore = store.scope(state: \.subjectList, action: \.subjectList) {
                SubjectListView(store: subjectListStore)
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { store.appSettings != nil },
                set: { if !$0 { store.send(.appSettings(.delegate(.dismissed))) } }
            )
        ) {
            if let appSettingsStore = store.scope(state: \.appSettings, action: \.appSettings) {
                AppSettingsView(store: appSettingsStore)
            }
        }
    }
}
