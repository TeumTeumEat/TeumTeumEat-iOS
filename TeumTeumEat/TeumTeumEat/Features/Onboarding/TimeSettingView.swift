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
        GeometryReader { geometry in
            ZStack {
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
                        
                        TTEProgressBar(
                            currentStep: 2,
                            totalSteps: 5,
                            height: 15
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            Text("대중교통 이용 시간대 입력")
                                .titleSemibold18()
                            
                            Image("pose=front")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 80)
                                .padding(.top, 20)
                            
                            // 집을 나오는 시간
                            VStack(alignment: .leading, spacing: 8) {
                                Text("집을 나오는 시간")
                                    .bodyMedium18()
                                    .foregroundColor(.black)
                                
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
                            .padding(.top, 56.33)
                            
                            // 집에 돌아오는 시간
                            VStack(alignment: .leading, spacing: 8) {
                                Text("집에 돌아오는 시간")
                                    .bodyMedium18()
                                    .foregroundColor(.black)
                                
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
                            .padding(.top, 50)
                            
                            Button(action: {
                                store.send(.alarmToggleTapped)
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .stroke(store.enableAlarm ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                            .frame(width: 24, height: 24)
                                        
                                        if store.enableAlarm {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 24, height: 24)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    Text("해당 시간에 알람 받을까요?")
                                        .bodyRegular14()
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 89)
                            .padding(.bottom, 18)
                            
                            Color.clear
                                .frame(height: (store.isLeaveTimePickerPresented || store.isReturnTimePickerPresented) ? geometry.size.height * 0.5 : 0)
                        }
                        .padding(.top, 60)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    
                    Spacer()
                    
                    TTEButton(
                        title: "다음",
                        size: .large,
                        isEnabled: store.canProceed
                    ) {
                        store.send(.nextTapped)
                    }
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
}
