//
//  MyPageView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
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
                    VStack(alignment: .leading, spacing: 0) {
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
                        if let selectedSubject = store.selectedSubject {
                            SelectedSubjectCard(subject: selectedSubject)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 20)
                        }
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
                        
                        AccountInfoCard(
                            socialLoginType: store.socialLoginType,
                            email: store.email
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
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



@Reducer
struct SubjectListFeature {
    @ObservableState
    struct State: Equatable {
        var subjects: [Subject] = [
            Subject(
                id: "1",
                name: "Swift 기초",
                duration: "4주",
                difficulty: "하",
                category: ["IT", "프로그래밍", "Swift"],
                description: "Swift 언어의 기본 문법부터 고급 기능까지 배워보세요."
            ),
            Subject(
                id: "2",
                name: "SwiftUI",
                duration: "6주",
                difficulty: "중",
                category: ["IT", "앱 개발자", "SwiftUI"],
                description: "SwiftUI를 사용하여 iOS 앱의 UI를 선언적으로 구성하는 방법을 배웁니다."
            ),
            Subject(
                id: "3",
                name: "Combine",
                duration: "8주",
                difficulty: "상",
                category: ["IT", "앱 개발자", "Reactive Programming"],
                description: "Combine 프레임워크를 활용한 반응형 프로그래밍 패턴을 학습합니다."
            ),
            Subject(
                id: "4",
                name: "TCA",
                duration: "10주",
                difficulty: "상",
                category: ["IT", "앱 개발자", "Architecture"],
                description: "The Composable Architecture를 사용하여 확장 가능하고 테스트 가능한 앱을 만드는 방법을 배웁니다."
            ),
            Subject(
                id: "5",
                name: "iOS 면접 준비",
                duration: "4주",
                difficulty: "중",
                category: ["IT", "취업 준비", "면접"],
                description: "iOS 개발자 면접에서 자주 나오는 질문들과 답변 방법을 준비합니다."
            )
        ]
    }
    
    enum Action {
        case backTapped
        case subjectTapped(Subject)
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
            case subjectSelected(Subject)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .subjectTapped(let subject):
                return .send(.delegate(.subjectSelected(subject)))
                
            case .backTapped:
                return .send(.delegate(.dismissed))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct Subject: Equatable, Identifiable {
    let id: String
    let name: String
    let duration: String // "4주"
    let difficulty: String // "상"
    let category: [String] // ["IT", "앱 개발자", "SwiftUI"]
    let description: String
}

struct SubjectListView: View {
    let store: StoreOf<SubjectListFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("학습주제")
                    .titleSemibold20()
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
            }
            .background(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.subjects) { subject in
                        Button {
                            store.send(.subjectTapped(subject))
                        } label: {
                            HStack {
                                Text(subject.name)
                                    .bodyRegular14()
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

@Reducer
struct AppSettingsFeature {
    @ObservableState
    struct State: Equatable {
        
    }
    
    enum Action {
        case backTapped
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.dismissed))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct AppSettingsView: View {
    let store: StoreOf<AppSettingsFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("틈틈잇 사용 설정")
                    .titleSemibold20()
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            ScrollView {
                VStack {
                    Text("틈틈잇 사용 설정 내용")
                        .font(.title)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}
