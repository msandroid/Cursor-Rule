//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit

@MainActor
class UsageTrackingManager: ObservableObject {
    static let shared = UsageTrackingManager()
    
    @Published var totalUsageMinutes: Double = 0.0
    @Published var shouldShowBillingPrompt = false
    @Published var shouldShowReviewPrompt = false
    
    private let userDefaults = UserDefaults.standard
    private let totalUsageKey = "TotalUsageMinutes"
    private let billingPromptShownKey = "BillingPromptShown"
    private let reviewPromptShownKey = "ReviewPromptShown"
    private let lastReviewPromptDateKey = "LastReviewPromptDate"
    
    // 30分の閾値
    private let billingThresholdMinutes: Double = 30.0
    
    private init() {
        loadUsageData()
    }
    
    // MARK: - Usage Tracking
    
    func addUsage(minutes: Double) {
        totalUsageMinutes += minutes
        saveUsageData()
        
        // 30分を超えた場合の課金勧誘チェック
        checkBillingPrompt()
    }
    
    func addTokenUsage(tokens: Int) {
        // トークンを分に変換（概算: 1分 = 約1000トークン）
        let estimatedMinutes = Double(tokens) / 1000.0
        addUsage(minutes: estimatedMinutes)
    }
    
    private func checkBillingPrompt() {
        guard totalUsageMinutes >= billingThresholdMinutes else { return }
        guard !userDefaults.bool(forKey: billingPromptShownKey) else { return }
        
        // 課金勧誘は一度だけ表示
        shouldShowBillingPrompt = true
    }
    
    // MARK: - Review Prompt
    
    func requestReviewAfterSTT() {
        // 最後のレビュープロンプトから7日以上経過しているかチェック
        let lastPromptDate = userDefaults.object(forKey: lastReviewPromptDateKey) as? Date ?? Date.distantPast
        let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
        
        // 7日以上経過している場合のみレビュー依頼を表示
        guard daysSinceLastPrompt >= 7 else { return }
        
        // 使用量が一定以上の場合のみレビュー依頼
        guard totalUsageMinutes >= 10.0 else { return }
        
        shouldShowReviewPrompt = true
        
        // 日付を更新
        userDefaults.set(Date(), forKey: lastReviewPromptDateKey)
    }
    
    // MARK: - Prompt Actions
    
    func dismissBillingPrompt() {
        shouldShowBillingPrompt = false
        userDefaults.set(true, forKey: billingPromptShownKey)
    }
    
    func dismissReviewPrompt() {
        shouldShowReviewPrompt = false
    }
    
    func openBillingView() {
        shouldShowBillingPrompt = false
        userDefaults.set(true, forKey: billingPromptShownKey)
        // BillingViewを開く処理は呼び出し元で実装
    }
    
    func openAppStoreReview() {
        shouldShowReviewPrompt = false
        
        // App Storeレビューを開く（iOS 10.3以降）
        // Apple公式ドキュメントに従い、requestReview()を直接呼び出し
        // システムが適切なタイミングでレビューダイアログを表示する
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadUsageData() {
        totalUsageMinutes = userDefaults.double(forKey: totalUsageKey)
    }
    
    private func saveUsageData() {
        userDefaults.set(totalUsageMinutes, forKey: totalUsageKey)
    }
    
    // MARK: - Reset (for testing)
    
    func resetUsageData() {
        totalUsageMinutes = 0.0
        userDefaults.removeObject(forKey: totalUsageKey)
        userDefaults.removeObject(forKey: billingPromptShownKey)
        userDefaults.removeObject(forKey: reviewPromptShownKey)
        userDefaults.removeObject(forKey: lastReviewPromptDateKey)
    }
}
