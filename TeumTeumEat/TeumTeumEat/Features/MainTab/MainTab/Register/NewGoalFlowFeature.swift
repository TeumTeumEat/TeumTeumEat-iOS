//
//  NewGoalFlowFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture
import OnboardingFeature

@Reducer
struct NewGoalFlowFeature {
    @ObservableState
    struct State: Equatable {
        // 콘텐츠 선택 화면은 유지 (주제 추가에서 뒤로 오면 선택 상태 그대로)
        var contentSelection: ContentSelectionFeature.State = .init()
        var addSubject: AddSubjectFlowFeature.State?
    }

    enum Action {
        case contentSelection(ContentSelectionFeature.Action)
        case addSubject(AddSubjectFlowFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case completed
            case cancelled
        }
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.contentSelection, action: \.contentSelection) {
            ContentSelectionFeature()
        }

        Reduce { state, action in
            switch action {
            case .contentSelection(.nextTapped):
                switch state.contentSelection.selectedType {
                case .category:
                    state.addSubject = AddSubjectFlowFeature.State(contentType: .category)
                case .fileUpload:
                    state.addSubject = AddSubjectFlowFeature.State(contentType: .fileUpload)
                case nil:
                    break
                }
                return .none

            case .contentSelection(.backTapped):
                return .send(.delegate(.cancelled))

            case .addSubject(.delegate(.completed)):
                return .send(.delegate(.completed))

            case .addSubject(.delegate(.cancelled)):
                state.addSubject = nil
                return .none

            case .contentSelection, .addSubject, .delegate:
                return .none
            }
        }
        .ifLet(\.addSubject, action: \.addSubject) {
            AddSubjectFlowFeature()
        }
    }
}

struct NewGoalFlowView: View {
    let store: StoreOf<NewGoalFlowFeature>

    var body: some View {
        if let addSubjectStore = store.scope(state: \.addSubject, action: \.addSubject) {
            AddSubjectFlowView(store: addSubjectStore)
                .transition(AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
        } else {
            ContentSelectionView(store: store.scope(state: \.contentSelection, action: \.contentSelection))
                .transition(AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
        }
    }
}
