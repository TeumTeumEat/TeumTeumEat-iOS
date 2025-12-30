//
//  HomeFeature.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/30/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var fireCount: Int = 0
        var stampCount: Int = 0
        var isTodayQuizCompleted: Bool = false
    }
    
    enum Action {
        case settingTapped
        case toggleQuizStatus
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .settingTapped:
                print("설정 버튼 클릭")
                // TODO: 설정 화면으로 이동
                return .none
            case .toggleQuizStatus:
                state.isTodayQuizCompleted.toggle()
                return .none
            }
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeNavigationBar(
                    fireCount: store.fireCount,
                    stampCount: store.stampCount,
                    onSettingTapped: {
                       // store.send(.settingTapped)
                        store.send(.toggleQuizStatus)
                    }
                )
                
                Spacer()
                    .frame(height: store.isTodayQuizCompleted ? 5 : 11)
                
                CharacterImageView(isTodayQuizCompleted: store.isTodayQuizCompleted)
                
                ScrollView {
                    VStack {

                        
                        // TODO: 홈 콘텐츠
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Character Image View
struct CharacterImageView: View {
    let isTodayQuizCompleted: Bool
    
    var body: some View {
        if isTodayQuizCompleted {
            Image("character_eat")
                .resizable()
                .scaledToFit()
                .frame(height: 554)
                .padding(.leading, 30)
                .padding(.trailing, 8.47)
        } else {
            Image("character_hamburger")
                .resizable()
                .scaledToFit()
                .frame(height: 548)
                .padding(.leading, 30)
                .padding(.trailing, 3)
        }
    }
}

struct HomeNavigationBar: View {
    let fireCount: Int
    let stampCount: Int
    let onSettingTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 로고
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 22)
                

            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("fire")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(fireCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
                .frame(width: 46)
            
            HStack(spacing: 6) {
                Image("stamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("\(stampCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 설정 버튼
            Button(action: onSettingTapped) {
                Image("setting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}
