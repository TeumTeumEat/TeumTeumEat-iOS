//
//  NewGoalFlowFeature.swift
//  TeumTeumEat
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct NewGoalFlowFeature {
    @ObservableState
    struct State: Equatable {
        var step: Step = .contentSelection
        var contentSelection: ContentSelectionFeature.State = .init()
        var addSubject: AddSubjectFeature.State?
        var addSubjectFile: AddSubjectFileFeature.State?

        enum Step: Equatable {
            case contentSelection
            case addSubject
            case addSubjectFile
        }
    }

    enum Action {
        case contentSelection(ContentSelectionFeature.Action)
        case addSubject(AddSubjectFeature.Action)
        case addSubjectFile(AddSubjectFileFeature.Action)
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
                    state.step = .addSubject
                    state.addSubject = AddSubjectFeature.State()
                case .fileUpload:
                    state.step = .addSubjectFile
                    state.addSubjectFile = AddSubjectFileFeature.State()
                case nil:
                    break
                }
                return .none

            case .contentSelection(.backTapped):
                return .send(.delegate(.cancelled))

            case .addSubject(.delegate(.completed)):
                return .send(.delegate(.completed))

            case .addSubject(.delegate(.cancelled)):
                state.step = .contentSelection
                state.addSubject = nil
                return .none

            case .addSubjectFile(.delegate(.completed)):
                return .send(.delegate(.completed))

            case .addSubjectFile(.delegate(.cancelled)):
                state.step = .contentSelection
                state.addSubjectFile = nil
                return .none

            case .contentSelection, .addSubject, .addSubjectFile, .delegate:
                return .none
            }
        }
        .ifLet(\.addSubject, action: \.addSubject) {
            AddSubjectFeature()
        }
        .ifLet(\.addSubjectFile, action: \.addSubjectFile) {
            AddSubjectFileFeature()
        }
    }
}

struct NewGoalFlowView: View {
    let store: StoreOf<NewGoalFlowFeature>

    var body: some View {
        switch store.step {
        case .contentSelection:
            ContentSelectionView(store: store.scope(state: \.contentSelection, action: \.contentSelection))
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))

        case .addSubject:
            if let addSubjectStore = store.scope(state: \.addSubject, action: \.addSubject) {
                AddSubjectView(store: addSubjectStore)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }

        case .addSubjectFile:
            if let addSubjectFileStore = store.scope(state: \.addSubjectFile, action: \.addSubjectFile) {
                AddSubjectFileView(store: addSubjectFileStore)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            }
        }
    }
}
