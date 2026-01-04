//
//  AppSettingsView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/31/25.
//

import SwiftUI
import ComposableArchitecture


struct AppSettingsView: View {
    let store: StoreOf<AppSettingsFeature>
    @FocusState private var isNicknameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            if store.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        nicknameSection
                        leaveTimeSection
                        returnTimeSection
                        usageTimeSection
                        
                        // 에러 메시지
                        if let errorMessage = store.errorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                Text(errorMessage)
                                    .bodyRegular14()
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // 저장하기 버튼
                        TTEButton(
                            title: store.isSaving ? "저장 중..." : "저장하기",
                            size: .large,
                            isEnabled: store.canSave && !store.isSaving
                        ) {
                            store.send(.saveButtonTapped)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color.white)
                .onTapGesture {
                    isNicknameFocused = false
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
                    store.send(.onAppear)
                }
        .sheet(isPresented: Binding(
            get: { store.isLeaveTimePickerPresented },
            set: { if !$0 { store.send(.leaveTimePickerDismissed) } }
        )) {
            TimePickerModal(
                title: "집을 나오는 시간",
                selectedTime: Binding(
                    get: { store.leaveTime },
                    set: { store.send(.leaveTimeChanged($0 ?? store.leaveTime)) }
                ),
                onDismiss: {
                    store.send(.leaveTimePickerDismissed)
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.isReturnTimePickerPresented },
            set: { if !$0 { store.send(.returnTimePickerDismissed) } }
        )) {
            TimePickerModal(
                title: "집에 돌아오는 시간",
                selectedTime: Binding(
                    get: { store.returnTime },
                    set: { store.send(.returnTimeChanged($0 ?? store.returnTime)) }
                ),
                onDismiss: {
                    store.send(.returnTimePickerDismissed)
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { store.isUsageTimePickerPresented },
            set: { if !$0 { store.send(.usageTimePickerDismissed) } }
        )) {
            UsageTimePickerModal(
                title: "틈틈잇 사용 시간",
                selectedMinutes: Binding(
                    get: { store.usageMinutes },
                    set: { store.send(.usageTimeChanged($0)) }
                ),
                onDismiss: {
                    store.send(.usageTimePickerDismissed)
                }
            )
        }
    }
    
    private var navigationBar: some View {
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
                
                Text("틈틈잇 사용 설정")
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
    }
    
    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("닉네임 설정")
                .titleSemibold16()
                .foregroundColor(.black)
            
            TTETextField(
                text: Binding(
                    get: { store.nickname },
                    set: { store.send(.nicknameChanged($0)) }
                ),
                placeholder: "닉네임을 입력하세요",
                allowSpaces: false
            )
            .focused($isNicknameFocused)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var leaveTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("집에서 나오는 시간")
                .titleSemibold16()
                .foregroundColor(.black)
            
            Button(action: {
                store.send(.leaveTimeButtonTapped)
            }) {
                timeButtonContent(text: store.leaveTimeText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var returnTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("집에 돌아오는 시간")
                .titleSemibold16()
                .foregroundColor(.black)
            
            Button(action: {
                store.send(.returnTimeButtonTapped)
            }) {
                timeButtonContent(text: store.returnTimeText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var usageTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("틈틈잇 사용 시간")
                .titleSemibold16()
                .foregroundColor(.black)
            
            Button(action: {
                store.send(.usageTimeButtonTapped)
            }) {
                timeButtonContent(text: "\(store.usageMinutes)분")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func timeButtonContent(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
