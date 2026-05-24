//
//  KeyChainManager.swift
//  TeumTeumEat
//
//  Created by 임재현 on 12/27/25.
//

import Foundation
import Security

final class KeyChainManager {
    static let shared = KeyChainManager()
    private init() {}
    
    private let service = "com.teumtuemeat.app"
    
    enum KeyChainKey: String {
        case accessToken
        case refreshToken
    }
    
    func save(_ value: String, for key: KeyChainKey) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeyChain Save Success: \(key.rawValue)")
        } else {
            print("KeyChain Save Failed: \(status)")
        }
    }
    
    func get(for key: KeyChainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            print("KeyChain Get Success: \(key.rawValue)")
            return value
        } else {
            print("KeyChain Get Failed: \(status)")
            return nil
        }
    }
    
    func delete(for key: KeyChainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("KeyChain Delete Success: \(key.rawValue)")
        } else {
            print("KeyChain Delete Failed: \(status)")
        }
    }
    
    func deleteAll() {
        delete(for: .accessToken)
        delete(for: .refreshToken)
        print("KeyChain All Deleted")
    }
}

extension KeyChainManager {
    func saveAccessToken(_ token: String) {
        save(token, for: .accessToken)
    }
    
    func getAccessToken() -> String? {
        get(for: .accessToken)
    }
    
    func saveRefreshToken(_ token: String) {
        save(token, for: .refreshToken)
    }
    
    func getRefreshToken() -> String? {
        get(for: .refreshToken)
    }
}
