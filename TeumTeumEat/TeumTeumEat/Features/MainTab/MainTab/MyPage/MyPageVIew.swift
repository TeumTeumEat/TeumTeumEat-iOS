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
    @Environment(\.scenePhase) private var scenePhase
    
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
                        
                        if store.isLoadingNotificationSetting {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: { store.isNotificationEnabled },
                                set: { store.send(.notificationToggled($0)) }
                            ))
                            .labelsHidden()
                        }
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
                                 store.send(.logoutButtonTapped)
                                } label: {
                                    Text("로그아웃")
                                        .bodyRegular14()
                                        .foregroundColor(.gray)
                                }
                                
                                Button {
                                    store.send(.withdrawalButtonTapped)
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
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .alert("알림 권한 필요", isPresented: Binding(
            get: { store.showNotificationSettingsAlert },
            set: { if !$0 { store.send(.dismissNotificationAlert) } }
        )) {
            Button("취소", role: .cancel) {
                store.send(.dismissNotificationAlert)
            }
            Button("설정으로 이동") {
                store.send(.dismissNotificationAlert)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("알림을 받으려면 설정에서 알림 권한을 허용해주세요.")
        }
        .alert("로그아웃", isPresented: Binding(
            get: { store.showLogoutAlert },
            set: { if !$0 { store.send(.cancelLogout) } }
        )) {
            Button("취소", role: .cancel) {
                store.send(.cancelLogout)
            }
            Button("로그아웃", role: .destructive) {
                store.send(.confirmLogout)
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("회원탈퇴", isPresented: Binding(
            get: { store.showWithdrawalAlert },
            set: { if !$0 { store.send(.cancelWithdrawal) } }
        )) {
            Button("취소", role: .cancel) {
                store.send(.cancelWithdrawal)
            }
            Button("탈퇴", role: .destructive) {
                store.send(.confirmWithdrawal)
            }
        } message: {
            Text("탈퇴 시 모든 학습 데이터가 삭제되며 복구할 수 없습니다. 정말 탈퇴하시겠습니까?")
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
