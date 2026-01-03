//
//  MyPageFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture


import Foundation

@Reducer
struct MyPageFeature {
    @ObservableState
    struct State: Equatable {
        var selectedSubject: Subject?
        var subjectList: SubjectListFeature.State?
        var isNotificationEnabled: Bool = false
        var appSettings: AppSettingsFeature.State?
        var isLoadingSubject: Bool = false
        
        // 계정 정보
        var socialLoginType: SocialLoginType = .apple
        var email: String = "user@example.com"
    }
    
    enum Action {
        case onAppear
        case selectedSubjectResponse(Result<Subject?, Error>)
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
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingSubject = true
                return .run { send in
                    do {
                        let goals = try await apiClient.fetchGoals()
                        // 가장 최근 goal을 선택된 주제로 설정
                        let selectedSubject = goals.first.map { Subject(from: $0) }
                        await send(.selectedSubjectResponse(.success(selectedSubject)))
                    } catch {
                        await send(.selectedSubjectResponse(.failure(error)))
                    }
                }
                
            case .selectedSubjectResponse(.success(let subject)):
                state.isLoadingSubject = false
                state.selectedSubject = subject
                return .none
                
            case .selectedSubjectResponse(.failure(let error)):
                state.isLoadingSubject = false
                print(" Failed to load selected subject: \(error)")
                // 에러가 나도 UI는 계속 표시
                return .none
                
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
            // 맨 위: 기간, 난이도 태그
            tagSection
            
            // 제목
            Text(subject.name)
                .titleSemibold16()
                .foregroundColor(.black)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // 카테고리 경로 (CATEGORY 타입일 때만 표시)
            if !subject.category.isEmpty && subject.category != ["문서"] {
                categorySection
            }
            
            // 설명 (prompt가 있을 때만 표시)
            if !subject.description.isEmpty {
                Text(subject.description)
                    .bodyRegular14()
                    .foregroundColor(.gray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            
            Spacer()
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
extension Subject {
    init(from goal: GoalResponse) {
        self.id = "\(goal.goalId)"
        
        // 이름 결정
        if goal.type == "CATEGORY", let category = goal.category {
            // 카테고리 타입: "PM > 제품기획 > MVP 정의"
            let pathComponents = category.path
                .components(separatedBy: "/")
                .filter { !$0.isEmpty }
            
            // path의 마지막 부분들과 name을 결합
            if pathComponents.count >= 2 {
                let displayPath = Array(pathComponents.dropFirst()) // "IT" 제외
                self.name = (displayPath + [category.name]).joined(separator: " > ")
            } else {
                self.name = category.name
            }
        } else {
            // 문서 타입: 파일명 사용
            self.name = goal.fileName ?? "문서 기반 학습"
        }
        
        self.duration = goal.studyPeriod
        self.difficulty = goal.difficulty.displayText
        
        // category 배열은 빈 배열로 (표시 안 함)
        self.category = []
        
        // 설명: prompt가 있을 때만 사용 (CATEGORY든 DOCUMENT든)
        if let prompt = goal.prompt {
            // 여러 개의 연속된 \n을 하나로 정리
            let cleaned = prompt
                .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            self.description = cleaned.isEmpty ? "" : cleaned
        } else {
            self.description = ""
        }
    }
}


// Difficulty 변환을 위한 extension
extension String {
    var displayText: String {
        switch self {
        case "EASY": return "하"
        case "MEDIUM": return "중"
        case "HARD": return "상"
        default: return "중"
        }
    }
}
