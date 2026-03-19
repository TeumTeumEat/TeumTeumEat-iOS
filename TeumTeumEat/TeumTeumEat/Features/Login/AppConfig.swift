//
//  AppConfig.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

protocol ConfigProtocol {
    var kakaoAppKey: String { get }
    var apiBaseURL: String { get }
}

enum Config  {

    static var kakaoNativeAppKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APPKEY") as? String else {
            fatalError("KAKAO_NATIVE_APPKEY not found")
        }
        return key
    }
    
    static var kakaoAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String else {
            fatalError("KAKAO_APP_KEY not found")
        }
        return key
    }
    
    static var baseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("API_BASE_URL not found")
        }
        return url
    }

    static var admobAppID: String {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String else {
            fatalError("GADApplicationIdentifier not found")
        }
        return id
    }

    static var admobRewardedAdUnitID: String {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "ADMOB_REWARDED_AD_UNIT_ID") as? String else {
            fatalError("ADMOB_REWARDED_AD_UNIT_ID not found")
        }
        return id
    }
}
