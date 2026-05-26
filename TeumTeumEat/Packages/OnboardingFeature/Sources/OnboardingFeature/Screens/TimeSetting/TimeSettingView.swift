//
//  TimeSettingView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/22/25.
//

import SwiftUI
import ComposableArchitecture
import DesignSystem

struct TimeSettingView: View {
    let store: StoreOf<TimeSettingFeature>
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
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
                        currentStep: 1,
                        totalSteps: 5,
                        height: 15
                    )
                }
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        Image("character_comment", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 265)
                            .padding(.horizontal, 32)
                            .padding(.top, 21)

                        // 일일 사용 시간
                        VStack(alignment: .leading, spacing: 12) {
                            Text("학습분량")
                                .stSemibold16()
                                .foregroundColor(.gray900)
                            HStack(spacing: 12) {
                                ForEach([TimeSettingFeature.State.Duration.three, .five], id: \.self) { duration in
                                    DurationSelectButton(
                                        text: duration.displayText,
                                        isSelected: store.selectedDuration == duration
                                    ) {
                                        store.send(.durationSelected(duration))
                                    }
                                }
                            }
                            HStack(spacing: 12) {
                                ForEach([TimeSettingFeature.State.Duration.seven, .ten], id: \.self) { duration in
                                    DurationSelectButton(
                                        text: duration.displayText,
                                        isSelected: store.selectedDuration == duration
                                    ) {
                                        store.send(.durationSelected(duration))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 18)

                        // 알림시간
                        VStack(alignment: .leading, spacing: 12) {
                            Text("알림시간")
                                .stSemibold16()
                                .foregroundColor(.gray900)

                            Text("* 학습을 이어갈 수 있도록 하루에 최대 2번까지 알람을 보내드려요")
                                .cRegular12()
                                .foregroundColor(.gray600)

                            Button(action: {
                                store.send(.leaveTimeButtonTapped)
                            }) {
                                HStack(spacing: 8) {
                                    Spacer()
                                    Text("1번째 알림")
                                        .bodyRegular14()
                                        .foregroundColor(.gray600)
                                    Text(store.leaveTimeText)
                                        .btMedium18_24()
                                        .foregroundColor(.gray900)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.gray300, lineWidth: 2)
                                )
                                .cornerRadius(12)
                            }

                            Button(action: {
                                store.send(.returnTimeButtonTapped)
                            }) {
                                HStack(spacing: 8) {
                                    Spacer()
                                    Text("2번째 알림")
                                        .bodyRegular14()
                                        .foregroundColor(.gray600)
                                    Text(store.returnTimeText)
                                        .btMedium18_24()
                                        .foregroundColor(.gray900)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.gray300, lineWidth: 2)
                                )
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 18)
                        .padding(.bottom, 20)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                Spacer().frame(height: 12)

                // 하단 고정 영역
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
                .padding(.top, 16)

                TTEButton(
                    title: "다음으로",
                    size: .largeFull,
                    isEnabled: store.canProceed
                ) {
                    store.send(.nextTapped)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
        }
        .background(.white)
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
                    get: { Optional(store.leaveTime) },
                    set: { store.send(.leaveTimeChanged($0 ?? Date())) }
                ),
                onDismiss: {
                    store.send(.leaveTimePickerDismissed)
                },
                minuteInterval: 10
            )
        }
        .sheet(isPresented: Binding(
            get: { store.isReturnTimePickerPresented },
            set: { if !$0 { store.send(.returnTimePickerDismissed) } }
        )) {
            TimePickerModal(
                title: "집에 돌아오는 시간",
                selectedTime: Binding(
                    get: { Optional(store.returnTime) },
                    set: { store.send(.returnTimeChanged($0 ?? Date())) }
                ),
                onDismiss: {
                    store.send(.returnTimePickerDismissed)
                },
                minuteInterval: 10
            )
        }
    }
}
