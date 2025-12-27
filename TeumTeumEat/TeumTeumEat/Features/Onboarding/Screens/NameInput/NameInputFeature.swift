//
//  NameInputFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct NameInputFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        
        var validationError: String? {
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            
            // 입력이 없으면 에러 메시지 표시 안 함
            if name.isEmpty {
                return nil
            }
            
            // 길이 체크
            if trimmedName.count > 10 {
                return "이름은 10글자 이하로 입력해주세요"
            }
            
            // 특수문자 체크 (한글, 영문, 숫자만 허용)
            let allowedCharacters = CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: "ㄱ-ㅎㅏ-ㅣ가-힣"))
            if trimmedName.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                return "특수문자는 사용할 수 없어요"
            }
            
            return nil
        }
        
        var canProceed: Bool {
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            
            // 기본 조건
            guard !trimmedName.isEmpty else { return false }
            guard trimmedName.count >= 1 && trimmedName.count <= 10 else { return false }
            guard !name.contains(" ") else { return false }
            
            // 특수문자 체크
            let allowedCharacters = CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: "ㄱ-ㅎㅏ-ㅣ가-힣"))
            return trimmedName.rangeOfCharacter(from: allowedCharacters.inverted) == nil
        }
    }
    
    enum Action {
        case nameChanged(String)
        case nextTapped
        case backTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .nameChanged(name):
                state.name = name.replacingOccurrences(of: " ", with: "")
                return .none
                
            case .nextTapped:
                // 부모에게 알림 (OnboardingFeature에서 처리)
                return .none
                
            case .backTapped:
                // 부모에게 알림
                return .none
            }
        }
    }
}
