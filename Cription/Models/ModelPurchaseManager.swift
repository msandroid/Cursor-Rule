//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit

@MainActor
class ModelPurchaseManager: ObservableObject {
    static let shared = ModelPurchaseManager()
    
    @Published var isLoading = false
    @Published var availableProducts: [Product] = []
    @Published var purchasedModels: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let purchasedModelsKey = "PurchasedModels"
    
    // モデル購入用のプロダクトID
    private let modelProductIDs: Set<String> = [
        "Cription.model.Cription.mini",
        "Cription.model.Cription.Pro", 
        "Cription.model.Cription.Enterprise",
        "Cription.model.Cription.Ultra",
        "Cription.model.Cription.Ultra.v3"
    ]
    
    init() {
        loadPurchasedModels()
        Task {
            await loadProducts()
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: modelProductIDs)
            availableProducts = products.sorted { $0.displayPrice < $1.displayPrice }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Logic
    
    func purchaseModel(productID: String) async throws {
        guard let product = availableProducts.first(where: { $0.id == productID }) else {
            throw ModelPurchaseError.productNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            guard let transaction = await unwrapVerificationResult(verification) else {
                throw ModelPurchaseError.unverified
            }
            
            await transaction.finish()
            
            // 購入済みモデルに追加
            addPurchasedModel(productID)
            
        case .userCancelled:
            throw ModelPurchaseError.userCancelled
            
        case .pending:
            throw ModelPurchaseError.pending
            
        @unknown default:
            throw ModelPurchaseError.unknown
        }
    }
    
    // MARK: - Model Access
    
    func isModelPurchased(_ modelID: String) -> Bool {
        return purchasedModels.contains(modelID)
    }
    
    func canUseModel(_ modelID: String) -> Bool {
        // Cription miniは無料で利用可能
        if modelID.contains("mini") || modelID.contains("tiny") {
            return true
        }
        
        // その他のモデルは購入が必要
        return isModelPurchased(modelID)
    }
    
    func getModelProductID(for modelID: String) -> String? {
        // モデルIDからプロダクトIDを生成
        let modelMapping: [String: String] = [
            "openai_whisper-base": "Cription.model.Cription.mini",
            "openai_whisper-small": "Cription.model.Cription.Pro",
            "openai_whisper-medium": "Cription.model.Cription.Enterprise",
            "openai_whisper-large-v2": "Cription.model.Cription.Ultra",
            "openai_whisper-large-v3": "Cription.model.Cription.Ultra.v3"
        ]
        return modelMapping[modelID]
    }
    
    // MARK: - Private Methods
    
    private func addPurchasedModel(_ productID: String) {
        purchasedModels.insert(productID)
        savePurchasedModels()
    }
    
    private func loadPurchasedModels() {
        if let data = userDefaults.data(forKey: purchasedModelsKey),
           let models = try? JSONDecoder().decode(Set<String>.self, from: data) {
            purchasedModels = models
        }
    }
    
    private func savePurchasedModels() {
        if let data = try? JSONEncoder().encode(purchasedModels) {
            userDefaults.set(data, forKey: purchasedModelsKey)
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
}

// MARK: - Model Purchase Errors

enum ModelPurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case unverified
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .unverified:
            return "Purchase verification failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
