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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    
                    TTEProgressBar(
                        currentStep: 2,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 20)
                
                GeometryReader { scrollGeometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            Image("character_timeSetting")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 285)
                                .padding(.horizontal, 32)
                                .padding(.top, 1)
                            
                            // 집을 나오는 시간
                            VStack(alignment: .leading, spacing: 12) {
                                Text("집에서 나오는 시간")
                                    .stSemibold16()
                                    .foregroundColor(.gray900)
                                
                                Button(action: {
                                    store.send(.leaveTimeButtonTapped)
                                }) {
                                    HStack {
                                        Spacer()
                                        Text(store.leaveTimeText)
                                            .btMedium18_24()
                                            .foregroundColor(store.leaveTime != nil ? .gray900 : .gray600)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(store.leaveTime != nil ? Color.blue500 : Color.gray300, lineWidth: 2)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 18)
                            
                            // 집에 돌아오는 시간
                            VStack(alignment: .leading, spacing: 12) {
                                Text("집에 돌아오는 시간")
                                    .stSemibold16()
                                    .foregroundColor(.gray900)
                                
                                Button(action: {
                                    store.send(.returnTimeButtonTapped)
                                }) {
                                    HStack {
                                        Spacer()
                                        Text(store.returnTimeText)
                                            .btMedium18_24()
                                            .foregroundColor(store.returnTime != nil ? .gray900 : .gray600)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(store.returnTime != nil ? Color.blue500 : Color.gray300, lineWidth: 2)
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 40)
                            
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

                                    Text("해당 시간에 알림을 받으실건가요? (필수)")
                                        .bodyRegular14()
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 46)
                            
                            Spacer()
                                .frame(minHeight: 20)
                            
                            TTEButton(
                                title: "다음으로",
                                size: .large,
                                isEnabled: store.canProceed
                            ) {
                                store.send(.nextTapped)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                        .frame(minHeight: scrollGeometry.size.height)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(.white)
        }
        .colorScheme(.light)
        .alert("알림 권한 필요", isPresented: Binding(
            get: { store.showSettingsAlert },
            set: { if !$0 { store.send(.dismissSettingsAlert) } }
        )) {
            Button("취소", role: .cancel) {
                store.send(.dismissSettingsAlert)
            }
            Button("설정으로 이동") {
                store.send(.openSettings)
            }
        } message: {
            Text("알림을 받으려면 설정에서 알림 권한을 허용해주세요.")
        }
        .onAppear {
            // 화면 진입 시 권한 상태 체크
            store.send(.checkNotificationStatus)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // 앱이 포그라운드로 돌아올 때
                store.send(.checkNotificationStatus)
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isLeaveTimePickerPresented },
            set: { if !$0 { store.send(.leaveTimePickerDismissed) } }
        )) {
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
        }
        .sheet(isPresented: Binding(
            get: { store.isReturnTimePickerPresented },
            set: { if !$0 { store.send(.returnTimePickerDismissed) } }
        )) {
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
        }
    }
}
