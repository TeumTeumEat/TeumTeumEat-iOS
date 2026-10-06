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
    private var interruptedHandler: (() -> Void)?
    // 광고 표시가 끝났을 때(정상 종료 / 조기 종료 / 표시 실패 / 표시 불가) 호출
    private var finishedHandler: (() -> Void)?

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
                Log.ad.error("Rewarded ad load failed: \(error)")
                isAdReady = false
            }
        }
    }

    func showAd(
        onRewarded: @escaping () -> Void,
        onInterrupted: @escaping () -> Void,
        onFinished: @escaping () -> Void
    ) {
        guard !isAdShowing else {
            Log.ad.debug("Ad is already showing")
            onFinished()
            return
        }
        guard let ad = rewardedAd else {
            Log.ad.debug("Ad not ready")
            onFinished()
            return
        }
        guard let topVC = UIApplication.shared.topViewController() else {
            Log.ad.debug("topViewController를 찾을 수 없습니다")
            onFinished()
            return
        }

        // 상태 초기화
        rewardEarned = false
        didClickOutToAppStore = false
        pendingRewardHandler = onRewarded
        interruptedHandler = onInterrupted
        finishedHandler = onFinished
        isAdShowing = true

        ad.fullScreenContentDelegate = self

        ad.present(from: topVC) { [weak self] in
            self?.rewardEarned = true
            onRewarded()
        }

        rewardedAd = nil
        isAdReady = false
    }

    private func resetHandlers() {
        pendingRewardHandler = nil
        interruptedHandler = nil
        finishedHandler = nil
        rewardEarned = false
        didClickOutToAppStore = false
    }
}

// MARK: - FullScreenContentDelegate
extension RewardedAdManager: FullScreenContentDelegate {

    // 광고가 클릭됨 (앱스토어 등 외부 링크 이동)
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        didClickOutToAppStore = true
        Log.ad.debug("[AdManager] 광고 클릭 감지 (앱스토어 이동 가능성)")
    }

    // 광고가 완전히 종료됨
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        isAdShowing = false

        if rewardEarned {
            // 정상 완료 - 보상은 ad.present 콜백에서 이미 지급됨
            Log.ad.debug("[AdManager] 광고 정상 완료")
        } else if didClickOutToAppStore {
            // AdMob iOS 버그: 앱스토어 바텀시트(SKStoreProductViewController) 닫힐 때
            // adDidDismissFullScreenContent가 잘못 호출됨.
            // 유저가 의도적으로 광고를 종료한 게 아니므로 보상 지급.
            Log.ad.debug("[AdManager] 앱스토어 클릭 후 시트 닫힘으로 광고 종료 - 보상 지급")
            pendingRewardHandler?()
        } else {
            Log.ad.debug("[AdManager] 광고 시청 미완료로 보상 미지급")
            interruptedHandler?()
        }

        finishedHandler?()
        resetHandlers()
        loadAd()
    }

    // 광고 표시 실패
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isAdShowing = false
        Log.ad.error("[AdManager] 광고 표시 실패: \(error)")
        finishedHandler?()
        resetHandlers()
        loadAd()
    }
}
