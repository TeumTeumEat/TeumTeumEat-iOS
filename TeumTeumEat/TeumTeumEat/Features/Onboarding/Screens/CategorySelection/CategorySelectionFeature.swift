//
//  CategorySelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CategorySelectionFeature {
    @ObservableState
    struct State: Equatable {
        // 현재 단계
        var currentStep: Step = .mainCategory
        
        // 선택된 카테고리들
        var selectedMainCategory: MainCategory?
        var selectedSubCategory: SubCategory?
        var selectedDetailCategory: DetailCategory?
        
        // 다음 버튼 활성화
        var canProceed: Bool {
            switch currentStep {
            case .mainCategory:
                return selectedMainCategory != nil
            case .subCategory:
                return selectedSubCategory != nil
            case .detailCategory:
                return selectedDetailCategory != nil
            }
        }
        
        enum Step {
            case mainCategory
            case subCategory
            case detailCategory
        }
    }
    
    enum Action {
        case backTapped
        case mainCategorySelected(MainCategory)
        case subCategorySelected(SubCategory)
        case detailCategorySelected(DetailCategory)
        case nextTapped
        case delegate(Delegate)
        
        enum Delegate {
            case completed(MainCategory, SubCategory, DetailCategory)
            case backToContentSelection
            case saveProgress(main: MainCategory?, sub: SubCategory?, detail: DetailCategory?)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            print("CategorySelectionFeature - Action: \(action)")
            print("현재 Step: \(state.currentStep)")
            
            switch action {
            case .backTapped:
                print("뒤로가기 - 현재 Step: \(state.currentStep)")
                
                switch state.currentStep {
                case .mainCategory:
                    print("1단계 → ContentSelection으로 (delegate)")
                    // 저장 후 ContentSelection으로
                    return .run { [main = state.selectedMainCategory, sub = state.selectedSubCategory, detail = state.selectedDetailCategory] send in
                        await send(.delegate(.saveProgress(main: main, sub: sub, detail: detail)))
                        await send(.delegate(.backToContentSelection))
                    }
                    
                case .subCategory:
                    print("2단계 → 1단계로")
                    state.currentStep = .mainCategory
                    // 선택값 유지 (초기화 제거)
                    
                    // 저장
                    return .send(.delegate(.saveProgress(
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: state.selectedDetailCategory
                    )))
                    
                case .detailCategory:
                    print("🔙 3단계 → 2단계로")
                    state.currentStep = .subCategory
                    // 선택값 유지 (초기화 제거)
                    
                    // 저장
                    return .send(.delegate(.saveProgress(
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: state.selectedDetailCategory
                    )))
                }
                
            case .nextTapped:
                print("다음 - 현재 Step: \(state.currentStep)")
                switch state.currentStep {
                case .mainCategory:
                    print("1단계 → 2단계로")
                    state.currentStep = .subCategory
                    return .none
                    
                case .subCategory:
                    print("2단계 → 3단계로")
                    state.currentStep = .detailCategory
                    return .none
                    
                case .detailCategory:
                    print("3단계 완료 (delegate)")
                    guard let main = state.selectedMainCategory,
                          let sub = state.selectedSubCategory,
                          let detail = state.selectedDetailCategory else {
                        return .none
                    }
                    return .send(.delegate(.completed(main, sub, detail)))
                }
                
            case .mainCategorySelected(let category):
                print("Main 선택: \(category.rawValue)")
                state.selectedMainCategory = category
                return .none
                
            case .subCategorySelected(let category):
                print("Sub 선택: \(category.rawValue)")
                state.selectedSubCategory = category
                return .none
                
            case .detailCategorySelected(let category):
                print("Detail 선택: \(category.rawValue)")
                state.selectedDetailCategory = category
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

enum Category: String, CaseIterable, Codable, Equatable {
    case travel = "여행여행"
    case food = "음식"
    case sports = "운동운동운동"
    case study = "공부"
    case hobby = "취미취미취미"
    case culture = "문화"
    
    var icon: String {
        switch self {
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .sports: return "figure.run"
        case .study: return "book.fill"
        case .hobby: return "paintbrush.fill"
        case .culture: return "theatermasks.fill"
        }
    }
}
