//
//  MyPageFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MyPageFeature {
    @ObservableState
    struct State: Equatable {
        var selectedSubject: Subject? = Subject(
            id: "1",
            name: "Swift 기초",
            duration: "4주",
            difficulty: "하",
            category: ["IT", "프로그래밍", "Swift"],
            description: "Swift 언어의 기본 문법부터 고급 기능까지 배워보세요."
        )
        var subjectList: SubjectListFeature.State?
        var isNotificationEnabled: Bool = false
        var appSettings: AppSettingsFeature.State?
        
        var socialLoginType: SocialLoginType = .apple
        var email: String = "user@example.com"
    }
    
    enum Action {
        case closeTapped
        case viewAllSubjectsTapped
        case viewAppSettingsTapped
        case notificationToggled(Bool)
        case subjectList(SubjectListFeature.Action)
        case appSettings(AppSettingsFeature.Action)
        case delegate(Delegate)
        
        enum Delegate {
            case dismissed
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewAllSubjectsTapped:
                state.subjectList = SubjectListFeature.State()
                return .none
                
            case .viewAppSettingsTapped:
                state.appSettings = AppSettingsFeature.State()
                return .none
                
            case .notificationToggled(let isEnabled):
                state.isNotificationEnabled = isEnabled
                print("알림 설정: \(isEnabled)")
                return .none
                
            case .subjectList(.delegate(.subjectSelected(let subject))):
                state.selectedSubject = subject
                state.subjectList = nil
                return .none
                
            case .subjectList(.delegate(.dismissed)):
                state.subjectList = nil
                return .none
                
            case .appSettings(.delegate(.dismissed)):
                state.appSettings = nil
                return .none
                
            case .closeTapped:
                return .send(.delegate(.dismissed))
                
            case .subjectList:
                return .none
                
            case .appSettings:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.subjectList, action: \.subjectList) {
            SubjectListFeature()
        }
        .ifLet(\.appSettings, action: \.appSettings) {
            AppSettingsFeature()
        }
    }
}
struct SelectedSubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 제목, 기간, 난이도
            HStack(alignment: .top, spacing: 8) {
                Text(subject.name)
                    .titleSemibold16()
                    .foregroundColor(.black)
                
                Spacer()
                
                tagSection
            }
            
            // 카테고리 경로
            categorySection
            
            // 설명
            Text(subject.description)
                .bodyRegular14()
                .foregroundColor(.black)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var tagSection: some View {
        HStack(spacing: 6) {
            Text(subject.duration)
                .bodyRegular14()
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
            
            Text("난이도 \(subject.difficulty)")
                .bodyRegular14()
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
        }
    }
    
    private var categorySection: some View {
        HStack(spacing: 4) {
            ForEach(Array(subject.category.enumerated()), id: \.offset) { index, category in
                Text(category)
                    .bodyRegular14()
                    .foregroundColor(.gray)
                
                if index < subject.category.count - 1 {
                    Text(">")
                        .bodyRegular14()
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct AccountInfoCard: View {
    let socialLoginType: SocialLoginType
    let email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 소셜 로그인 아이콘과 타입
            HStack(spacing: 8) {
                Image(systemName: socialLoginType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(socialLoginType.iconColor)
                
                Text(socialLoginType.rawValue)
                    .bodyRegular16()
                    .foregroundColor(.black)
            }
            
            // 이메일
            HStack(spacing: 8) {
                Text("이메일")
                    .bodyRegular14()
                    .foregroundColor(.gray)
                
                Text(email)
                    .bodyRegular14()
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
