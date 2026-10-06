//
//  UserDefaultsManager.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

public enum UserDefaultsManager {
    private static let isOnboardingCompletedKey = "isOnboardingCompleted"
    private static let leagueLastSeenResultWeekKey = "leagueLastSeenResultWeek"

    public static var isOnboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: isOnboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: isOnboardingCompletedKey) }
    }
    
    /// 마지막으로 결과 모달을 보여준 리그 주차 (LeagueWeekResult.weekStartDate)
    public static var leagueLastSeenResultWeek: String? {
        get { UserDefaults.standard.string(forKey: leagueLastSeenResultWeekKey) }
        set { UserDefaults.standard.set(newValue, forKey: leagueLastSeenResultWeekKey) }
    }

    public static func clearAll() {
        UserDefaults.standard.removeObject(forKey: isOnboardingCompletedKey)
        UserDefaults.standard.removeObject(forKey: leagueLastSeenResultWeekKey)
    }
}
