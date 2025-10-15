//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI


struct ModelSelectionView: View {
    @ObservedObject var modelManager: WhisperModelManager
    @EnvironmentObject var transcriptionServiceManager: TranCriptionServiceManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ModelCategory? = nil
    
    var filteredModels: [WhisperModel] {
        // 利用可能なモデルのみを取得
        var availableModelIds: [String] = []
        
        // ローカルモデル（バンドル済みまたはダウンロード済み）
        availableModelIds.append(contentsOf: modelManager.localModels)
        
        // クラウドモデル（APIキーが設定されているもののみ）
        
        // OpenAIモデル（APIキーが設定されている場合）
        if transcriptionServiceManager.hasValidAPIKey() {
            availableModelIds.append("whisper-1")
            availableModelIds.append("gpt-4o-transcribe")
            availableModelIds.append("gpt-4o-mini-transcribe")
        }
        
        // Fireworksモデル（APIキーが設定されている場合）
        if transcriptionServiceManager.hasValidFireworksAPIKey() {
            availableModelIds.append("fireworks-asr-large")
            availableModelIds.append("fireworks-asr-v2")
            availableModelIds.append("whisper-v3")
            availableModelIds.append("whisper-v3-turbo")
        }
        
        // 利用可能なモデルのみをフィルタリング
        var models = WhisperModels.shared.allModels.filter { availableModelIds.contains($0.id) }
        
        // Filter by category
        if let category = selectedCategory {
            models = models.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            models = models.filter { model in
                model.displayName.localizedCaseInsensitiveContains(searchText) ||
                model.id.localizedCaseInsensitiveContains(searchText) ||
                model.deCription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return models
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Controls
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(String(localized: LocalizedStringResource("Search models...", comment: "Search models placeholder")), text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(
                                title: String(localized: LocalizedStringResource("All", comment: "All category filter")),
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(ModelCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                }
                .padding()
                .background(Color.clear)
                
                Divider()
                    .padding(.horizontal)
                
                // Models List
                if filteredModels.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(String(localized: LocalizedStringResource("No Models Found", comment: "No models found message")))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(String(localized: LocalizedStringResource("Try adjusting your search criteria", comment: "No models found suggestion")))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredModels, id: \.id) { model in
                            ModelRowView(
                                model: model,
                                isSelected: model.id == modelManager.selectedModel,
                                onTap: {
                                    modelManager.selectModel(model.id)
                                    dismiss()
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(String(localized: LocalizedStringResource("Select Model", comment: "Select model title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Model Row View
struct ModelRowView: View {
    let model: WhisperModel
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var subscriptionManager = SubCriptionManager.shared
    
    private var isModelAccessible: Bool {
        // OpenAIモデルはサブスクリプションチェック済み
        if model.id == "whisper-1" || model.id.contains("gpt-4o") {
            return subscriptionManager.canUseCloudModel(model.id)
        }
        
        // バンドルモデルは常にアクセス可能（無料）
        let bundleModels = ["openai_whisper-tiny.en", "openai_whisper-base", "openai_whisper-base.en"]
        if bundleModels.contains(model.id) {
            return true
        }
        
        // その他のモデルは有料サブスクリプション必須
        return subscriptionManager.isSubCriptiond
    }
    
    var body: some View {
        Button(action: {
            if isModelAccessible {
                onTap()
            }
        }) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Model Icon
                    if model.category == .openaiTranCription {
                        Image(systemName: "cloud.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else if model.category == .fireworksASR {
                        Image("fireworks-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else if model.category == .parakeetASR {
                        Image("cription-icon-black")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else {
                        Image("cription-icon-black")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    
                    // Model Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(model.displayName)
                                .font(.headline)
                                .foregroundColor(isModelAccessible ? .primary : .secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if !isModelAccessible {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        Text(model.deCription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if !isModelAccessible {
                            Text("Subscription required")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }
                    }
                }
                
                // Tags
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 8)
                ], spacing: 8) {
                    ModelTag(text: model.size, color: Color("1CA485"))
                    ModelTag(text: model.languages, color: .green)
                    
                    if let quantization = model.quantization {
                        ModelTag(text: quantization.rawValue, color: .accentColor)
                    }
                    
                    ForEach(model.specialFeatures, id: \.self) { feature in
                        ModelTag(text: feature.rawValue, color: .orange)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .opacity(isModelAccessible ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isModelAccessible)
    }
}

// MARK: - Model Tag
struct ModelTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

#Preview {
    ModelSelectionView(modelManager: WhisperModelManager())
}
