//
//  ErrorOverlayView.swift
//  TeumTeumEat
//
//  Created by 임재현 on 6/21/26.
//

import SwiftUI

struct ErrorOverlayView: View {
    let message: String
    let isRetrying: Bool
    let onRetry: () -> Void
    let onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray400)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray700)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        Group {
                            if isRetrying {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.85)
                                    Text("다시 시도 중...")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text("다시 시도")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isRetrying ? Color.blue500.opacity(0.6) : Color.blue500)
                        .cornerRadius(12)
                    }
                    .disabled(isRetrying)

                    if let onBack = onBack {
                        Button(action: onBack) {
                            Text("뒤로가기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray600)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.gray100)
                                .cornerRadius(12)
                        }
                        .disabled(isRetrying)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 32)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
        }
    }
}
