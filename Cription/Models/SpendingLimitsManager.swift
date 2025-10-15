//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation
import SwiftUI

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
            return String(localized: LocalizedStringResource("Total historical spend of $50+", comment: "Tier 2 qualification"))
        case .tier3:
            return String(localized: LocalizedStringResource("Total historical spend of $500+", comment: "Tier 3 qualification"))
        case .tier4:
            return String(localized: LocalizedStringResource("Total historical spend of $5,000+", comment: "Tier 4 qualification"))
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

// MARK: - Spending Limits Manager (Delegates to TierSystemManager)
@MainActor
class SpendingLimitsManager: ObservableObject {
    static let shared = SpendingLimitsManager()
    
    @Published var currentTier: SpendingTier = .tier1
    @Published var currentMonthlySpend: Double = 0.0
    @Published var historicalSpend: Double = 0.0
    @Published var customLimit: Double = 0.0
    @Published var firstPaymentDate: Date?
    @Published var isLoading = false
    @Published var error: String?
    
    private let tierSystemManager = TierSystemManager.shared
    
    private init() {
        // TierSystemManagerからデータを同期
        syncWithTierSystemManager()
        
        // TierSystemManagerの変更を監視
        observeTierSystemManager()
    }
    
    private func syncWithTierSystemManager() {
        currentTier = tierSystemManager.currentTier
        currentMonthlySpend = tierSystemManager.currentMonthlySpend
        historicalSpend = tierSystemManager.historicalSpend
        customLimit = tierSystemManager.customLimit
        firstPaymentDate = tierSystemManager.firstPaymentDate
        isLoading = tierSystemManager.isLoading
        error = tierSystemManager.error
    }
    
    private func observeTierSystemManager() {
        // TierSystemManagerの変更を監視して自動同期
        Task {
            for await _ in tierSystemManager.$currentTier.values {
                await MainActor.run {
                    self.syncWithTierSystemManager()
                }
            }
        }
        
        Task {
            for await _ in tierSystemManager.$currentMonthlySpend.values {
                await MainActor.run {
                    self.syncWithTierSystemManager()
                }
            }
        }
        
        Task {
            for await _ in tierSystemManager.$historicalSpend.values {
                await MainActor.run {
                    self.syncWithTierSystemManager()
                }
            }
        }
    }
    
    // MARK: - Data Management (Delegated to TierSystemManager)
    private func loadData() {
        // TierSystemManagerに委譲
        syncWithTierSystemManager()
    }
    
    private func saveData() {
        // TierSystemManagerに委譲
        syncWithTierSystemManager()
    }
    
    // MARK: - Tier Management (Delegated to TierSystemManager)
    func updateCurrentTier() {
        // TierSystemManagerに委譲
        tierSystemManager.updateCurrentTier()
        syncWithTierSystemManager()
    }
    
    private func determineTierFromHistoricalSpend() -> SpendingTier {
        // TierSystemManagerに委譲
        return tierSystemManager.currentTier
    }
    
    // MARK: - Spending Management (Delegated to TierSystemManager)
    func addSpending(_ amount: Double) {
        // TierSystemManagerに委譲
        tierSystemManager.addSpending(amount)
        syncWithTierSystemManager()
    }
    
    func resetMonthlySpend() {
        // TierSystemManagerに委譲
        tierSystemManager.resetMonthlySpend()
        syncWithTierSystemManager()
    }
    
    // MARK: - Credit Purchase (Delegated to TierSystemManager)
    func purchaseCredits(_ amount: Double) {
        // TierSystemManagerに委譲（StoreKit 2で自動処理される）
        syncWithTierSystemManager()
    }
    
    // MARK: - Limit Checking (Delegated to TierSystemManager)
    func canSpend(_ amount: Double) -> Bool {
        // TierSystemManagerに委譲
        return tierSystemManager.canSpend(amount)
    }
    
    func getCurrentLimit() -> Double {
        // TierSystemManagerに委譲
        return tierSystemManager.getCurrentLimit()
    }
    
    func getRemainingLimit() -> Double {
        // TierSystemManagerに委譲
        return tierSystemManager.getRemainingLimit()
    }
    
    // MARK: - Tier Information (Delegated to TierSystemManager)
    func getAvailableTiers() -> [SpendingTier] {
        // TierSystemManagerに委譲
        return tierSystemManager.getAvailableTiers()
    }
    
    func getNextTier() -> SpendingTier? {
        // TierSystemManagerに委譲
        return tierSystemManager.getNextTier()
    }
    
    func getRequiredSpendForNextTier() -> Double? {
        // TierSystemManagerに委譲
        return tierSystemManager.getRequiredSpendForNextTier()
    }
    
    func getRequiredDaysForNextTier() -> Int? {
        // TierSystemManagerに委譲
        return tierSystemManager.getRequiredDaysForNextTier()
    }
    
    // MARK: - Custom Limit Management (Delegated to TierSystemManager)
    func setCustomLimit(_ limit: Double) {
        // TierSystemManagerに委譲
        tierSystemManager.setCustomLimit(limit)
        syncWithTierSystemManager()
    }
    
    func clearCustomLimit() {
        // TierSystemManagerに委譲
        tierSystemManager.clearCustomLimit()
        syncWithTierSystemManager()
    }
}

// MARK: - Spending Limits View Model (Updated to use TierSystemManager)
class SpendingLimitsViewModel: ObservableObject {
    @Published var selectedTier: SpendingTier = .tier1
    @Published var customLimitText: String = ""
    @Published var showingCustomLimitDialog = false
    @Published var showingCreditPurchaseDialog = false
    @Published var creditAmount: Double = 100.0
    
    private let tierSystemManager = TierSystemManager.shared
    
    var currentTier: SpendingTier {
        tierSystemManager.currentTier
    }
    
    var currentMonthlySpend: Double {
        tierSystemManager.currentMonthlySpend
    }
    
    var historicalSpend: Double {
        tierSystemManager.historicalSpend
    }
    
    var currentLimit: Double {
        tierSystemManager.getCurrentLimit()
    }
    
    var remainingLimit: Double {
        tierSystemManager.getRemainingLimit()
    }
    
    var availableTiers: [SpendingTier] {
        tierSystemManager.getAvailableTiers()
    }
    
    var nextTier: SpendingTier? {
        tierSystemManager.getNextTier()
    }
    
    var requiredSpendForNextTier: Double? {
        tierSystemManager.getRequiredSpendForNextTier()
    }
    
    var requiredDaysForNextTier: Int? {
        tierSystemManager.getRequiredDaysForNextTier()
    }
    
    func purchaseCredits() async {
        do {
            try await tierSystemManager.purchaseCredits(creditAmount)
            showingCreditPurchaseDialog = false
        } catch {
            print("❌ Credit purchase failed: \(error)")
            // エラーハンドリングはTierSystemManagerで行われる
        }
    }
    
    func setCustomLimit() {
        if let limit = Double(customLimitText) {
            tierSystemManager.setCustomLimit(limit)
            showingCustomLimitDialog = false
            customLimitText = ""
        }
    }
}
