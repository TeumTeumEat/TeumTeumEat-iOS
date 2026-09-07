//
//  RewardedAdManager.swift
//  TeumTeumEat
//

import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: NSObject, ObservableObject {
    static let shared = RewardedAdManager()

    private var rewardedAd: RewardedAd?
    @Published var isAdReady: Bool = false
    @Published var isAdShowing: Bool = false

    // 광고 보상 및 클릭 추적
    private var pendingRewardHandler: (() -> Void)?
    private var rewardEarned: Bool = false
    private var didClickOutToAppStore: Bool = false

    // 광고 조기 종료 시 유저에게 안내할 콜백
    var onAdInterrupted: (() -> Void)?

    private override init() {}

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
        guard !isAdShowing else {
            print("Ad is already showing")
            return
        }
        guard let ad = rewardedAd else {
            print("Ad not ready")
            return
        }
        guard let topVC = topViewController() else {
            print("topViewController를 찾을 수 없습니다")
            return
        }

        // 상태 초기화
        rewardEarned = false
        didClickOutToAppStore = false
        pendingRewardHandler = onRewarded
        isAdShowing = true

        ad.fullScreenContentDelegate = self

        ad.present(from: topVC) { [weak self] in
            self?.rewardEarned = true
            onRewarded()
        }

        rewardedAd = nil
        isAdReady = false
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

// MARK: - FullScreenContentDelegate
extension RewardedAdManager: FullScreenContentDelegate {

    // 광고가 클릭됨 (앱스토어 등 외부 링크 이동)
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        didClickOutToAppStore = true
        print("[AdManager] 광고 클릭 감지 (앱스토어 이동 가능성)")
    }

    // 광고가 완전히 종료됨
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isAdShowing = false

        if rewardEarned {
            // 정상 완료 - 보상은 ad.present 콜백에서 이미 지급됨
            print("[AdManager] 광고 정상 완료")
        } else if didClickOutToAppStore {
            // AdMob iOS 버그: 앱스토어 바텀시트(SKStoreProductViewController) 닫힐 때
            // adDidDismissFullScreenContent가 잘못 호출됨.
            // 유저가 의도적으로 광고를 종료한 게 아니므로 보상 지급.
            print("[AdManager] 앱스토어 클릭 후 시트 닫힘으로 광고 종료 - 보상 지급")
            pendingRewardHandler?()
        } else {
            print("[AdManager] 광고 시청 미완료로 보상 미지급")
            onAdInterrupted?()
        }

        pendingRewardHandler = nil
        rewardEarned = false
        didClickOutToAppStore = false

        loadAd()
    }

    // 광고 표시 실패
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isAdShowing = false
        pendingRewardHandler = nil
        rewardEarned = false
        didClickOutToAppStore = false
        print("[AdManager] 광고 표시 실패: \(error)")
        loadAd()
    }
}
