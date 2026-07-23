//
//  CouponModalView.swift
//  TeumTeumEat
//

import SwiftUI

struct CouponModalView: View {
    let couponCount: Int
    let maxCouponCount: Int = 10
    let canIssueCoupon: Bool
    let onUse: () -> Void
    let onCharge: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - 타이틀
            VStack(spacing: 6) {
                Text("광고 보고 퀴즈 더 풀기")
                    .font(.t_bold_20)
                    .foregroundColor(.black)

                Text("사용 가능 쿠폰 \(couponCount)/\(maxCouponCount)")
                    .font(.c_regular_14)
                    .foregroundColor(Color(hex: "#393C41"))
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // MARK: - 안내 카드
            HStack(alignment: .top, spacing: 12) {
                Image("coupon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.top, 6)

                (
                    Text("퀴즈 쿠폰")
                        .foregroundColor(.blue500) +
                    Text("으로 하루 한번만 가능했던\n틈틈잇 퀴즈를 추가로 풀 수 있어요!")
                        .foregroundColor(.black)
                )
                .font(Font.custom("Pretendard-Medium", size: 12))
                .lineSpacing(3)
            }
            .padding(14)
            .background(Color.gray300.opacity(0.3))
            .cornerRadius(10)
            .padding(.horizontal, 20)

            // MARK: - 안내 문구
            VStack(alignment: .leading, spacing: 6) {
                bulletRow("하루 최대 10번 사용할 수 있어요.")
                bulletRow("광고로 받은 쿠폰은 당일까지 사용할 수 있어요.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 28)

            // MARK: - 버튼
            HStack(spacing: 12) {
                Button(action: onUse) {
                    Text("쿠폰 사용")
                        .btMedium18_24()
                        .foregroundColor(couponCount > 0 ? Color(hex: "#2B8FFF") : Color(hex: "#787C82"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(couponCount > 0 ? Color(hex: "#EAF4FF") : Color(hex: "#E3E4E5"))
                        .cornerRadius(10)
                }
                .disabled(couponCount == 0)

                Button(action: onCharge) {
                    Text("쿠폰 충전하기")
                        .btMedium18_24()
                        .foregroundColor(canIssueCoupon ? .white : Color(hex: "#787C82"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canIssueCoupon ? Color(hex: "#2B8FFF") : Color(hex: "#E3E4E5"))
                        .cornerRadius(10)
                }
                .disabled(!canIssueCoupon)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 4)
        .padding(.horizontal, 36)
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.c_regular_12)
                .foregroundColor(Color(hex: "#787C82"))
            Text(text)
                .font(.c_regular_12)
                .foregroundColor(Color(hex: "#787C82"))
                .lineSpacing(2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
