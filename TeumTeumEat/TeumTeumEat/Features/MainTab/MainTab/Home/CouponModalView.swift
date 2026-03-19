//
//  CouponModalView.swift
//  TeumTeumEat
//

import SwiftUI

struct CouponModalView: View {
    let couponCount: Int
    let maxCouponCount: Int = 10
    let onUse: () -> Void
    let onCharge: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - 타이틀
            VStack(spacing: 6) {
                Text("30초 후 퀴즈 풀기")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text("사용 가능 쿠폰 \(couponCount)/\(maxCouponCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // MARK: - 안내 카드
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "ticket.fill")
                    .foregroundColor(.blue500)
                    .font(.system(size: 18))
                    .padding(.top, 1)

                (
                    Text("퀴즈 쿠폰")
                        .foregroundColor(.blue500)
                        .fontWeight(.semibold) +
                    Text("으로 하루 한번만 가능했던\n틈틈잇 퀴즈를 추가로 풀 수 있어요!")
                        .foregroundColor(.black)
                )
                .font(.system(size: 13))
                .lineSpacing(3)
            }
            .padding(14)
            .background(Color.gray300.opacity(0.3))
            .cornerRadius(10)
            .padding(.horizontal, 20)

            // MARK: - 안내 문구
            VStack(alignment: .leading, spacing: 10) {
                bulletRow("다른 퀴즈를 더 풀 수 있는 쿠폰입니다.")
                bulletRow("하루 최대 10번 사용 가능해요.")
                bulletRow("광고로 받은 쿠폰은 당일까지만 사용가능")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)

            // MARK: - 버튼
            HStack(spacing: 12) {
                Button(action: onUse) {
                    Text("쿠폰 사용")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(couponCount > 0 ? .gray600 : Color.gray300)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray300.opacity(0.4))
                        .cornerRadius(10)
                }
                .disabled(couponCount == 0)

                Button(action: onCharge) {
                    Text("쿠폰 충전")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue500)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
        .padding(.horizontal, 24)
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 13))
                .foregroundColor(.gray600)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.gray600)
                .lineSpacing(2)
        }
    }
}
