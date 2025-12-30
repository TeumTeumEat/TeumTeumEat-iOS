//
//  SubjectListFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import ComposableArchitecture
import Foundation

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
    let duration: String
    let difficulty: String
    let category: [String]
    let description: String
}

