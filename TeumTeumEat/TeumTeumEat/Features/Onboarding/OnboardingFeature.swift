//
//  OnboardingFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/21/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentStep: Step = .welcome
        var onboardingData = OnboardingData()
        
        var welcome: WelcomeFeature.State?
        var nameInput: NameInputFeature.State?
        var timeSetting: TimeSettingFeature.State?
        var usageDuration: UsageDurationFeature.State?
        var contentSelection: ContentSelectionFeature.State?
        var fileUpload: FileUploadFeature.State?
        var categorySelection: CategorySelectionFeature.State?
        var difficultySelection: DifficultySelectionFeature.State?
        var durationSelection: DurationSelectionFeature.State?
        var summary: OnboardingSummaryFeature.State?
        var loading: OnboardingLoadingFeature.State?
        var complete: OnboardingCompleteFeature.State?
        
        enum Step: Int {
            case welcome = 0
            case nameInput = 1
            case timeSetting = 2
            case usageDuration = 3
            case contentSelection = 4
            case fileUpload = 5
            case categorySelection = 6
            case difficultySelection = 7
            case durationSelection = 8
            case summary = 9
            case loading = 10
            case complete = 11
        }
        
        init() {
            self.welcome = WelcomeFeature.State()
        }
    }
    
    enum Action {
        case welcome(WelcomeFeature.Action)
        case nameInput(NameInputFeature.Action)
        case timeSetting(TimeSettingFeature.Action)
        case usageDuration(UsageDurationFeature.Action)
        case contentSelection(ContentSelectionFeature.Action)
        case fileUpload(FileUploadFeature.Action)
        case categorySelection(CategorySelectionFeature.Action)
        case difficultySelection(DifficultySelectionFeature.Action)
        case durationSelection(DurationSelectionFeature.Action)
        case summary(OnboardingSummaryFeature.Action)
        case loading(OnboardingLoadingFeature.Action)
        case complete(OnboardingCompleteFeature.Action)
        case nextStep
        case previousStep
    }
    
    var body: some ReducerOf<Self> {
        Reduce(self.core)
            .ifLet(\.welcome, action: \.welcome) {
                WelcomeFeature()
            }
            .ifLet(\.nameInput, action: \.nameInput) {
                NameInputFeature()
            }
            .ifLet(\.timeSetting, action: \.timeSetting) {
                TimeSettingFeature()
            }
            .ifLet(\.usageDuration, action: \.usageDuration) {
                UsageDurationFeature()
            }
            .ifLet(\.contentSelection, action: \.contentSelection) {
                ContentSelectionFeature()
            }
            .ifLet(\.fileUpload, action: \.fileUpload) {
                FileUploadFeature()
            }
            .ifLet(\.categorySelection, action: \.categorySelection) {
                CategorySelectionFeature()
            }
            .ifLet(\.difficultySelection, action: \.difficultySelection) {
                DifficultySelectionFeature()
            }
            .ifLet(\.durationSelection, action: \.durationSelection) {
                DurationSelectionFeature()
            }
            .ifLet(\.summary, action: \.summary) {
                OnboardingSummaryFeature()
            }
            .ifLet(\.loading, action: \.loading) {
                OnboardingLoadingFeature()
            }
            .ifLet(\.complete, action: \.complete) {
                OnboardingCompleteFeature()
            }
    }
    
    func core(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        // Welcome
        case .welcome(.startOnboardingTapped):
            return .send(.nextStep)
            
        // NameInput
        case .nameInput(.nextTapped):
            if let name = state.nameInput?.name {
                state.onboardingData.userName = name
            }
            return .send(.nextStep)
            
        case .nameInput(.backTapped):
            return .send(.previousStep)
            
        // TimeSetting
        case .timeSetting(.nextTapped):
            if let leaveTime = state.timeSetting?.leaveTime {
                state.onboardingData.leaveHomeTime = leaveTime
            }
            if let returnTime = state.timeSetting?.returnTime {
                state.onboardingData.returnHomeTime = returnTime
            }
            return .send(.nextStep)
            
        case .timeSetting(.backTapped):
            return .send(.previousStep)
            
        // UsageDuration
        case .usageDuration(.nextTapped):
            if let duration = state.usageDuration?.selectedDuration {
                state.onboardingData.dailyUsageMinutes = duration.rawValue
            }
            return .send(.nextStep)
            
        case .usageDuration(.backTapped):
            return .send(.previousStep)
            
        // ContentSelection
        case .contentSelection(.nextTapped):
            guard let type = state.contentSelection?.selectedType else {
                return .none
            }
            
            if type == .fileUpload {
                state.onboardingData.contentType = .fileUpload
            } else {
                state.onboardingData.contentType = .category
            }
            
            state.contentSelection = nil
            if type == .fileUpload {
                state.fileUpload = FileUploadFeature.State()
            } else {
                state.categorySelection = CategorySelectionFeature.State()
            }
            
            return .none
            
        case .contentSelection(.backTapped):
            return .send(.previousStep)
            
        // FileUpload
        case .fileUpload(.backTapped):
            state.fileUpload = nil
            state.contentSelection = ContentSelectionFeature.State()
            return .none
            
        case .fileUpload(.nextTapped):
            if let fileURL = state.fileUpload?.selectedFileURL {
                state.onboardingData.uploadedFileURL = fileURL
            }
            // Difficulty 화면으로 이동
            state.fileUpload = nil
            state.difficultySelection = DifficultySelectionFeature.State()
            return .none
            
        // CategorySelection
        case .categorySelection(.backTapped):
            state.categorySelection = nil
            state.contentSelection = ContentSelectionFeature.State()
            return .none
            
        case .categorySelection(.nextTapped):
            if let categories = state.categorySelection?.selectedCategories {
                state.onboardingData.selectedCategories = Array(categories)
            }
            // Difficulty 화면으로 이동
            state.categorySelection = nil
            state.difficultySelection = DifficultySelectionFeature.State()
            return .none
            
        // DifficultySelection
        case .difficultySelection(.backTapped):
            state.difficultySelection = nil
            
            if state.onboardingData.contentType == .fileUpload {
                // 파일 업로드로 돌아가기
                state.fileUpload = FileUploadFeature.State()
                if let url = state.onboardingData.uploadedFileURL {
                    state.fileUpload?.selectedFileURL = url
                    state.fileUpload?.selectedFileName = url.lastPathComponent
                    if let fileSize = try? url.fileSize() {
                        state.fileUpload?.selectedFileSize = fileSize
                    }
                }
            } else {
                // 카테고리 선택으로 돌아가기
                let categories = state.onboardingData.selectedCategories
                state.categorySelection = CategorySelectionFeature.State()
                state.categorySelection?.selectedCategories = Set(categories)
            }
            return .none
            
        case .difficultySelection(.nextTapped):
            if let difficulty = state.difficultySelection?.selectedDifficulty {
                state.onboardingData.difficulty = difficulty.rawValue
            }
            // 커스텀 프롬프트 저장
            state.onboardingData.customPrompt = state.difficultySelection?.customPrompt ?? ""
            
            // Duration 화면으로 이동
            state.difficultySelection = nil
            state.durationSelection = DurationSelectionFeature.State()
            return .none
            
        // DurationSelection
        case .durationSelection(.backTapped):
            state.durationSelection = nil
            
            // 로컬 변수로 복사
            let difficulty = state.onboardingData.difficulty
            let customPrompt = state.onboardingData.customPrompt
            
            state.difficultySelection = DifficultySelectionFeature.State()
            
            // 이전 선택 복원
            if let difficultyValue = difficulty,
               let selectedDifficulty = DifficultySelectionFeature.State.Difficulty(rawValue: difficultyValue) {
                state.difficultySelection?.selectedDifficulty = selectedDifficulty
            }
            state.difficultySelection?.customPrompt = customPrompt
            
            return .none
        case .durationSelection(.nextTapped):
            if let weeks = state.durationSelection?.selectedWeeks {
                state.onboardingData.programWeeks = weeks.rawValue
            }
            state.durationSelection = nil
            state.summary = OnboardingSummaryFeature.State(
                leaveHomeTime: state.onboardingData.leaveHomeTime,
                returnHomeTime: state.onboardingData.returnHomeTime,
                dailyUsageMinutes: state.onboardingData.dailyUsageMinutes,
                programWeeks: state.onboardingData.programWeeks
            )
            return .none
            
        case .summary(.backTapped):
            state.summary = nil
            state.durationSelection = DurationSelectionFeature.State()
            // 이전 선택 복원
            if let weeks = DurationSelectionFeature.State.Weeks(rawValue: state.onboardingData.programWeeks) {
                state.durationSelection?.selectedWeeks = weeks
            }
            return .none
            
        case .summary(.completeTapped):
            // Loading 화면으로 이동
            state.summary = nil
            state.loading = OnboardingLoadingFeature.State()
            return .none
            
        case .loading(.loadingCompleted):
            // Complete 화면으로 이동
            state.loading = nil
            state.complete = OnboardingCompleteFeature.State(
                userName: state.onboardingData.userName
            )
            return .none
            
        case .complete(.startButtonTapped):
            print("🎉 온보딩 완료!")
            print("📊 수집된 데이터: \(state.onboardingData)")
            // TODO: AppFeature로 완료 알림 → 메인 화면으로 이동
            return .none
            
        // NextStep
        case .nextStep:
            switch state.currentStep {
            case .welcome:
                state.welcome = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State()
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .timeSetting
                state.timeSetting = TimeSettingFeature.State()
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .usageDuration
                state.usageDuration = UsageDurationFeature.State()
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .contentSelection
                state.contentSelection = ContentSelectionFeature.State()
                
            case .contentSelection, .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary,.loading, .complete:
                break
            }
            return .none
            
        // PreviousStep
        case .previousStep:
            switch state.currentStep {
            case .welcome:
                break
                
            case .nameInput:
                state.nameInput = nil
                state.currentStep = .welcome
                state.welcome = WelcomeFeature.State()
                
            case .timeSetting:
                state.timeSetting = nil
                state.currentStep = .nameInput
                state.nameInput = NameInputFeature.State(
                    name: state.onboardingData.userName
                )
                
            case .usageDuration:
                state.usageDuration = nil
                state.currentStep = .timeSetting
                state.timeSetting = TimeSettingFeature.State()
                
            case .contentSelection:
                state.contentSelection = nil
                state.currentStep = .usageDuration
                state.usageDuration = UsageDurationFeature.State()
                
            case .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary,.loading,.complete:
                break
            }
            return .none
            
        // Default
        case .welcome, .nameInput, .timeSetting, .usageDuration, .contentSelection, .fileUpload, .categorySelection, .difficultySelection, .durationSelection, .summary,.loading, .complete:
            return .none
        }
    }
}

struct DifficultySelectionView: View {
    let store: StoreOf<DifficultySelectionFeature>
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation
            HStack(spacing: 16) {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                
                TTEProgressBar(
                    currentStep: 4,
                    totalSteps: 5,
                    height: 15
                )
            }
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    Text("난이도를 선택하세요!")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                        .padding(.top, 20)
                    
                    // 난이도 선택 버튼
                    VStack(alignment: .leading, spacing: 8) {
                        Text("난이도")
                            .bodyMedium18()
                            .foregroundColor(.black)
                        
                        Button(action: {
                            store.send(.difficultyButtonTapped)
                        }) {
                            HStack {
                                Spacer()
                                Text(store.difficultyText)
                                    .font(.system(size: 16))
                                    .foregroundColor(store.selectedDifficulty != nil ? .primary : .gray)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.selectedDifficulty != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 56.33)
                    
                    // 커스텀 프롬프트 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("퀴즈 커스텀 설정 (선택)")
                            .bodyMedium18()
                            .foregroundColor(.black)
                        
                        VStack(spacing: 0) {
                            ZStack(alignment: .topLeading) {
                                // Placeholder
                                if store.customPrompt.isEmpty {
                                    Text("퀴즈에 필요한 프롬포트 있으면 설정해주세요")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                // TextEditor
                                TextEditor(text: Binding(
                                    get: { store.customPrompt },
                                    set: { store.send(.customPromptChanged($0)) }
                                ))
                                .font(.system(size: 14))
                                .focused($isTextEditorFocused)
                                .frame(height: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                            }
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isTextEditorFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            
                            // 글자수 카운터
                            HStack {
                                Spacer()
                                Text("\(store.characterCount) / 30")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 24)
                }
                .padding(.top, 60)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isTextEditorFocused = false
            }
            
            Spacer()
            
            TTEButton(
                title: "다음",
                size: .large,
                isEnabled: store.canProceed
            ) {
                isTextEditorFocused = false
                store.send(.nextTapped)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: Binding(
            get: { store.isDifficultyPickerPresented },
            set: { if !$0 { store.send(.difficultyPickerDismissed) } }
        )) {
            DifficultyPickerModal(
                selectedDifficulty: Binding(
                    get: { store.selectedDifficulty },
                    set: { if let difficulty = $0 { store.send(.difficultySelected(difficulty)) } }
                ),
                onDismiss: {
                    store.send(.difficultyPickerDismissed)
                }
            )
        }
    }
}

struct DifficultyPickerModal: View {
    @Binding var selectedDifficulty: DifficultySelectionFeature.State.Difficulty?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 난이도 선택 버튼들
                VStack(spacing: 16) {
                    ForEach(DifficultySelectionFeature.State.Difficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            selectedDifficulty = difficulty
                            onDismiss()
                        }) {
                            HStack(spacing: 16) {
                                // 아이콘
                                Image(systemName: difficulty.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedDifficulty == difficulty ? .blue : .primary)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // 난이도 이름
                                    Text(difficulty.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    // 설명
                                    Text(difficulty.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // 체크마크
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedDifficulty == difficulty ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle("난이도 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}
