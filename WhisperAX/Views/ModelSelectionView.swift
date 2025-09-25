//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI


struct ModelSelectionView: View {
    @ObservedObject var modelManager: WhisperModelManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ModelCategory? = nil
    @State private var showRecommendedOnly = false
    
    var filteredModels: [WhisperModel] {
        var models = WhisperModels.shared.allModels
        
        // Filter by category
        if let category = selectedCategory {
            models = models.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            models = models.filter { model in
                model.displayName.localizedCaseInsensitiveContains(searchText) ||
                model.id.localizedCaseInsensitiveContains(searchText) ||
                model.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by recommended only
        if showRecommendedOnly {
            let recommendedIds = Set(WhisperModels.shared.getRecommendedModels().map { $0.id })
            models = models.filter { recommendedIds.contains($0.id) }
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
                        TextField("Search models...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(
                                title: "All",
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
                    
                    // Recommended Toggle
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text("Show Recommended Only")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $showRecommendedOnly)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                    .padding(.horizontal)
                
                // Models List
                if filteredModels.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Models Found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try adjusting your search criteria")
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
            .navigationTitle("Select Model")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
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
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Model Icon
                    VStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Model Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(model.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        Text(model.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Tags
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 8)
                ], spacing: 8) {
                    ModelTag(text: model.size, color: Color("1CA485"))
                    ModelTag(text: model.languages, color: .green)
                    
                    if let quantization = model.quantization {
                        ModelTag(text: quantization.rawValue, color: .purple)
                    }
                    
                    ForEach(model.specialFeatures, id: \.self) { feature in
                        ModelTag(text: feature.rawValue, color: .orange)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
