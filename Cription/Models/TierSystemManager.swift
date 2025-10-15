//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit

// MARK: - Spending Tier
enum SpendingTier: String, CaseIterable, Identifiable {
    case tier1 = "Tier 1"
    case tier2 = "Tier 2"
    case tier3 = "Tier 3"
    case tier4 = "Tier 4"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var monthlyLimit: Double {
        switch self {
        case .tier1:
            return 50.0
        case .tier2:
            return 500.0
        case .tier3:
            return 5000.0
        case .tier4:
            return 50000.0
        case .custom:
            return 0.0 // カスタムは個別設定
        }
    }
    
    var requiredHistoricalSpend: Double {
        switch self {
        case .tier1:
            return 0.0 // デフォルト
        case .tier2:
            return 50.0
        case .tier3:
            return 500.0
        case .tier4:
            return 5000.0
        case .custom:
            return 0.0
        }
    }
    
    var requiredDaysSinceFirstPayment: Int {
        switch self {
        case .tier1:
            return 0 // 即座
        case .tier2:
            return 7
        case .tier3:
            return 14
        case .tier4:
            return 30
        case .custom:
            return 0
        }
    }
    
    var displayName: String {
        switch self {
        case .tier1:
            return String(localized: LocalizedStringResource("Tier 1", comment: "Spending tier 1 name"))
        case .tier2:
            return String(localized: LocalizedStringResource("Tier 2", comment: "Spending tier 2 name"))
        case .tier3:
            return String(localized: LocalizedStringResource("Tier 3", comment: "Spending tier 3 name"))
        case .tier4:
            return String(localized: LocalizedStringResource("Tier 4", comment: "Spending tier 4 name"))
        case .custom:
            return String(localized: LocalizedStringResource("Custom", comment: "Custom spending tier name"))
        }
    }
    
    var qualificationText: String {
        switch self {
        case .tier1:
            return String(localized: LocalizedStringResource("Default with valid payment method added", comment: "Tier 1 qualification"))
        case .tier2:
            return String(localized: LocalizedStringResource("Total historical spend of $50+ and 7 days since first payment", comment: "Tier 2 qualification"))
        case .tier3:
            return String(localized: LocalizedStringResource("Total historical spend of $500+ and 14 days since first payment", comment: "Tier 3 qualification"))
        case .tier4:
            return String(localized: LocalizedStringResource("Total historical spend of $5,000+ and 30 days since first payment", comment: "Tier 4 qualification"))
        case .custom:
            return String(localized: LocalizedStringResource("Contact support for custom limits", comment: "Custom tier qualification"))
        }
    }
    
    var canBuyCredits: Bool {
        switch self {
        case .tier1, .tier2, .tier3, .tier4:
            return true
        case .custom:
            return false
        }
    }
}

// MARK: - Tier System Manager
@MainActor
class TierSystemManager: ObservableObject {
    static let shared = TierSystemManager()
    
    @Published var currentTier: SpendingTier = .tier1
    @Published var currentMonthlySpend: Double = 0.0
    @Published var historicalSpend: Double = 0.0
    @Published var customLimit: Double = 0.0
    @Published var firstPaymentDate: Date?
    @Published var isLoading = false
    @Published var error: String?
    
    private let userDefaults = UserDefaults.standard
    private let secureDataManager = SecureTierDataManager.shared
    private let currentTierKey = "currentTier"
    private let customLimitKey = "customLimit"
    private let monthlySpendKey = "currentMonthlySpend"
    private let lastResetDateKey = "lastMonthlyReset"
    
    // StoreKit 2 Transaction監視
    private var transactionListener: Task<Void, Error>?
    
    // 競合状態を防ぐためのセマフォ
    private let dataAccessQueue = DispatchQueue(label: "com.cription.tiersystem.data", attributes: .concurrent)
    private let recalculationSemaphore = DispatchSemaphore(value: 1)
    
    private init() {
        loadData()
        startTransactionListener()
        checkMonthlyReset()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Data Management
    private func loadData() {
        // セキュアなデータの復元
        let recoveredData = secureDataManager.recoverData()
        historicalSpend = recoveredData.historicalSpend
        firstPaymentDate = recoveredData.firstPaymentDate
        
        // UserDefaultsから非機密データを読み込み
        customLimit = userDefaults.double(forKey: customLimitKey)
        currentMonthlySpend = userDefaults.double(forKey: monthlySpendKey)
        
        if let tierString = userDefaults.string(forKey: currentTierKey),
           let tier = SpendingTier(rawValue: tierString) {
            currentTier = tier
        }
        
        // StoreKit 2から履歴支出を再計算
        Task {
            await recalculateHistoricalSpend()
        }
    }
    
    private func saveData() {
        // データ整合性を保証するためのトランザクション処理
        userDefaults.beginContentAccess()
        defer { userDefaults.endContentAccess() }
        
        do {
            // セキュアなデータをKeychainに保存
            guard secureDataManager.saveHistoricalSpend(historicalSpend) else {
                throw NSError(domain: "TierSystemManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save historical spend to Keychain"])
            }
            
            if let firstPaymentDate = firstPaymentDate {
                guard secureDataManager.saveFirstPaymentDate(firstPaymentDate) else {
                    throw NSError(domain: "TierSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to save first payment date to Keychain"])
                }
            }
            
            // 非機密データをUserDefaultsに保存
            userDefaults.set(currentTier.rawValue, forKey: currentTierKey)
            userDefaults.set(customLimit, forKey: customLimitKey)
            userDefaults.set(currentMonthlySpend, forKey: monthlySpendKey)
            
            // データの整合性チェック
            guard secureDataManager.loadHistoricalSpend() == historicalSpend else {
                throw NSError(domain: "TierSystemManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Data integrity check failed for historical spend"])
            }
            
            guard userDefaults.string(forKey: currentTierKey) == currentTier.rawValue else {
                throw NSError(domain: "TierSystemManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Data integrity check failed for current tier"])
            }
            
            print("✅ Data saved successfully with integrity check")
            
        } catch {
            print("❌ Failed to save data: \(error)")
            // エラーが発生した場合は、データを復元を試行
            loadData()
        }
    }
    
    // MARK: - StoreKit 2 Integration
    private func startTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await self.handleTransactionUpdate(transaction)
                } catch {
                    await MainActor.run {
                        self.error = "Transaction verification failed: \(error.localizedDescription)"
                    }
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        guard transaction.revocationDate == nil else {
            // 返金された場合、履歴支出から差し引く
            await removeSpendingFromTransaction(transaction)
            return
        }
        
        guard transaction.revocationDate == nil else { return }
        
        // 新しい購入の場合、履歴支出に追加
        await addSpendingFromTransaction(transaction)
    }
    
    private func addSpendingFromTransaction(_ transaction: Transaction) async {
        let amount = await getTransactionAmount(transaction)
        
        // スレッドセーフな更新
        await MainActor.run {
            // 初回支払い日を記録
            if self.firstPaymentDate == nil {
                self.firstPaymentDate = transaction.purchaseDate
            }
            
            self.historicalSpend += amount
            self.updateCurrentTier()
            self.saveData()
        }
        
        print("💰 Added $\(String(format: "%.2f", amount)) from transaction \(transaction.id) to historical spend. Total: $\(String(format: "%.2f", amount))")
    }
    
    private func removeSpendingFromTransaction(_ transaction: Transaction) async {
        let amount = await getTransactionAmount(transaction)
        
        // スレッドセーフな更新
        await MainActor.run {
            self.historicalSpend = max(0, self.historicalSpend - amount)
            self.updateCurrentTier()
            self.saveData()
        }
        
        print("💸 Removed $\(String(format: "%.2f", amount)) from transaction \(transaction.id) from historical spend. Total: $\(String(format: "%.2f", amount))")
    }
    
    private func getTransactionAmount(_ transaction: Transaction) async -> Double {
        // トランザクションの金額を取得
        // StoreKit 2では、transaction.priceはProduct.Price型
        // 実際の金額を取得するには、Productを取得する必要がある
        
        do {
            let product = try await Product.products(for: [transaction.productID]).first
            if let product = product {
                // 価格を取得（実際の実装では、product.priceを適切に変換）
                return await getProductPrice(product)
            } else {
                await MainActor.run {
                    self.error = "Product not found for transaction: \(transaction.productID)"
                }
                print("❌ Product not found for transaction: \(transaction.productID)")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to get product for transaction: \(error.localizedDescription)"
            }
            print("❌ Failed to get product for transaction: \(error)")
        }
        
        return 0.0
    }
    
    private func getProductPrice(_ product: Product) async -> Double {
        // StoreKit 2の価格情報を使用
        let price = product.price
        
        // 価格をDoubleに変換（Product.Priceから）
        if let priceValue = Double(price.description) {
            return priceValue
        }
        
        // フォールバック: クレジット購入の価格マッピング
        let creditPrices: [String: Double] = [
            "Cription.credits.22": 19.99,
            "Cription.credits.55": 49.99,
            "Cription.credits.110": 99.99,
            "Cription.credits.220": 199.99,
            "Cription.credits.1100": 999.99
        ]
        
        // サブスクリプションプランの価格マッピング
        let subscriptionPrices: [String: Double] = [
            "Cription.plus.weekly": 4.99,
            "Cription.plus.monthly": 19.99,
            "Cription.plus.yearly": 199.99
        ]
        
        // ローカルモデルの価格マッピング
        let modelPrices: [String: Double] = [
            "Cription.model.whisper-large": 9.99,
            "Cription.model.whisper-medium": 4.99
        ]
        
        if let price = creditPrices[product.id] {
            return price
        } else if let price = subscriptionPrices[product.id] {
            return price
        } else if let price = modelPrices[product.id] {
            return price
        }
        
        // デフォルト価格（実際の価格が取得できない場合）
        return 0.0
    }
    
    // MARK: - Historical Spend Recalculation
    private func recalculateHistoricalSpend() async {
        // 競合状態を防ぐためのセマフォ
        recalculationSemaphore.wait()
        defer { recalculationSemaphore.signal() }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            var totalSpend: Double = 0.0
            var earliestPaymentDate: Date?
            var transactionCount = 0
            
            // StoreKit 2のTransaction.allを使用してすべてのトランザクション履歴を取得
            for await result in Transaction.all {
                do {
                    let transaction = try checkVerified(result)
                    transactionCount += 1
                    
                    // 返金されていないトランザクションのみ
                    guard transaction.revocationDate == nil else { 
                        print("⏭️ Skipping revoked transaction: \(transaction.id)")
                        continue 
                    }
                    
                    let amount = await getTransactionAmount(transaction)
                    totalSpend += amount
                    
                    // 最初の支払い日を記録
                    if earliestPaymentDate == nil || transaction.purchaseDate < earliestPaymentDate! {
                        earliestPaymentDate = transaction.purchaseDate
                    }
                    
                    print("💰 Transaction \(transaction.id): $\(String(format: "%.2f", amount)) on \(transaction.purchaseDate)")
                    
                } catch {
                    print("❌ Transaction verification failed during recalculation: \(error)")
                }
            }
            
            // データを更新（スレッドセーフ）
            await MainActor.run {
                self.historicalSpend = totalSpend
                if self.firstPaymentDate == nil {
                    self.firstPaymentDate = earliestPaymentDate
                }
                
                self.updateCurrentTier()
                self.saveData()
            }
            
            print("✅ Recalculated historical spend: $\(String(format: "%.2f", totalSpend)) from \(transactionCount) transactions")
            
        } catch {
            await MainActor.run {
                self.error = "Failed to recalculate historical spend: \(error.localizedDescription)"
            }
            print("❌ Failed to recalculate historical spend: \(error)")
        }
    }
    
    // MARK: - Tier Management
    func updateCurrentTier() {
        let newTier = determineTierFromHistoricalSpend()
        if newTier != currentTier {
            currentTier = newTier
            saveData()
            print("🔄 Tier updated to: \(currentTier.displayName)")
        }
    }
    
    private func determineTierFromHistoricalSpend() -> SpendingTier {
        // エッジケースの処理
        guard historicalSpend.isFinite && historicalSpend >= 0 else {
            print("⚠️ Invalid historical spend: \(historicalSpend), defaulting to Tier 1")
            return .tier1
        }
        
        let daysSinceFirstPayment = getDaysSinceFirstPayment()
        
        // OpenAI Tier System準拠の判定ロジック
        // Tier 4: $5,000+ かつ 30日以上
        if historicalSpend >= SpendingTier.tier4.requiredHistoricalSpend && 
           daysSinceFirstPayment >= SpendingTier.tier4.requiredDaysSinceFirstPayment {
            return .tier4
        }
        
        // Tier 3: $500+ かつ 14日以上
        if historicalSpend >= SpendingTier.tier3.requiredHistoricalSpend && 
           daysSinceFirstPayment >= SpendingTier.tier3.requiredDaysSinceFirstPayment {
            return .tier3
        }
        
        // Tier 2: $50+ かつ 7日以上
        if historicalSpend >= SpendingTier.tier2.requiredHistoricalSpend && 
           daysSinceFirstPayment >= SpendingTier.tier2.requiredDaysSinceFirstPayment {
            return .tier2
        }
        
        // Tier 1: デフォルト（有効な支払い方法追加済み）
        return .tier1
    }
    
    private func getDaysSinceFirstPayment() -> Int {
        guard let firstPaymentDate = firstPaymentDate else { return 0 }
        
        // エッジケースの処理
        let calendar = Calendar.current
        let now = Date()
        
        // 未来の日付の場合は0を返す
        if firstPaymentDate > now {
            print("⚠️ First payment date is in the future: \(firstPaymentDate)")
            return 0
        }
        
        // 日付計算
        let components = calendar.dateComponents([.day], from: firstPaymentDate, to: now)
        let days = components.day ?? 0
        
        // 異常な値の場合は0を返す
        guard days >= 0 && days <= 36500 else { // 100年を超える場合は異常
            print("⚠️ Invalid days since first payment: \(days)")
            return 0
        }
        
        return days
    }
    
    // MARK: - Monthly Reset
    private func checkMonthlyReset() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            // エッジケースの処理
            // 未来の日付の場合は現在時刻でリセット
            if lastResetDate > now {
                print("⚠️ Last reset date is in the future, resetting now")
                resetMonthlySpend()
                return
            }
            
            // 異常に古い日付の場合は現在時刻でリセット
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            if lastResetDate < oneYearAgo {
                print("⚠️ Last reset date is too old, resetting now")
                resetMonthlySpend()
                return
            }
            
            // 前回のリセットから1ヶ月経過しているかチェック
            if let nowMonthStart = calendar.dateInterval(of: .month, for: now)?.start,
               let lastMonthStart = calendar.dateInterval(of: .month, for: lastResetDate)?.start {
                if nowMonthStart != lastMonthStart {
                    resetMonthlySpend()
                }
            } else {
                // 日付計算に失敗した場合は安全のためリセット
                print("⚠️ Failed to calculate month intervals, resetting")
                resetMonthlySpend()
            }
        } else {
            // 初回実行時はリセット
            resetMonthlySpend()
        }
    }
    
    private func resetMonthlySpend() {
        currentMonthlySpend = 0.0
        userDefaults.set(currentMonthlySpend, forKey: monthlySpendKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
        print("🔄 Monthly spend reset to $0.00")
    }
    
    // MARK: - Spending Management
    func addSpending(_ amount: Double) {
        // データ検証
        guard amount >= 0 else {
            error = "Invalid spending amount: negative values are not allowed"
            print("❌ Invalid spending amount: \(amount)")
            return
        }
        
        guard amount <= 1000000.0 else {
            error = "Invalid spending amount: amount exceeds maximum limit"
            print("❌ Invalid spending amount: \(amount) exceeds maximum limit")
            return
        }
        
        guard amount.isFinite else {
            error = "Invalid spending amount: non-finite values are not allowed"
            print("❌ Invalid spending amount: non-finite value \(amount)")
            return
        }
        
        // 制限チェック
        guard canSpend(amount) else {
            error = "Spending limit exceeded: cannot spend $\(String(format: "%.2f", amount))"
            print("❌ Spending limit exceeded: \(amount)")
            return
        }
        
        // スレッドセーフな更新
        dataAccessQueue.async(flags: .barrier) {
            self.currentMonthlySpend += amount
            self.saveData()
        }
        
        error = nil // エラーをクリア
        print("💸 Added $\(String(format: "%.2f", amount)) to monthly spend. Total: $\(String(format: "%.2f", currentMonthlySpend))")
    }
    
    func resetMonthlySpend() {
        currentMonthlySpend = 0.0
        saveData()
    }
    
    // MARK: - Limit Checking
    func canSpend(_ amount: Double) -> Bool {
        let limit = getCurrentLimit()
        return (currentMonthlySpend + amount) <= limit
    }
    
    func getCurrentLimit() -> Double {
        if currentTier == .custom {
            return customLimit
        }
        return currentTier.monthlyLimit
    }
    
    func getRemainingLimit() -> Double {
        return max(0, getCurrentLimit() - currentMonthlySpend)
    }
    
    // MARK: - Tier Information
    func getAvailableTiers() -> [SpendingTier] {
        return SpendingTier.allCases.filter { tier in
            if tier == .custom {
                return true // カスタムは常に表示
            }
            return historicalSpend >= tier.requiredHistoricalSpend
        }
    }
    
    func getNextTier() -> SpendingTier? {
        let allTiers = SpendingTier.allCases.filter { $0 != .custom }
        let currentIndex = allTiers.firstIndex(of: currentTier)
        
        if let index = currentIndex, index < allTiers.count - 1 {
            return allTiers[index + 1]
        }
        return nil
    }
    
    func getRequiredSpendForNextTier() -> Double? {
        guard let nextTier = getNextTier() else { return nil }
        return max(0, nextTier.requiredHistoricalSpend - historicalSpend)
    }
    
    func getRequiredDaysForNextTier() -> Int? {
        guard let nextTier = getNextTier() else { return nil }
        let daysSinceFirstPayment = getDaysSinceFirstPayment()
        return max(0, nextTier.requiredDaysSinceFirstPayment - daysSinceFirstPayment)
    }
    
    // MARK: - Custom Limit Management
    func setCustomLimit(_ limit: Double) {
        // データ検証
        guard limit >= 0 else {
            error = "Invalid custom limit: negative values are not allowed"
            print("❌ Invalid custom limit: \(limit)")
            return
        }
        
        guard limit <= 1000000.0 else {
            error = "Invalid custom limit: limit exceeds maximum allowed value"
            print("❌ Invalid custom limit: \(limit) exceeds maximum")
            return
        }
        
        guard limit.isFinite else {
            error = "Invalid custom limit: non-finite values are not allowed"
            print("❌ Invalid custom limit: non-finite value \(limit)")
            return
        }
        
        customLimit = limit
        currentTier = .custom
        saveData()
        error = nil // エラーをクリア
        print("✅ Custom limit set to $\(String(format: "%.2f", limit))")
    }
    
    func clearCustomLimit() {
        customLimit = 0.0
        updateCurrentTier()
        saveData()
    }
    
    // MARK: - Credit Purchase
    func purchaseCredits(_ amount: Double) async throws {
        // StoreKit 2を使用してクレジットを購入
        // 実際の実装では、Productを取得して購入処理を行う
        let productID = getCreditProductID(for: amount)
        
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                throw TierSystemError.productNotFound
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                // 購入成功時は自動的にTransaction.updatesで処理される
                print("✅ Credit purchase successful: $\(String(format: "%.2f", amount))")
                
            case .userCancelled:
                throw TierSystemError.userCancelled
            case .pending:
                throw TierSystemError.pending
            @unknown default:
                throw TierSystemError.unknown
            }
            
        } catch {
            print("❌ Credit purchase failed: \(error)")
            throw error
        }
    }
    
    private func getCreditProductID(for amount: Double) -> String {
        // 金額に基づいて適切なクレジット商品IDを返す
        switch amount {
        case 0..<25:
            return "Cription.credits.22"
        case 25..<75:
            return "Cription.credits.55"
        case 75..<150:
            return "Cription.credits.110"
        case 150..<500:
            return "Cription.credits.220"
        default:
            return "Cription.credits.1100"
        }
    }
    
    // MARK: - Manual Refresh
    func refreshData() async {
        await recalculateHistoricalSpend()
    }
}

// MARK: - StoreKit 2 Helper
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw StoreError.failedVerification
    case .verified(let safe):
        return safe
    }
}

enum StoreError: Error {
    case failedVerification
}

enum TierSystemError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unknown
    case invalidAmount
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled by user"
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        case .invalidAmount:
            return "Invalid purchase amount"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
