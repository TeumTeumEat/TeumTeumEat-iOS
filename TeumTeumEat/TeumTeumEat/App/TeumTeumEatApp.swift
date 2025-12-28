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

@main
struct TeumTeumEatApp: App {

    init() {
        let APPKEY = Config.kakaoNativeAppKey
        KakaoSDK.initSDK(appKey: APPKEY)
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()){
                    AppFeature()
                }
            )
            .onOpenURL(perform:{ url in
                if(AuthApi.isKakaoTalkLoginUrl(url)){
                    _ = AuthController.handleOpenUrl(url:url)
                }
            })
        }
    }
}
