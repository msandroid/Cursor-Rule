//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI

struct ModelsTabView: View {
    @EnvironmentObject var modelManager: WhisperModelManager
    @State private var selectedSection: ModelSection = .local
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var modelPurchaseManager = ModelPurchaseManager()
    @State private var showingPurchaseAlert = false
    @State private var purchaseError: String?
    @State private var selectedModelForPurchase: WhisperModel?
    
    enum ModelSection: String, CaseIterable {
        case local = "Local Models"
        case cloud = "Cloud Models"
        case streaming = "Streaming Models"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerView
                modelSectionsView
            }
            .padding(.bottom, 24)
        }
        .alert(String(localized: LocalizedStringResource("Purchase Error", comment: "Purchase error alert title")), isPresented: $showingPurchaseAlert) {
            Button(String(localized: LocalizedStringResource("OK", comment: "OK button text"))) { }
        } message: {
            Text(purchaseError ?? String(localized: LocalizedStringResource("Unknown error occurred", comment: "Unknown error message")))
        }
        .alert(String(localized: LocalizedStringResource("Purchase Model", comment: "Purchase model button text")), isPresented: .constant(selectedModelForPurchase != nil)) {
            Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button text"))) {
                selectedModelForPurchase = nil
            }
            Button(String(localized: LocalizedStringResource("Purchase", comment: "Purchase button text"))) {
                if let model = selectedModelForPurchase {
                    Task {
                        await purchaseModel(model)
                    }
                }
            }
        } message: {
            if let model = selectedModelForPurchase {
                Text(String(localized: "Purchase \(model.displayName) for enhanced transcription accuracy?"))
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: LocalizedStringResource("Available Models", comment: "Available models section title")))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    // MARK: - Model Sections View
    private var modelSectionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("Model Types", comment: "Model types section title")))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .padding(.horizontal, 24)
            
            sectionSelectorView
            modelsGridView
        }
    }
    
    // MARK: - Section Selector View
    private var sectionSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ModelSection.allCases, id: \.self) { section in
                    sectionButton(for: section)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Section Button
    private func sectionButton(for section: ModelSection) -> some View {
        let isSelected = selectedSection == section
        let textColor = isSelected ? Color.black : (themeManager.isDarkMode ? Color.white : Color.black)
        let backgroundColor = isSelected ? Color.white : Color.clear
        let strokeColor = themeManager.isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
        
        return Button(action: {
            selectedSection = section
        }) {
            Text(section.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    backgroundColor,
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(strokeColor, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Models Grid View
    private var modelsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(getModelsForSection(selectedSection), id: \.id) { model in
                ModelCard(
                    model: model,
                    isPurchased: modelPurchaseManager.isModelPurchased(model.id),
                    canUse: modelPurchaseManager.canUseModel(model.id),
                    onPurchase: {
                        selectedModelForPurchase = model
                    }
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Model Section Logic
    private func getModelsForSection(_ section: ModelSection) -> [WhisperModel] {
        switch section {
        case .local:
            // ローカルモデル（basicEnglishカテゴリのモデル）
            return WhisperModels.shared.allModels.filter { $0.category == .basicEnglish }
        case .cloud:
            // クラウドモデル（OpenAIモデルとWhisper V3 Turbo）
            return WhisperModels.shared.allModels.filter { 
                $0.category == .openaiTranCription && $0.id != "whisper-v3-turbo"
            }
        case .streaming:
            // ストリーミングモデル（FireworksモデルとWhisper V3 Turbo）
            return WhisperModels.shared.allModels.filter { 
                $0.category == .fireworksASR || $0.id == "whisper-v3-turbo"
            }
        }
    }
    
    // MARK: - Purchase Logic
    private func purchaseModel(_ model: WhisperModel) async {
        guard let productID = modelPurchaseManager.getModelProductID(for: model.id) else {
            purchaseError = String(localized: LocalizedStringResource("Product not found for this model", comment: "Product not found error message"))
            showingPurchaseAlert = true
            selectedModelForPurchase = nil
            return
        }
        
        do {
            try await modelPurchaseManager.purchaseModel(productID: productID)
            selectedModelForPurchase = nil
        } catch {
            purchaseError = error.localizedDescription
            showingPurchaseAlert = true
            selectedModelForPurchase = nil
        }
    }
}

struct TokenInfoRow: View {
    let icon: String
    let title: String
    let deCription: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(deCription)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct ModelCard: View {
    let model: WhisperModel
    let isPurchased: Bool
    let canUse: Bool
    let onPurchase: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if model.category == .openaiTranCription || model.id == "whisper-v3-turbo" {
                    // OpenAIアイコンを表示
                    Image("openai-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else if model.category == .fireworksASR {
                    Image("fireworks-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else if model.category == .parakeetASR {
                    Image("cription-icon-black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image("cription-icon-black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                
                Spacer()
                
                if !model.specialFeatures.isEmpty {
                    ForEach(model.specialFeatures, id: \.self) { feature in
                        Text(feature.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("006337"), in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(model.deCription)
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                
                HStack {
                    Spacer()
                    
                    Text(model.languages)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                }
                
                // Pricing Information
                VStack(alignment: .leading, spacing: 2) {
                    if canUse {
                        if isPurchased {
                            Text(String(localized: LocalizedStringResource("Purchased", comment: "Purchased status label")))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        } else {
                            Text(String(localized: LocalizedStringResource("Cription Core - Free", comment: "Cription Core free label")))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("006337"))
                        }
                    } else {
                        Text(String(localized: LocalizedStringResource("Purchase Required", comment: "Purchase required status label")))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.top, 4)
                
                if let quantization = model.quantization {
                    Text(quantization.deCription)
                        .font(.caption2)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                        .padding(.top, 2)
                }
            }
            
            // Purchase Button (OpenAI models and Whisper V3 Turbo don't show purchase button)
            if !canUse && model.category != .openaiTranCription && model.id != "whisper-v3-turbo" {
                Button(action: onPurchase) {
                    Text(String(localized: LocalizedStringResource("Purchase Model", comment: "Purchase model button text")))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canUse ? Color.white.opacity(0.1) : Color.accentColor.opacity(0.3), lineWidth: canUse ? 1 : 2)
        )
    }
}
