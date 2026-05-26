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
        var currentStep: Step = .rootCategory
        
        // API 데이터
        var categories: [CategoryResponse] = []
        var isLoading: Bool = false
        var loadError: String?
        
        // 선택된 값
        var selectedRootCategory: String?
        var selectedMainCategory: String?
        var selectedSubCategory: String?
        var selectedDetailCategory: CategoryResponse?
        
        // Computed properties
        var rootCategories: [String] {
            let result = Array(Set(categories.compactMap { $0.mainCategory })).sorted()
            print("rootCategories: \(result)")
            return result
        }
        var mainCategories: [String] {
            guard let root = selectedRootCategory else {
                print("mainCategories: selectedRootCategory is nil")
                return []
            }
            let mains = categories
                .filter { $0.mainCategory == root }
                .compactMap { $0.subCategory }
            let result = Array(Set(mains)).sorted()
            print("mainCategories for \(root): \(result)")
            return result
        }

        // currentSubCategories → path[3] 사용 (iOS, Android, ...)
        var currentSubCategories: [String] {
            guard let root = selectedRootCategory,
                  let main = selectedMainCategory else { return [] }
            let subs = categories
                .filter {
                    $0.mainCategory == root &&
                    $0.subCategory == main
                }
                .compactMap { $0.pathComponents[safe: 3] }  // [3] 추출
            return Array(Set(subs)).sorted()
        }

        // currentDetailCategories → name 사용
        var currentDetailCategories: [CategoryResponse] {
            guard let root = selectedRootCategory,
                  let main = selectedMainCategory,
                  let sub = selectedSubCategory else { return [] }
            return categories.filter {
                $0.mainCategory == root &&
                $0.subCategory == main &&
                $0.pathComponents[safe: 3] == sub
            }
        }
        
        var canProceed: Bool {
            switch currentStep {
            case .rootCategory:
                return selectedRootCategory != nil
            case .mainCategory:
                return selectedMainCategory != nil
            case .subCategory:
                return selectedSubCategory != nil
            case .detailCategory:
                return selectedDetailCategory != nil
            }
        }
        
        enum Step {
            case rootCategory
            case mainCategory
            case subCategory
            case detailCategory
        }
    }
    
    enum Action {
        case onAppear
        case retryLoad
        case categoriesLoaded(TaskResult<[CategoryResponse]>)
        
        case backTapped
        case rootCategorySelected(String)
        case mainCategorySelected(String)
        case subCategorySelected(String)
        case detailCategorySelected(CategoryResponse)
        case nextTapped
        
        case delegate(Delegate)
        
        enum Delegate {
            case completed(root: String, main: String, sub: String, detail: CategoryResponse)
            case backToContentSelection
            case saveProgress(root: String?, main: String?, sub: String?, detail: CategoryResponse?)
        }
    }
    
    @Dependency(\.categoryAPIClient) var categoryAPIClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .retryLoad:
                state.isLoading = true
                state.loadError = nil

                return .run { send in
                    await send(.categoriesLoaded(
                        TaskResult {
                            try await categoryAPIClient.fetchCategories()
                        }
                    ))
                }
                
            case .categoriesLoaded(.success(let categories)):
                state.isLoading = false
                state.categories = categories
                state.loadError = nil
                return .none
                
            case .categoriesLoaded(.failure(let error)):
                state.isLoading = false
                
                print("Category Load Error:")
                print("Error Type: \(type(of: error))")
                print("Error: \(error)")
                print("LocalizedDescription: \(error.localizedDescription)")
                
                if let apiError = error as? CategoryAPIError {
                    state.loadError = apiError.errorDescription
                } else {
                    state.loadError = "카테고리를 불러오는데 실패했습니다.\n잠시 후 다시 시도해주세요."
                }
                return .none
                
            // MARK: - Back Navigation
            case .backTapped:
                switch state.currentStep {
                case .rootCategory:
                    return .run { [root = state.selectedRootCategory,
                                   main = state.selectedMainCategory,
                                   sub = state.selectedSubCategory,
                                   detail = state.selectedDetailCategory] send in
                        await send(.delegate(.saveProgress(root: root, main: main, sub: sub, detail: detail)))
                        await send(.delegate(.backToContentSelection))
                    }
                    
                case .mainCategory:
                    state.currentStep = .rootCategory
                    return .send(.delegate(.saveProgress(
                        root: state.selectedRootCategory,
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: state.selectedDetailCategory
                    )))
                    
                case .subCategory:
                    state.currentStep = .mainCategory
                    return .send(.delegate(.saveProgress(
                        root: state.selectedRootCategory,
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: state.selectedDetailCategory
                    )))
                    
                case .detailCategory:
                    state.currentStep = .subCategory
                    return .send(.delegate(.saveProgress(
                        root: state.selectedRootCategory,
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: state.selectedDetailCategory
                    )))
                }
                
            case .nextTapped:
                switch state.currentStep {
                case .rootCategory:
                    state.currentStep = .mainCategory
                    return .none
                    
                case .mainCategory:
                    state.currentStep = .subCategory
                    return .none
                    
                case .subCategory:
                    state.currentStep = .detailCategory
                    return .none
                    
                case .detailCategory:
                    guard let root = state.selectedRootCategory,
                          let main = state.selectedMainCategory,
                          let sub = state.selectedSubCategory,
                          let detail = state.selectedDetailCategory else {
                        return .none
                    }
                    return .send(.delegate(.completed(root: root, main: main, sub: sub, detail: detail)))
                }
                
            case .rootCategorySelected(let category):
                state.selectedRootCategory = category
                return .none
                
            case .mainCategorySelected(let category):
                state.selectedMainCategory = category
                return .none
                
            case .subCategorySelected(let category):
                state.selectedSubCategory = category
                return .none
                
            case .detailCategorySelected(let category):
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

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
