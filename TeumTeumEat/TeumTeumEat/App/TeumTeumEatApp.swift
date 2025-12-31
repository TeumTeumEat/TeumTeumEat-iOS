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

@main
struct TeumTeumEatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        let APPKEY = Config.kakaoNativeAppKey
        KakaoSDK.initSDK(appKey: APPKEY)
        KeyChainManager.shared.deleteAll()
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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // UNUserNotificationCenter delegate 설정
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - Remote Notification (APNs) 토큰 등록 성공
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Token: \(token)")
        
        // TODO: FCM 설정 시
        // Messaging.messaging().apnsToken = deviceToken
        
        // TODO: 서버로 토큰 전송
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
        
        // 앱 실행 중에도 알림 표시
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - 알림 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("알림 탭: \(response.notification.request.content.body)")
        
        // TODO: 딥링크 처리 등
        
        completionHandler()
    }
}
