//
//  CategorySelectionFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import SwiftUI
import ComposableArchitecture
import CoreNetwork

@Reducer
public struct CategorySelectionFeature {
    public init() {}
    @ObservableState
    public struct State: Equatable {
        public var currentStep: Step = .rootCategory

        // API 데이터
        public var categories: [CategoryResponse] = []
        public var isLoading: Bool = false
        public var loadError: String?

        // 선택된 값
        public var selectedRootCategory: String?
        public var selectedMainCategory: String?
        public var selectedSubCategory: String?
        public var selectedDetailCategory: CategoryResponse?

        public init() {}

        // Computed properties
        public var rootCategories: [String] {
            let result = Array(Set(categories.compactMap { $0.mainCategory })).sorted()
            print("rootCategories: \(result)")
            return result
        }
        public var mainCategories: [String] {
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

        // path[3] 값이 있는 group 목록 (하위 depth로 이동하는 항목)
        public var currentSubCategories: [String] {
            guard let root = selectedRootCategory,
                  let main = selectedMainCategory else { return [] }
            let subs = categories
                .filter {
                    $0.mainCategory == root &&
                    $0.subCategory == main
                }
                .compactMap { $0.pathComponents[safe: 3] }
            return Array(Set(subs)).sorted()
        }

        // path[3]이 없는 leaf 목록 (subCategory 화면에서 직접 선택 가능한 항목)
        public var currentDirectCategories: [CategoryResponse] {
            guard let root = selectedRootCategory,
                  let main = selectedMainCategory else { return [] }
            return categories.filter {
                $0.mainCategory == root &&
                $0.subCategory == main &&
                $0.pathComponents[safe: 3] == nil
            }
        }

        // 최종 선택 항목 목록
        public var currentDetailCategories: [CategoryResponse] {
            guard let root = selectedRootCategory else { return [] }

            // depth-2 경로(/IT테스트): selectedMainCategory가 nil인 경우
            guard let main = selectedMainCategory else {
                return categories.filter { $0.mainCategory == root && $0.subCategory == nil }
            }

            let base = categories.filter { $0.mainCategory == root && $0.subCategory == main }
            if let sub = selectedSubCategory {
                return base.filter { $0.pathComponents[safe: 3] == sub }
            } else {
                return base.filter { $0.pathComponents[safe: 3] == nil }
            }
        }
        
        public var canProceed: Bool {
            switch currentStep {
            case .rootCategory:
                return selectedRootCategory != nil
            case .mainCategory:
                return selectedMainCategory != nil
            case .subCategory:
                // group chip은 탭 시 자동 이동이므로, leaf가 선택됐을 때만 활성화
                return selectedDetailCategory != nil
            case .detailCategory:
                return selectedDetailCategory != nil
            }
        }
        
        public enum Step {
            case rootCategory
            case mainCategory
            case subCategory
            case detailCategory
        }
    }

    public enum Action {
        case onAppear
        case retryLoad
        case categoriesLoaded(TaskResult<[CategoryResponse]>)

        case backTapped
        case rootCategorySelected(String)
        case mainCategorySelected(String)
        case subCategorySelected(String)
        case directCategorySelected(CategoryResponse)
        case detailCategorySelected(CategoryResponse)
        case nextTapped

        case delegate(Delegate)

        public enum Delegate {
            case completed(root: String, main: String, sub: String?, detail: CategoryResponse)
            case backToContentSelection
            case saveProgress(root: String?, main: String?, sub: String?, detail: CategoryResponse?)
        }
    }

    @Dependency(\.categoryAPIClient) var categoryAPIClient

    public var body: some ReducerOf<Self> {
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
                    state.selectedSubCategory = nil
                    state.selectedDetailCategory = nil
                    state.currentStep = .mainCategory
                    return .send(.delegate(.saveProgress(
                        root: state.selectedRootCategory,
                        main: state.selectedMainCategory,
                        sub: nil,
                        detail: nil
                    )))

                case .detailCategory:
                    state.selectedDetailCategory = nil
                    if state.selectedMainCategory == nil {
                        // depth-2 경로: rootCategory로 복귀
                        state.currentStep = .rootCategory
                    } else if state.currentSubCategories.isEmpty {
                        // group이 없었던 경우: mainCategory로 복귀
                        state.currentStep = .mainCategory
                    } else {
                        // group을 통해 진입했던 경우: subCategory로 복귀
                        state.selectedSubCategory = nil
                        state.currentStep = .subCategory
                    }
                    return .send(.delegate(.saveProgress(
                        root: state.selectedRootCategory,
                        main: state.selectedMainCategory,
                        sub: state.selectedSubCategory,
                        detail: nil
                    )))
                }
                
            case .nextTapped:
                switch state.currentStep {
                case .rootCategory:
                    if state.mainCategories.isEmpty {
                        // depth-2 경로(/IT테스트): mainCategory 단계 스킵
                        state.selectedMainCategory = nil
                        state.currentStep = .detailCategory
                    } else {
                        state.currentStep = .mainCategory
                    }
                    return .none

                case .mainCategory:
                    // group이 없으면 detailCategory로 바로 이동 (leaf만 있는 경우)
                    if state.currentSubCategories.isEmpty {
                        state.selectedSubCategory = nil
                        state.currentStep = .detailCategory
                    } else {
                        state.currentStep = .subCategory
                    }
                    return .none

                case .subCategory:
                    // leaf(directCategory)를 선택한 경우 바로 완료
                    guard let root = state.selectedRootCategory,
                          let main = state.selectedMainCategory,
                          let detail = state.selectedDetailCategory else {
                        return .none
                    }
                    return .send(.delegate(.completed(root: root, main: main, sub: state.selectedSubCategory, detail: detail)))

                case .detailCategory:
                    guard let root = state.selectedRootCategory,
                          let detail = state.selectedDetailCategory else {
                        return .none
                    }
                    // depth-2 경로는 selectedMainCategory가 nil → root를 main으로 사용
                    let main = state.selectedMainCategory ?? root
                    return .send(.delegate(.completed(root: root, main: main, sub: state.selectedSubCategory, detail: detail)))
                }
                
            case .rootCategorySelected(let category):
                state.selectedRootCategory = category
                state.selectedMainCategory = nil
                state.selectedSubCategory = nil
                state.selectedDetailCategory = nil
                return .none

            case .mainCategorySelected(let category):
                state.selectedMainCategory = category
                state.selectedSubCategory = nil
                state.selectedDetailCategory = nil
                return .none

            case .subCategorySelected(let category):
                // group chip 탭 → 즉시 detailCategory로 이동
                state.selectedSubCategory = category
                state.selectedDetailCategory = nil
                state.currentStep = .detailCategory
                return .none

            case .directCategorySelected(let category):
                // subCategory 화면의 leaf 버튼 탭 → 선택만 하고 "다음으로"로 완료
                state.selectedSubCategory = nil
                state.selectedDetailCategory = category
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
