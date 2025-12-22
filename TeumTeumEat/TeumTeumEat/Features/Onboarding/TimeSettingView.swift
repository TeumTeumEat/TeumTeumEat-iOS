//
//  TimeSettingView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import ComposableArchitecture

struct TimeSettingView: View {
    let store: StoreOf<TimeSettingFeature>
    
    var body: some View {
        ZStack {
            // 배경 탭 영역
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // 상단 네비게이션 영역
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
                        currentStep: 2,
                        totalSteps: 5,
                        height: 15,
                        showStepText: false
                    )
                    
                    Text("2/5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 컨텐츠 영역
                VStack(spacing: 24) {
                    Text("대중교통 이용 시간대 입력")
                        .titleSemibold18()
                    
                    Image("pose=front")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 80)
                    
                    // 집을 나오는 시간 (TextField 위치와 동일)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("집을 나오는 시간")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            store.send(.leaveTimeButtonTapped)
                        }) {
                            HStack {
                                
                                Spacer()
                                Text(store.leaveTimeText)
                                    .font(.system(size: 16))
                                    .foregroundColor(store.leaveTime != nil ? .primary : .gray)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.leaveTime != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 집에 돌아오는 시간
                    VStack(alignment: .leading, spacing: 8) {
                        Text("집에 돌아오는 시간")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            store.send(.returnTimeButtonTapped)
                        }) {
                            HStack {
                                Spacer()
                                Text(store.returnTimeText)
                                    .font(.system(size: 16))
                                    .foregroundColor(store.returnTime != nil ? .primary : .gray)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(store.returnTime != nil ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                
                Spacer()
                
                Button {
                    hideKeyboard()
                    store.send(.nextTapped)
                } label: {
                    Text("다음")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(store.canProceed ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!store.canProceed)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            
            if store.isLeaveTimePickerPresented || store.isReturnTimePickerPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if store.isLeaveTimePickerPresented {
                            store.send(.leaveTimePickerDismissed)
                        } else {
                            store.send(.returnTimePickerDismissed)
                        }
                    }
            }
            
            VStack {
                Spacer()
                
                if store.isLeaveTimePickerPresented {
                    TimePickerModal(
                        title: "집을 나오는 시간",
                        selectedTime: Binding(
                            get: { store.leaveTime },
                            set: { store.send(.leaveTimeChanged($0 ?? Date())) }
                        ),
                        onDismiss: {
                            store.send(.leaveTimePickerDismissed)
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                if store.isReturnTimePickerPresented {
                    TimePickerModal(
                        title: "집에 돌아오는 시간",
                        selectedTime: Binding(
                            get: { store.returnTime },
                            set: { store.send(.returnTimeChanged($0 ?? Date())) }
                        ),
                        onDismiss: {
                            store.send(.returnTimePickerDismissed)
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.isLeaveTimePickerPresented)
            .animation(.easeInOut(duration: 0.3), value: store.isReturnTimePickerPresented)
        }
    }
}
