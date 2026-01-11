//
//  TeumTeumEatApp.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/4/25.
//

import ComposableArchitecture
import SwiftUI
import KakaoSDKAuth
import KakaoSDKCommon
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
struct TeumTeumEatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        let APPKEY = Config.kakaoNativeAppKey
        KakaoSDK.initSDK(appKey: APPKEY)
        let accessToken = KeyChainManager.shared.getAccessToken()
        print(accessToken)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                } withDependencies: {
                    $0.categoryAPIClient = .liveValue
                }
            )
            .onOpenURL(perform: { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            })
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // Messaging delegate 설정
        Messaging.messaging().delegate = self
        
        // UNUserNotificationCenter delegate 설정
        UNUserNotificationCenter.current().delegate = self
        
        // Remote Notification 등록
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - MessagingDelegate
    
    // FCM 토큰 갱신 시
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "nil")")
        
        // 서버로 FCM 토큰 전송
        if let token = fcmToken {
            Task {
                do {
                    let apiClient = APIClient.liveValue
                    
                    try await apiClient.registerDeviceToken(
                        token: token,
                        deviceType: "IOS"
                    )
                    
                    print("FCM 토큰 서버 전송 완료")
                    
                } catch {
                    print("FCM 토큰 서버 전송 실패: \(error)")
                }
            }
        }
    }
    
    // MARK: - Remote Notification (APNs) 토큰 등록 성공
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token: \(token)")
        
        // APNs 토큰을 Messaging에 전달
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: - Remote Notification 등록 실패
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 등록 실패: \(error.localizedDescription)")
    }
    
    // MARK: - 포그라운드에서 알림 받을 때 (앱 실행 중)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("포그라운드 알림 수신: \(notification.request.content.body)")
        
        let userInfo = notification.request.content.userInfo
        
        // FCM 데이터 출력
        if let messageID = userInfo["gcm.message_id"] {
            print("FCM Message ID: \(messageID)")
        }
        
        // 앱 실행 중에도 알림 표시
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - 알림 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("알림 탭: \(response.notification.request.content.body)")
        
        let userInfo = response.notification.request.content.userInfo
        
        // FCM 데이터 처리
        if let messageID = userInfo["gcm.message_id"] {
            print("FCM Message ID: \(messageID)")
        }
        
        // TODO: 딥링크 처리 등
        
        completionHandler()
    }
}
