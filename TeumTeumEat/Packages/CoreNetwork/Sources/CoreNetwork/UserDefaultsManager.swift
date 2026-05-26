//
//  UserDefaultsManager.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

public enum UserDefaultsManager {
    private static let isOnboardingCompletedKey = "isOnboardingCompleted"

    public static var isOnboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: isOnboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: isOnboardingCompletedKey) }
    }
    
    public static func clearAll() {
        UserDefaults.standard.removeObject(forKey: isOnboardingCompletedKey)
    }
}
