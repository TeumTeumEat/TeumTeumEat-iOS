//
//  AdTestView.swift
//  TeumTeumEat
//
//  광고 연동 확인용 임시 테스트 뷰

import SwiftUI
import GoogleMobileAds

struct AdTestView: View {
    @State private var rewardedAd: RewardedAd?
    @State private var statusMessage = "광고 로드 전"
    @State private var isLoading = false

    private let testAdUnitID = Config.admobRewardedAdUnitID

    var body: some View {
        VStack(spacing: 32) {
            Text("AdMob 테스트")
                .font(.title.bold())

            VStack(spacing: 8) {
                Circle()
                    .fill(rewardedAd != nil ? Color.green : (isLoading ? Color.orange : Color.red))
                    .frame(width: 16, height: 16)

                Text(statusMessage)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
            }
            .padding(.horizontal)

            Button {
                loadAd()
            } label: {
                Text(isLoading ? "로딩 중..." : "광고 로드")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button {
                showAd()
            } label: {
                Text("광고 보기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(rewardedAd == nil)

            Spacer()
        }
        .padding(24)
        .onAppear {
            loadAd()
        }
    }

    private func loadAd() {
        isLoading = true
        rewardedAd = nil
        statusMessage = "로딩 중..."

        Task {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: testAdUnitID,
                    request: Request()
                )
                statusMessage = "광고 준비 완료! '광고 보기' 버튼을 눌러보세요."
                isLoading = false
            } catch {
                statusMessage = "로드 실패: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func showAd() {
        guard let ad = rewardedAd else { return }
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController

        guard let topVC = topViewController(from: rootVC) else {
            statusMessage = "ViewController를 찾을 수 없습니다"
            return
        }

        ad.present(from: topVC) {
            statusMessage = "보상 획득! 다시 로드 중..."
            rewardedAd = nil
            loadAd()
        }
    }

    // 현재 가장 위에 있는 ViewController 반환
    private func topViewController(from base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(from: presented)
        }
        return base
    }
}
