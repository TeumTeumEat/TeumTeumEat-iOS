//
//  UserDefaultsManager.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/28/25.
//

import Foundation

enum UserDefaultsManager {
    private static let isOnboardingCompletedKey = "isOnboardingCompleted"
    
    static var isOnboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: isOnboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: isOnboardingCompletedKey) }
    }
    
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: isOnboardingCompletedKey)
    }
}
