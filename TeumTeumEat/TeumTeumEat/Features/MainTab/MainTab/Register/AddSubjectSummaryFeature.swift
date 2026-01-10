//
//  AddSubjectSummaryFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 1/4/26.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AddSubjectSummaryFeature {
    @ObservableState
    struct State: Equatable {
        let contentType: OnboardingData.ContentType
        let fileName: String?
        let mainCategory: String?
        let subCategory: String?
        let detailCategory: String?
        let difficulty: String?
        let customPrompt: String
        let programWeeks: Int
        
        var categoryText: String {
            guard let main = mainCategory,
                  let sub = subCategory,
                  let detail = detailCategory else {
                return "미설정"
            }
            return "\(main) > \(sub) > \(detail)"
        }
        
        var fileNameText: String {
            fileName ?? "없음"
        }
        
        var difficultyText: String {
            difficulty ?? "미설정"
        }
        
        var durationText: String {
            "\(programWeeks)주"
        }
    }
    
    enum Action {
        case backTapped
        case completeTapped
        case delegate(Delegate)
        
        enum Delegate {
            case back
            case complete
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.back))
                
            case .completeTapped:
                return .send(.delegate(.complete)) 
                
            case .delegate:
                return .none
            }
        }
    }
}

struct AddSubjectSummaryView: View {
    let store: StoreOf<AddSubjectSummaryFeature>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
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
                        
                        Spacer()
                        
                        Text("확인")
                            .titleSemibold20()
                        
                        Spacer()
                        
                        // 균형 맞추기용 투명 뷰
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_summary")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 283)
                                .padding(.horizontal, 32)
                                .padding(.top, 5)
                            
                            VStack(spacing: 16) {
                                if store.contentType == .category {
                                    SummaryRow(
                                        title: "관심 분야",
                                        value: store.categoryText
                                    )
                                } else {
                                    SummaryRow(
                                        title: "업로드 파일",
                                        value: store.fileNameText
                                    )
                                }
                                
                                SummaryRow(
                                    title: "난이도",
                                    value: store.difficultyText
                                )
                                
                                if !store.customPrompt.isEmpty {
                                    SummaryRow(
                                        title: "요청 프롬프트",
                                        value: store.customPrompt
                                    )
                                }
                                
                                SummaryRow(
                                    title: "공부기간",
                                    value: store.durationText
                                )
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            .padding(.bottom, 180)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground).opacity(0),
                            Color(UIColor.systemBackground).opacity(0.8),
                            Color(UIColor.systemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("입력한 정보는 마이페이지에서 수정할 수 있어요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TTEButton(
                            title: "학습 목표 등록하기",
                            size: .large,
                            isEnabled: true
                        ) {
                            store.send(.completeTapped)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                    .background(Color(UIColor.systemBackground))
                }
            }
        }
        .background(.white)
        .colorScheme(.light)
    }
}
