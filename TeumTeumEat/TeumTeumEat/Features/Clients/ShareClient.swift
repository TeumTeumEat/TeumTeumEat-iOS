//
//  ShareClient.swift
//  TeumTeumEat
//

import ComposableArchitecture
import KakaoSDKShare
import KakaoSDKTemplate
import UIKit

/// 공유 채널
enum ShareChannel: String, Equatable, Sendable {
    /// 카카오톡 (카카오 SDK 메시지)
    case kakao
    /// iOS 기본 공유 시트
    case system
}

/// 공유할 내용 (앱 초대 링크 + 문구)
struct ShareContent: Equatable, Sendable {
    let text: String
    let url: URL

    // TODO: 설치 여부 / OS별로 분기하는 초대 링크(리다이렉트 URL) 나오면 교체
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6757255726")!

    /// 앱 초대
    static let invite = ShareContent(
        text: "틈틈이 퀴즈 풀고 주간 리그 1등에 도전해 보세요!",
        url: appStoreURL
    )
}

enum ShareError: Error {
    case kakaoUnavailable
}

/// 카카오톡 / iOS 기본 공유
@DependencyClient
struct ShareClient {
    var shareToKakao: @Sendable (_ content: ShareContent) async throws -> Void
    var shareToSystem: @Sendable (_ content: ShareContent) async -> Void
}

extension ShareClient: DependencyKey {
    static let liveValue = ShareClient(
        shareToKakao: { content in
            try await shareToKakaoTalk(content)
        },
        shareToSystem: { content in
            await MainActor.run {
                guard let topVC = UIApplication.shared.topViewController() else {
                    Log.app.error("공유 시트를 띄울 화면을 찾지 못함")
                    return
                }
                let activityVC = UIActivityViewController(
                    activityItems: [content.text, content.url],
                    applicationActivities: nil
                )
                topVC.present(activityVC, animated: true)
            }
        }
    )

    // 테스트에서 override하지 않은 공유가 호출되면 테스트 실패
    static let testValue = ShareClient()
}

private extension ShareClient {
    // TODO: 카카오 디벨로퍼스 메시지 템플릿 ID 받으면 shareCustom으로 교체 (현재는 이미지 없는 텍스트 템플릿)
    /// 메시지의 "앱에서 보기"를 누르면 앱이 있으면 앱 실행, 없으면 콘솔에 등록한 스토어로 이동
    @MainActor
    static func shareToKakaoTalk(_ content: ShareContent) async throws {
        let template = TextTemplate(
            text: content.text,
            link: Link(
                webUrl: content.url,
                mobileWebUrl: content.url,
                androidExecutionParams: ["from": "share"],
                iosExecutionParams: ["from": "share"]
            ),
            buttonTitle: "앱에서 보기"
        )

        guard ShareApi.isKakaoTalkSharingAvailable() else {
            // 카카오톡 미설치: 웹 공유 페이지로 이동
            guard let url = ShareApi.shared.makeDefaultUrl(templatable: template) else {
                throw ShareError.kakaoUnavailable
            }
            await UIApplication.shared.open(url)
            return
        }

        let sharingURL: URL = try await withCheckedThrowingContinuation { continuation in
            ShareApi.shared.shareDefault(templatable: template) { result, error in
                if let result {
                    continuation.resume(returning: result.url)
                } else {
                    continuation.resume(throwing: error ?? ShareError.kakaoUnavailable)
                }
            }
        }
        await UIApplication.shared.open(sharingURL)
    }
}

extension DependencyValues {
    var shareClient: ShareClient {
        get { self[ShareClient.self] }
        set { self[ShareClient.self] = newValue }
    }
}
