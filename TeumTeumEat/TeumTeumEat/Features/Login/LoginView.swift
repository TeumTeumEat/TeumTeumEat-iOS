//
//  LoginView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
    let store: StoreOf<LoginFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("TeumTeumEat")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("간편하게 로그인하고 시작하세요")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            VStack(spacing: 12) {
                // 카카오 로그인
                Button {
                    store.send(.kakaoLoginTapped)
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("카카오로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                
                // 애플 로그인
                Button {
                    store.send(.appleLoginTapped)
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Apple로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
            }
            .padding(.horizontal, 20)
            .disabled(store.isLoading)
            
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            if store.isLoading {
                ProgressView()
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .padding()
    }
}
