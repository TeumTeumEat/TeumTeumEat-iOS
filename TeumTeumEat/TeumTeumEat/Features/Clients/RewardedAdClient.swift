//
//  RewardedAdClient.swift
//  TeumTeumEat
//

import ComposableArchitecture

/// 보상형 광고 시청 중 발생하는 이벤트
enum RewardedAdEvent: Equatable, Sendable {
    /// 보상 지급 조건 충족 (광고 시청 완료 등)
    case rewarded
    /// 광고 시청을 끝내지 않고 닫음 (보상 미지급)
    case interrupted
}

/// AdMob 보상형 광고 (RewardedAdManager 래핑)
@DependencyClient
struct RewardedAdClient {
    /// 다음에 보여줄 광고를 미리 불러옴
    var load: @Sendable () async -> Void
    /// 광고를 표시하고, 광고가 닫히거나 표시할 수 없으면 스트림이 끝남
    var show: @Sendable () -> AsyncStream<RewardedAdEvent> = { .finished }
}

extension RewardedAdClient: DependencyKey {
    static let liveValue = RewardedAdClient(
        load: {
            await RewardedAdManager.shared.loadAd()
        },
        show: {
            AsyncStream { continuation in
                Task { @MainActor in
                    RewardedAdManager.shared.showAd(
                        onRewarded: { continuation.yield(.rewarded) },
                        onInterrupted: { continuation.yield(.interrupted) },
                        onFinished: { continuation.finish() }
                    )
                }
            }
        }
    )

    // 광고 미리 불러오기는 화면 진입마다 호출되므로 테스트에서는 무시, 광고 표시는 override 필요
    static let testValue: RewardedAdClient = {
        var client = RewardedAdClient()
        client.load = {}
        return client
    }()
}

extension DependencyValues {
    var rewardedAdClient: RewardedAdClient {
        get { self[RewardedAdClient.self] }
        set { self[RewardedAdClient.self] = newValue }
    }
}
