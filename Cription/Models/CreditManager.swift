//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit

// MARK: - Credit Manager

@MainActor
class CreditManager: ObservableObject {
    static let shared = CreditManager()
    
    @Published var currentCredits: Double = 0.0
    @Published var creditTransactions: [CreditTransaction] = []
    @Published var isLoading = false
    @Published var error: CreditError?
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "CurrentCredits"
    private let transactionsKey = "CreditTransactions"
    private let welcomeCreditsGivenKey = "WelcomeCreditsGiven"
    
    // クレジット購入用のプロダクトID
    private let creditProductIDs: Set<String> = [
        "Cription.credits.22",    // $19.99 = 22 credits
        "Cription.credits.55",    // $49.99 = 55 credits
        "Cription.credits.110",   // $99.99 = 110 credits
        "Cription.credits.220",   // $199.99 = 220 credits
        "Cription.credits.1100"   // $999.99 = 1100 credits
    ]
    
    private init() {
        loadCredits()
        loadTransactions()
        giveWelcomeCreditsIfNeeded()
    }
    
    // MARK: - Credit Management
    
    func addCredits(_ amount: Double, source: CreditSource, description: String = "") {
        currentCredits += amount
        
        let transaction = CreditTransaction(
            id: UUID().uuidString,
            amount: amount,
            type: .credit,
            source: source,
            description: description,
            timestamp: Date()
        )
        
        creditTransactions.append(transaction)
        saveCredits()
        saveTransactions()
        
        // 履歴支出の追跡（将来のSpendingLimitsManager統合用）
        // SpendingLimitsManager.shared.purchaseCredits(amount)
        
        print("💰 Added \(amount) credits. Total: \(currentCredits)")
    }
    
    func consumeCredits(_ amount: Double, description: String = "") -> Bool {
        guard currentCredits >= amount else {
            error = .insufficientCredits
            return false
        }
        
        currentCredits -= amount
        
        let transaction = CreditTransaction(
            id: UUID().uuidString,
            amount: -amount,
            type: .debit,
            source: .apiUsage,
            description: description,
            timestamp: Date()
        )
        
        creditTransactions.append(transaction)
        saveCredits()
        saveTransactions()
        
        // 月次支出の追跡（将来のSpendingLimitsManager統合用）
        // SpendingLimitsManager.shared.addSpending(amount)
        
        print("💸 Consumed \(amount) credits. Remaining: \(currentCredits)")
        return true
    }
    
    func canAfford(_ amount: Double) -> Bool {
        // クレジット残高をチェック
        let hasEnoughCredits = currentCredits >= amount
        
        // 将来のSpending Limits統合用
        // let withinSpendingLimit = SpendingLimitsManager.shared.canSpend(amount)
        // return hasEnoughCredits && withinSpendingLimit
        
        return hasEnoughCredits
    }
    
    // MARK: - Credit Purchase
    
    func purchaseCredits(productID: String) async throws {
        guard let product = await getProduct(for: productID) else {
            throw CreditError.productNotFound
        }
        
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                guard let transaction = await unwrapVerificationResult(verification) else {
                    throw CreditError.purchaseFailed("Transaction verification failed")
                }
                
                let creditAmount = getCreditAmount(for: productID)
                addCredits(creditAmount, source: .purchase, description: "Purchased \(product.displayName)")
                await transaction.finish()
            case .userCancelled:
                throw CreditError.userCancelled
            case .pending:
                // Handle pending state
                break
            @unknown default:
                throw CreditError.unknown
            }
        } catch {
            self.error = .purchaseFailed(error.localizedDescription)
            throw error
        }
        
        isLoading = false
    }
    
    private func getProduct(for productID: String) async -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            return products.first
        } catch {
            print("Failed to load product: \(error)")
            return nil
        }
    }
    
    private func unwrapVerificationResult(_ verificationResult: VerificationResult<StoreKit.Transaction>) async -> StoreKit.Transaction? {
        switch verificationResult {
        case .verified(let transaction):
            return transaction
        case .unverified(let transaction, let error):
            print("Transaction verification failed: \(error)")
            return nil
        }
    }
    
    private func getCreditAmount(for productID: String) -> Double {
        switch productID {
        case "Cription.credits.22":
            return 15.0  // $19.99 = 15 credits (1 credit = $1.33)
        case "Cription.credits.55":
            return 38.0  // $49.99 = 38 credits (1 credit = $1.32)
        case "Cription.credits.110":
            return 77.0  // $99.99 = 77 credits (1 credit = $1.30)
        case "Cription.credits.220":
            return 154.0 // $199.99 = 154 credits (1 credit = $1.30)
        case "Cription.credits.1100":
            return 769.0 // $999.99 = 769 credits (1 credit = $1.30)
        default:
            return 0.0
        }
    }
    
    // MARK: - API Cost Calculation
    
    func calculateAPICost(duration: Double, model: String, isTranslation: Bool = false) -> Double {
        let baseCostPerMinute: Double
        
        switch model {
        case "whisper-1":
            baseCostPerMinute = 0.006 // High precision rate
        case "gpt-4o-transcribe":
            baseCostPerMinute = 0.006 // 公式価格: $0.006/分
        case "gpt-4o-mini-transcribe":
            baseCostPerMinute = 0.003 // 公式価格: $0.003/分 (最安モデル)
        case "gpt-4o-mini": // For text translation
            baseCostPerMinute = 0.000075 // Per 1K tokens, estimated
        default:
            baseCostPerMinute = 0.003 // デフォルトは最安モデル基準に変更
        }
        
        let minutes = duration / 60.0
        var cost = minutes * baseCostPerMinute
        
        // Add translation cost if applicable
        if isTranslation {
            cost += 0.001 // Additional cost for translation
        }
        
        return cost
    }
    
    /// モデル間のコスト比較を取得
    func getModelCostComparison(duration: Double, isTranslation: Bool = false) -> [String: Double] {
        let models = ["whisper-1", "gpt-4o-transcribe", "gpt-4o-mini-transcribe"]
        var costs: [String: Double] = [:]
        
        for model in models {
            costs[model] = calculateAPICost(duration: duration, model: model, isTranslation: isTranslation)
        }
        
        return costs
    }
    
    /// 推奨モデルを取得（コスト優先）
    func getRecommendedModel(duration: Double, requireHighAccuracy: Bool = false) -> String {
        if requireHighAccuracy {
            return "gpt-4o-transcribe"  // 高精度が必要な場合
        }
        return "gpt-4o-mini-transcribe"  // コスト優先（デフォルト）
    }
    
    // MARK: - Data Persistence
    
    private func loadCredits() {
        currentCredits = userDefaults.double(forKey: creditsKey)
    }
    
    private func saveCredits() {
        userDefaults.set(currentCredits, forKey: creditsKey)
    }
    
    private func loadTransactions() {
        if let data = userDefaults.data(forKey: transactionsKey),
           let transactions = try? JSONDecoder().decode([CreditTransaction].self, from: data) {
            creditTransactions = transactions
        }
    }
    
    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(creditTransactions) {
            userDefaults.set(data, forKey: transactionsKey)
        }
    }
    
    // MARK: - Welcome Credits
    
    private func giveWelcomeCreditsIfNeeded() {
        // UserDefaultsからKeychainへの移行処理
        SecureKeychainManager.shared.migrateWelcomeCreditsFlag()
        
        // Keychainでチェック（より堅牢）
        let hasReceivedWelcomeCredits = SecureKeychainManager.shared.hasReceivedWelcomeCredits()
        
        if !hasReceivedWelcomeCredits {
            // 30分相当のクレジットを付与
            // gpt-4o-mini-transcribe: $0.003/分 × 30分 = $0.09
            // gpt-4o-transcribe: $0.006/分 × 30分 = $0.18
            // より高価なモデルを基準に$0.18（約30分分）を付与
            let welcomeCreditAmount = 0.18
            
            addCredits(welcomeCreditAmount, source: .bonus, description: "Welcome bonus - 30 minutes of transcription")
            
            // Keychainにデバイス情報と日時を記録
            let deviceID = SecureKeychainManager.shared.getDeviceIdentifier()
            let timestamp = Date()
            
            if SecureKeychainManager.shared.saveWelcomeCreditsGiven(deviceID: deviceID, timestamp: timestamp) {
                print("🎉 Welcome credits given: \(welcomeCreditAmount) credits (30 minutes)")
                print("📱 Device ID: \(deviceID.prefix(8))...")
                print("📅 Timestamp: \(timestamp)")
                
                // UserDefaultsのフラグも更新（後方互換性）
                userDefaults.set(true, forKey: welcomeCreditsGivenKey)
                userDefaults.synchronize()
            } else {
                print("❌ Failed to save welcome credits flag to Keychain")
            }
        }
    }
    
    // MARK: - Credit History
    
    func getRecentTransactions(limit: Int = 10) -> [CreditTransaction] {
        return Array(creditTransactions.suffix(limit).reversed())
    }
    
    func getTransactionsForPeriod(days: Int) -> [CreditTransaction] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return creditTransactions.filter { $0.timestamp >= cutoffDate }
    }
}

// MARK: - Credit Transaction

struct CreditTransaction: Codable, Identifiable {
    let id: String
    let amount: Double
    let type: TransactionType
    let source: CreditSource
    let description: String
    let timestamp: Date
    
    enum TransactionType: String, Codable {
        case credit = "credit"
        case debit = "debit"
    }
}

// MARK: - Credit Source

enum CreditSource: String, Codable {
    case purchase = "purchase"
    case apiUsage = "api_usage"
    case bonus = "bonus"
    case refund = "refund"
}

// MARK: - Credit Error

enum CreditError: LocalizedError {
    case insufficientCredits
    case productNotFound
    case userCancelled
    case purchaseFailed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return "Insufficient credits. Please purchase more credits to continue."
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
