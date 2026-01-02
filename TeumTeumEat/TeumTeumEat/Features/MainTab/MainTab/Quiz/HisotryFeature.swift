//
//  QuizFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HistoryFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        var myPage: MyPageFeature.State?
        
        // 탭 관련 상태
        var selectedTab: Int = 0
        let tabs: [TTETabItem] = [
            TTETabItem(title: "날짜별"),
            TTETabItem(title: "주제별")
        ]
    }
    
    enum Action {
        case settingTapped
        case myPage(MyPageFeature.Action)
        case tabSelected(Int)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingTapped:
                state.myPage = MyPageFeature.State()
                return .none
                
            case .tabSelected(let index):
                state.selectedTab = index
                return .none
                
            case .myPage(.delegate(.dismissed)):
                state.myPage = nil
                return .none
                
            case .myPage:
                return .none
            }
        }
        .ifLet(\.myPage, action: \.myPage) {
            MyPageFeature()
        }
    }
}

struct HistoryView: View {
    let store: StoreOf<HistoryFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 네비게이션 바
                HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                        store.send(.settingTapped)
                    }
                )
                .padding(.horizontal, 20) // 네비게이션 바만 padding
               
                
                Spacer()
                    .frame(height: 16)
                
                // 탭 헤더 - 전체 너비
                TTETabHeader(
                    selectedTab: Binding(
                        get: { store.selectedTab },
                        set: { store.send(.tabSelected($0)) }
                    ),
                    tabs: store.tabs
                )
                .background(.red)
                
                // 탭별 콘텐츠 - 전체 너비
                ScrollView {
                    VStack(spacing: 16) {
                        switch store.selectedTab {
                        case 0:
                            // 날짜별
                            VStack(spacing: 16) {
                                HistoryDateCard(
                                    fireCount: 5,
                                    dateText: "얼른 시작 틈틈잇",
                                    characterImage: "Frame 7407"
                                )
                                HistoryDateCard(
                                    fireCount: 5,
                                    dateText: "얼른 시작 틈틈잇",
                                    characterImage: "Frame 7408"
                                )
                                
                                HistoryDateCard(
                                    fireCount: 5,
                                    dateText: "얼른 시작 틈틈잇",
                                    characterImage: "Frame 7409"
                                )
                                
                                HistoryDateCard(
                                    fireCount: 5,
                                    dateText: "얼른 시작 틈틈잇",
                                    characterImage: "Frame 7410"
                                )
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 32)
                            
                        case 1:
                            // 주제별
                            Text("주제별 히스토리")
                                .padding(.top, 32)
                            
                        default:
                            EmptyView()
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.yellow)
            }
            .navigationBarHidden(true)
            .navigationDestination(
                isPresented: Binding(
                    get: { store.myPage != nil },
                    set: { if !$0 { store.send(.myPage(.delegate(.dismissed))) } }
                )
            ) {
                if let myPageStore = store.scope(state: \.myPage, action: \.myPage) {
                    MyPageView(store: myPageStore)
                }
            }
        }
    }
}



struct HistoryDateCard: View {
    let fireCount: Int
    let dateText: String
    let characterImage: String
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                // 왼쪽 영역 - 남은 공간 차지
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 8) {
                        Image("fire")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.orange)
                            .frame(width: 50, height: 50)
                       
                        
                        Text("\(fireCount)")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(.black)
                    }
                    .frame(height: 66)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text(dateText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(height: 42)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                
                // 오른쪽 영역 - 카드 절반 크기
                Image(characterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width / 2)
                    .frame(height: 188)
                    .clipped()
            }
        }
        .frame(height: 188)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
