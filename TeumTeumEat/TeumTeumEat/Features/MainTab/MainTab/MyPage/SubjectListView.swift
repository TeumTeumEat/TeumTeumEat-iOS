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
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(store.subjects) { subject in
                        Button {
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}
