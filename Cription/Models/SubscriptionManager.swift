//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit

// MARK: - SubCription Manager

@MainActor
class SubCriptionManager: ObservableObject {
    static let shared = SubCriptionManager()
    
    @Published var isSubCriptiond = false
    @Published var subCriptionTier: SubCriptionTier = .free
    @Published var remainingUsage: Int = 0
    @Published var subCriptionStatus: SubCriptionStatus = .unknown
    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    // Token limit management
    @Published var shouldShowUpgradePrompt = false
    @Published var shouldShowModelPurchasePrompt = false
    @Published var currentTokenUsage: Int = 0
    @Published var tokenLimit: Int = 1000 // デフォルト制限
    @Published var isNearLimit: Bool = false
    
    private let productIdentifiers: Set<String> = [
        "Cription.plus.weekly",
        "Cription.plus.monthly", 
        "Cription.plus.yearly"
    ]
    
    enum SubCriptionTier: String, CaseIterable {
        case free = "free"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var hasOpenAIAccess: Bool {
            switch self {
            case .free: return false
            case .weekly, .monthly, .yearly: return true
            }
        }
        
        var monthlyUsageLimit: Int {
            switch self {
            case .free: return 0 // No cloud model access for free plan
            case .weekly: return 300 // 300 minutes for weekly plan
            case .monthly: return 300 // 300 minutes for monthly plan
            case .yearly: return 300 // 300 minutes for yearly plan
            }
        }
        
        var tokenLimit: Int {
            switch self {
            case .free: return 1000
            case .weekly: return 5000
            case .monthly: return 20000
            case .yearly: return 50000
            }
        }
        
        var productIdentifiers: [String] {
            switch self {
            case .free: return []
            case .weekly: return ["Cription.plus.weekly"]
            case .monthly: return ["Cription.plus.monthly"]
            case .yearly: return ["Cription.plus.yearly"]
            }
        }
        
        var allowedModels: [String] {
            switch self {
            case .free: 
                return [] // Free tier has no model access (only credit-based usage)
            case .weekly, .monthly, .yearly:
                return [] // All models allowed (empty array means no restrictions)
            }
        }
        
        var canUseBundleModels: Bool {
            switch self {
            case .free: return true // All tiers can use bundle models
            case .weekly, .monthly, .yearly: return true // Paid tiers can use bundle models
            }
        }
        
        var canUseCloudModels: Bool {
            switch self {
            case .free: return false // Free tier cannot use cloud models (credit-only)
            case .weekly, .monthly, .yearly: return true // Paid tiers can use cloud models
            }
        }
    }
    
    enum SubCriptionStatus {
        case unknown
        case subCriptiond
        case notSubCriptiond
        case expired
        case pending
    }
    
    init() {
        Task {
            await loadProducts()
            await checkSubCriptionStatus()
            await checkForUnfinishedTransactions()
            observeTransactionUpdates()
            
            // トークン制限を更新
            await updateTokenLimitForSubscription()
        }
    }
    
    // MARK: - Public Methods
    
    func checkSubCriptionStatus() async {
        do {
            for await result in Transaction.currentEntitlements {
                guard let transaction = await unwrapVerificationResult(result) else { continue }
                
                if productIdentifiers.contains(transaction.productID) {
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                        self.updateSubCriptionTier(from: transaction.productID)
                        self.isSubCriptiond = true
                        self.subCriptionStatus = .subCriptiond
                    }
                }
            }
            
            // 購入済みプロダクトがない場合
            if purchasedProductIDs.isEmpty {
                await MainActor.run {
                    self.isSubCriptiond = false
                    self.subCriptionTier = .free
                    self.subCriptionStatus = .notSubCriptiond
                }
            }
            
        } catch {
            print("Error checking subCription status: \(error)")
            await MainActor.run {
                self.subCriptionStatus = .unknown
            }
        }
    }
    
    func purchaseProduct(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            guard let transaction = await unwrapVerificationResult(verification) else {
                throw SubCriptionError.purchaseFailed
            }
            
            await transaction.finish()
            await MainActor.run {
                self.purchasedProductIDs.insert(transaction.productID)
                self.updateSubCriptionTier(from: transaction.productID)
                self.isSubCriptiond = true
                self.subCriptionStatus = .subCriptiond
            }
        case .userCancelled:
            throw SubCriptionError.userCancelled
        case .pending:
            await MainActor.run {
                self.subCriptionStatus = .pending
            }
        @unknown default:
            throw SubCriptionError.unknown
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubCriptionStatus()
    }
    
    func restorePurchasesWithProgress() async -> Bool {
        do {
            try await restorePurchases()
            return true
        } catch {
            print("Failed to restore purchases: \(error)")
            return false
        }
    }
    
    func canUseOpenAITranCription() -> Bool {
        print("🔍 SubscriptionManager: Checking OpenAI transcription access")
        print("   - Subscription tier: \(subCriptionTier)")
        print("   - Remaining usage: \(remainingUsage)")
        print("   - Is subscribed: \(isSubCriptiond)")
        
        // Weekly, Monthly, and Yearly tier can use OpenAI if they have remaining usage
        if subCriptionTier == .weekly || subCriptionTier == .monthly || subCriptionTier == .yearly {
            let canUse = remainingUsage > 0
            print("🔍 \(subCriptionTier) tier - OpenAI access: \(canUse ? "granted" : "denied") (usage: \(remainingUsage))")
            return canUse
        }
        
        // Free tier cannot use OpenAI
        if subCriptionTier == .free {
            print("❌ Free tier - OpenAI access denied")
            return false
        }
        
        print("❌ Unknown tier - OpenAI access denied")
        return false
    }
    
    func canUseModel(_ model: String) -> Bool {
        // All tiers can use all models (local models are now unrestricted)
        return true
    }
    
    func canUseBundleModel(_ model: String) -> Bool {
        let bundleModels = ["whisper-base", "whisper-small", "whisper-tiny"]
        
        // Check if it's a bundle model
        guard bundleModels.contains(model) else { return false }
        
        // All tiers can use bundle models
        return true
    }
    
    func canUseCloudModel(_ model: String) -> Bool {
        let cloudModels = ["whisper-1", "gpt-4o-transcribe", "gpt-4o-mini-transcribe"]
        
        // Check if model is a cloud model
        guard cloudModels.contains(model) else { return false }
        
        // Paid tiers can use cloud models without usage limit
        if subCriptionTier == .weekly || subCriptionTier == .monthly || subCriptionTier == .yearly {
            return true
        }
        
        // Free tier can use cloud models only with credits
        if subCriptionTier == .free {
            let creditManager = CreditManager.shared
            let estimatedCost = creditManager.calculateAPICost(duration: 60.0, model: model) // 1分間の推定コスト
            return creditManager.canAfford(estimatedCost)
        }
        
        return false
    }
    
    func consumeUsage(minutes: Int) {
        remainingUsage = max(0, remainingUsage - minutes)
    }
    
    func consumeAPICredits(duration: Double, model: String, isTranslation: Bool = false) -> Bool {
        // For Weekly, Monthly, and Yearly tier, consume subscription usage
        if (subCriptionTier == .weekly || subCriptionTier == .monthly || subCriptionTier == .yearly) && remainingUsage > 0 {
            let minutes = Int(ceil(duration / 60.0))
            consumeUsage(minutes: minutes)
            return true
        }
        
        // For Free tier, consume credits
        if subCriptionTier == .free {
            let creditManager = CreditManager.shared
            let cost = creditManager.calculateAPICost(duration: duration, model: model, isTranslation: isTranslation)
            let success = creditManager.consumeCredits(cost, description: "API usage - \(model)")
            return success
        }
        
        return false
    }
    
    func getUsageLimit() -> Int {
        return subCriptionTier.monthlyUsageLimit
    }
    
    func getRemainingUsage() -> Int {
        return remainingUsage
    }
    
    // MARK: - Private Methods
    
    private func loadProducts() async {
        do {
            let products = try await Product.products(for: productIdentifiers)
            await MainActor.run {
                self.availableProducts = products
            }
        } catch {
            print("Error loading products: \(error)")
        }
    }
    
    // MARK: - Transaction Management
    
    func observeTransactionUpdates() {
        Task {
            for await update in Transaction.updates {
                guard let transaction = await unwrapVerificationResult(update) else { continue }
                await processTransaction(transaction)
            }
        }
    }
    
    func checkForUnfinishedTransactions() async {
        for await transaction in Transaction.unfinished {
            guard let transaction = await unwrapVerificationResult(transaction) else { continue }
            await processTransaction(transaction)
        }
    }
    
    private func processTransaction(_ transaction: StoreKit.Transaction) async {
        if productIdentifiers.contains(transaction.productID) {
            await MainActor.run {
                self.purchasedProductIDs.insert(transaction.productID)
                self.updateSubCriptionTier(from: transaction.productID)
                self.isSubCriptiond = true
                self.subCriptionStatus = .subCriptiond
            }
        }
        await transaction.finish()
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
    
    private func updateSubCriptionTier(from productID: String) {
        if productID.contains("weekly") {
            subCriptionTier = .weekly
        } else if productID.contains("monthly") {
            subCriptionTier = .monthly
        } else if productID.contains("yearly") {
            subCriptionTier = .yearly
        } else {
            subCriptionTier = .free
        }
        
        // 使用量をリセット
        remainingUsage = subCriptionTier.monthlyUsageLimit
        
        // トークン制限を更新
        Task {
            await updateTokenLimitForSubscription()
        }
    }
    
    // MARK: - Token Management
    
    func updateTokenLimitForSubscription() async {
        await MainActor.run {
            self.tokenLimit = self.subCriptionTier.tokenLimit
            self.checkTokenLimitStatus()
        }
    }
    
    func addTokenUsage(_ tokens: Int) {
        currentTokenUsage += tokens
        checkTokenLimitStatus()
    }
    
    func checkTokenLimitStatus() {
        let usagePercentage = Double(currentTokenUsage) / Double(tokenLimit)
        isNearLimit = usagePercentage >= 0.8
        
        if usagePercentage >= 1.0 {
            if isSubCriptiond {
                shouldShowModelPurchasePrompt = true
            } else {
                shouldShowUpgradePrompt = true
            }
        }
    }
    
    func getUsagePercentage() -> Double {
        return Double(currentTokenUsage) / Double(tokenLimit)
    }
    
    func resetTokenUsage() {
        currentTokenUsage = 0
        checkTokenLimitStatus()
    }
}

// MARK: - SubCription Error

enum SubCriptionError: LocalizedError {
    case userCancelled
    case unknown
    case productNotFound
    case purchaseFailed
    
    var errorDeCription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .unknown:
            return "An unknown error occurred"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

// MARK: - SubCription View Model

@MainActor
class SubCriptionViewModel: ObservableObject {
    @Published var showingSubCriptionSheet = false
    @Published var selectedTier: SubCriptionManager.SubCriptionTier = .monthly
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let subscriptionManagerInstance = SubCriptionManager()
    
    var subCriptionManager: SubCriptionManager {
        return subscriptionManagerInstance
    }
    
    func showSubCriptionSheet() {
        showingSubCriptionSheet = true
    }
    
    func hideSubCriptionSheet() {
        showingSubCriptionSheet = false
    }
    
}