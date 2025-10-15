//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import IOKit
#endif

// MARK: - Secure Keychain Manager
class SecureKeychainManager {
    static let shared = SecureKeychainManager()
    
    private let service = "com.Cription.openai"
    private let account = "api_key"
    private let fireworksService = "com.Cription.fireworks"
    private let fireworksAccount = "fireworks_api_key"
    private let welcomeCreditsService = "com.Cription.credits"
    private let welcomeCreditsAccount = "welcome_credits_given"
    
    private init() {}
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        // 既存のキーを削除
        deleteAPIKey()
        
        guard let data = apiKey.data(using: .utf8) else {
            print("❌ Failed to convert API key to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ API key saved securely to Keychain")
            return true
        } else {
            print("❌ Failed to save API key to Keychain: \(status)")
            return false
        }
    }
    
    func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            print("✅ API key loaded from Keychain")
            return apiKey
        } else {
            print("❌ Failed to load API key from Keychain: \(status)")
            return nil
        }
    }
    
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ API key deleted from Keychain")
        } else if status == errSecItemNotFound {
            print("ℹ️ No API key found in Keychain to delete")
        } else {
            print("❌ Failed to delete API key from Keychain: \(status)")
        }
    }
    
    func hasAPIKey() -> Bool {
        return loadAPIKey() != nil
    }
    
    // MARK: - Fireworks API Key Management
    
    func saveFireworksAPIKey(_ apiKey: String) -> Bool {
        // 既存のキーを削除
        deleteFireworksAPIKey()
        
        guard let data = apiKey.data(using: .utf8) else {
            print("❌ Failed to convert Fireworks API key to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: fireworksService,
            kSecAttrAccount as String: fireworksAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Fireworks API key saved securely to Keychain")
            return true
        } else {
            print("❌ Failed to save Fireworks API key to Keychain: \(status)")
            return false
        }
    }
    
    func loadFireworksAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: fireworksService,
            kSecAttrAccount as String: fireworksAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let apiKey = String(data: data, encoding: .utf8) {
            print("✅ Fireworks API key loaded from Keychain")
            return apiKey
        } else {
            print("❌ Failed to load Fireworks API key from Keychain: \(status)")
            return nil
        }
    }
    
    func deleteFireworksAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: fireworksService,
            kSecAttrAccount as String: fireworksAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ Fireworks API key deleted from Keychain")
        } else if status == errSecItemNotFound {
            print("ℹ️ No Fireworks API key found in Keychain to delete")
        } else {
            print("❌ Failed to delete Fireworks API key from Keychain: \(status)")
        }
    }
    
    func hasFireworksAPIKey() -> Bool {
        return loadFireworksAPIKey() != nil
    }
    
    func validateFireworksAPIKey(_ apiKey: String) -> Bool {
        // Fireworks APIキーの基本的な形式をチェック
        return apiKey.hasPrefix("fw_") && apiKey.count > 20
    }
    
    // MARK: - Migration from Config.xcconfig
    
    func migrateFromConfig() {
        print("🔍 Attempting to load API key from Config.xcconfig...")
        
        // Config.xcconfigからAPIキーを取得
        if let configAPIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !configAPIKey.isEmpty {
            
            print("✅ API key found in Config.xcconfig: \(String(configAPIKey.prefix(10)))...")
            
            // Keychainに保存
            if saveAPIKey(configAPIKey) {
                print("✅ API key loaded from Config.xcconfig and saved to Keychain")
            } else {
                print("❌ Failed to save API key from Config.xcconfig to Keychain")
            }
        } else {
            print("❌ No API key found in Config.xcconfig")
            print("🔍 Available Info.plist keys: \(Bundle.main.infoDictionary?.keys.sorted() ?? [])")
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults() {
        // UserDefaultsからAPIキーを取得
        if let oldAPIKey = UserDefaults.standard.string(forKey: "openai_api_key"),
           !oldAPIKey.isEmpty {
            
            // Keychainに保存
            if saveAPIKey(oldAPIKey) {
                // UserDefaultsから削除
                UserDefaults.standard.removeObject(forKey: "openai_api_key")
                UserDefaults.standard.synchronize()
                print("✅ API key migrated from UserDefaults to Keychain")
            } else {
                print("❌ Failed to migrate API key to Keychain")
            }
        }
    }
    
    // MARK: - Validation
    
    func validateAPIKey(_ apiKey: String) -> Bool {
        // OpenAI APIキーの基本的な形式をチェック
        return apiKey.hasPrefix("sk-") && apiKey.count > 20
    }
    
    // MARK: - Welcome Credits Management
    
    func saveWelcomeCreditsGiven(deviceID: String, timestamp: Date) -> Bool {
        let data = "\(deviceID)|\(timestamp.timeIntervalSince1970)".data(using: .utf8)
        
        guard let creditsData = data else {
            print("❌ Failed to convert welcome credits data")
            return false
        }
        
        // 既存のエントリを削除
        deleteWelcomeCreditsFlag()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: welcomeCreditsService,
            kSecAttrAccount as String: welcomeCreditsAccount,
            kSecValueData as String: creditsData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Welcome credits flag saved to Keychain")
            return true
        } else {
            print("❌ Failed to save welcome credits flag: \(status)")
            return false
        }
    }
    
    func hasReceivedWelcomeCredits() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: welcomeCreditsService,
            kSecAttrAccount as String: welcomeCreditsAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let dataString = String(data: data, encoding: .utf8) {
                let components = dataString.split(separator: "|")
                if components.count == 2 {
                    let deviceID = String(components[0])
                    let timestamp = Double(components[1]) ?? 0
                    print("✅ Welcome credits already given - Device: \(deviceID.prefix(8))..., Date: \(Date(timeIntervalSince1970: timestamp))")
                }
            }
            return true
        } else if status == errSecItemNotFound {
            print("ℹ️ No welcome credits flag found in Keychain")
            return false
        } else {
            print("❌ Failed to check welcome credits flag: \(status)")
            return false
        }
    }
    
    private func deleteWelcomeCreditsFlag() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: welcomeCreditsService,
            kSecAttrAccount as String: welcomeCreditsAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Device ID
    
    func getDeviceIdentifier() -> String {
        #if canImport(UIKit)
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #elseif canImport(AppKit)
        // macOSの場合はシリアル番号を使用
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }
        
        guard platformExpert != 0 else { return "unknown" }
        
        if let serialNumber = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return serialNumber
        }
        return "unknown"
        #else
        return "unknown"
        #endif
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateWelcomeCreditsFlag() {
        let hasReceivedInUserDefaults = UserDefaults.standard.bool(forKey: "WelcomeCreditsGiven")
        
        if hasReceivedInUserDefaults && !hasReceivedWelcomeCredits() {
            let deviceID = getDeviceIdentifier()
            let timestamp = Date()
            
            if saveWelcomeCreditsGiven(deviceID: deviceID, timestamp: timestamp) {
                print("✅ Welcome credits flag migrated from UserDefaults to Keychain")
            } else {
                print("❌ Failed to migrate welcome credits flag to Keychain")
            }
        }
    }
}