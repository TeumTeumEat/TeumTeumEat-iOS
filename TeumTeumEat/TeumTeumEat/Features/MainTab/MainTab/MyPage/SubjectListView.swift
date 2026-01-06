//
//  SubjectListView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture

struct SubjectListView: View {
    let store: StoreOf<SubjectListFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            VStack(spacing: 0) {
                HStack {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("학습주제")
                        .titleSemibold20()
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
            }
            .background(Color.white)
            
            if store.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = store.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Text("목록을 불러올 수 없습니다")
                        .font(.system(size: 16, weight: .semibold))
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                Spacer()
            } else if store.subjects.isEmpty {
                Spacer()
                Text("등록된 학습주제가 없습니다")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(store.subjects) { subject in
                            Button {
                                print("🔍 Subject tapped: \(subject.name)")
                                store.send(.subjectTapped(subject))
                            } label: {
                                SelectedSubjectCard(subject: subject)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            print("🔍 SubjectListView appeared - calling API")
            store.send(.onAppear)
        }
    }
}
