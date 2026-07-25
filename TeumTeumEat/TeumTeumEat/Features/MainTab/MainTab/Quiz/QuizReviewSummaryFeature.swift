//
//  QuizReviewSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI
import ComposableArchitecture
import Lottie

@Reducer
struct QuizReviewSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var summaryText: String
        
        init(summaryText: String) {
            self.summaryText = summaryText
        }
    }
    
    enum Action {
        case backButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case back  // 뒤로가기
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                print("QuizReviewSummary: 뒤로가기")
                return .send(.delegate(.back))
                
            case .delegate:
                return .none
            }
        }
    }
}

import MarkdownUI

struct QuizReviewSummaryView: View {
    let store: StoreOf<QuizReviewSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Custom Navigation Bar
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            store.send(.backButtonTapped)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("오늘의 냠냠지식")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                        
                        Spacer()
                        
                        // 우측 빈 공간 (중앙 정렬용)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                }
                .background(Color.white)
                
                // Markdown 콘텐츠
                ScrollView {
                    Markdown(store.summaryText)
                        .markdownTheme(.gitHub)
                        .colorScheme(.light)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.white)
            }
        }
        .background(.white)
        .navigationBarHidden(true)
    }
}


@Reducer
struct QuizCompleteFeature {
    @ObservableState
    struct State: Equatable {
        // 필요한 경우 완료 관련 데이터 추가
    }
    
    enum Action {
        case homeButtonTapped
        case historyButtonTapped
        case delegate(Delegate)
    }
    
    enum Delegate {
        case navigateToHome
        case navigateToHistory
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .homeButtonTapped:
                print("QuizComplete: 홈으로 이동")
                return .send(.delegate(.navigateToHome))
                
            case .historyButtonTapped:
                print("QuizComplete: 히스토리로 이동")
                return .send(.delegate(.navigateToHistory))
                
            case .delegate:
                return .none
            }
        }
    }
}

struct QuizCompleteView: View {
    let store: StoreOf<QuizCompleteFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                
                LottieView(animation: .named("quiz_fin"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .frame(width: 280, height: 280)
                
                Text("오늘의 틈틈잇 \n완료!")
                    .font(.system(size: 30, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // 히스토리로
                Button {
                    store.send(.historyButtonTapped)
                } label: {
                    Text("내 스탬프")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue100, lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
                
                // 홈으로
                Button {
                    store.send(.homeButtonTapped)
                } label: {
                    Text("홈으로")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue500)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(.white)
    }
}


// MARK: - QuizSubjectCompleteFeature

@Reducer
struct QuizSubjectCompleteFeature {
    @ObservableState
    struct State: Equatable {
        var showSubjectTypeModal: Bool = false
    }

    enum Action {
        case homeButtonTapped
        case addSubjectButtonTapped
        case subjectTypeModalDismissed
        case fileUploadTapped
        case categorySelectTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case navigateToHome
        case navigateToFileUpload
        case navigateToCategory
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .homeButtonTapped:
                return .send(.delegate(.navigateToHome))
            case .addSubjectButtonTapped:
                state.showSubjectTypeModal = true
                return .none
            case .subjectTypeModalDismissed:
                state.showSubjectTypeModal = false
                return .none
            case .fileUploadTapped:
                state.showSubjectTypeModal = false
                return .send(.delegate(.navigateToFileUpload))
            case .categorySelectTapped:
                state.showSubjectTypeModal = false
                return .send(.delegate(.navigateToCategory))
            case .delegate:
                return .none
            }
        }
    }
}

struct SubjectFinView: View {
    let store: StoreOf<QuizSubjectCompleteFeature>

    var body: some View {
        ZStack {
            // MARK: - 메인 화면
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image("char_exited_quiz_finish")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 240)

                    VStack(spacing: 8) {
                        Text("해당 주제를\n모두 완주했어요!")
                            .font(Font.custom("Pretendard-SemiBold", size: 30))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        Text("새로운 여정을 시작해 볼까요?")
                            .font(Font.custom("Pretendard-SemiBold", size: 20))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        store.send(.homeButtonTapped)
                    } label: {
                        Text("홈으로 가기")
                            .font(.st_semibold_16)
                            .foregroundColor(Color(hex: "2B8FFF"))
                    }

                    Button {
                        store.send(.addSubjectButtonTapped)
                    } label: {
                        Text("새로운 틈틈잇 시작하기")
                            .btSemiBold20_24()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.blue500)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 34)
            }
            .background(.white)

            // MARK: - Dim + 주제 형태 선택 모달
            if store.showSubjectTypeModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.subjectTypeModalDismissed)
                    }

                SubjectTypeSelectModal(
                    onFileUpload: { store.send(.fileUploadTapped) },
                    onCategorySelect: { store.send(.categorySelectTapped) },
                    onDismiss: { store.send(.subjectTypeModalDismissed) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.showSubjectTypeModal)
    }
}

// MARK: - 주제 형태 선택 모달
struct SubjectTypeSelectModal: View {
    let onFileUpload: () -> Void
    let onCategorySelect: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
                // 타이틀
            Text("주제 형태를 선택하세요")
                .font(.t_bold_22)
                .foregroundColor(.black)
                .padding(.top, 28)

            // 선택 버튼
            HStack(spacing: 10) {
                Button(action: onFileUpload) {
                    Text("파일 업로드")
                        .btMedium18_24()
                        .foregroundColor(Color(hex: "2B8FFF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "EAF4FF"))
                        .cornerRadius(16)
                }

                Button(action: onCategorySelect) {
                    Text("카테고리 선택")
                        .btMedium18_24()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "2B8FFF"))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
        .padding(.horizontal, 36)
    }
}
