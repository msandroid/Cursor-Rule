//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import Security

// MARK: - Secure Tier Data Manager
class SecureTierDataManager {
    static let shared = SecureTierDataManager()
    
    private let service = "com.cription.tiersystem"
    private let historicalSpendKey = "historicalSpend"
    private let firstPaymentDateKey = "firstPaymentDate"
    
    private init() {}
    
    // MARK: - Historical Spend Management
    func saveHistoricalSpend(_ amount: Double) -> Bool {
        let data = String(amount).data(using: .utf8)!
        return saveToKeychain(data: data, key: historicalSpendKey)
    }
    
    func loadHistoricalSpend() -> Double {
        guard let data = loadFromKeychain(key: historicalSpendKey),
              let string = String(data: data, encoding: .utf8),
              let amount = Double(string) else {
            return 0.0
        }
        return amount
    }
    
    // MARK: - First Payment Date Management
    func saveFirstPaymentDate(_ date: Date) -> Bool {
        let data = try! JSONEncoder().encode(date)
        return saveToKeychain(data: data, key: firstPaymentDateKey)
    }
    
    func loadFirstPaymentDate() -> Date? {
        guard let data = loadFromKeychain(key: firstPaymentDateKey) else {
            return nil
        }
        return try? JSONDecoder().decode(Date.self, from: data)
    }
    
    // MARK: - Keychain Operations
    private func saveToKeychain(data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 既存のアイテムを削除
        SecItemDelete(query as CFDictionary)
        
        // 新しいアイテムを追加
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    // MARK: - Data Validation
    func validateHistoricalSpend(_ amount: Double) -> Bool {
        return amount >= 0 && amount <= 1000000.0 && amount.isFinite
    }
    
    func validateFirstPaymentDate(_ date: Date) -> Bool {
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        
        return date >= oneYearAgo && date <= oneYearFromNow
    }
    
    // MARK: - Data Integrity Check
    func verifyDataIntegrity() -> Bool {
        let historicalSpend = loadHistoricalSpend()
        let firstPaymentDate = loadFirstPaymentDate()
        
        // 履歴支出の妥当性チェック
        guard validateHistoricalSpend(historicalSpend) else {
            print("❌ Historical spend validation failed: \(historicalSpend)")
            return false
        }
        
        // 初回支払い日の妥当性チェック
        if let date = firstPaymentDate {
            guard validateFirstPaymentDate(date) else {
                print("❌ First payment date validation failed: \(date)")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Data Recovery
    func recoverData() -> (historicalSpend: Double, firstPaymentDate: Date?) {
        // データの整合性をチェック
        if verifyDataIntegrity() {
            return (loadHistoricalSpend(), loadFirstPaymentDate())
        }
        
        // データが破損している場合は、デフォルト値を返す
        print("⚠️ Data integrity check failed, returning default values")
        return (0.0, nil)
    }
}
