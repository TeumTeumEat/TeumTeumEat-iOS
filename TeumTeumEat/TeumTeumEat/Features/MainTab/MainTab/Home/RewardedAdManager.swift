//
//  RewardedAdManager.swift
//  TeumTeumEat
//

import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: ObservableObject {
    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?
    @Published var isAdReady: Bool = false

    private init() {}

    func loadAd() {
        Task {
            do {
                rewardedAd = try await RewardedAd.load(
                    with: Config.admobRewardedAdUnitID,
                    request: Request()
                )
                isAdReady = true
            } catch {
                print("Rewarded ad load failed: \(error)")
                isAdReady = false
            }
        }
    }

    func showAd(onRewarded: @escaping () -> Void) {
        guard let ad = rewardedAd else {
            print("Ad not ready")
            return
        }
        guard let topVC = topViewController() else {
            print("topViewController를 찾을 수 없습니다")
            return
        }

        ad.present(from: topVC) {
            onRewarded()
        }

        rewardedAd = nil
        isAdReady = false
        loadAd()
    }

    private func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}
