//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import StoreKit

struct CriptionPlusView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var subscriptionManager = SubCriptionManager.shared
    @State private var selectedPlanIndex = 1 // Default to monthly
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let localization = CriptionPlusViewLocalization.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Plan Selection
                    planSelectionView
                    
                    // Features List
                    featuresView
                    
                    // Privacy & Terms Links
                    privacyTermsLinks
                    
                    // Upgrade Button
                    upgradeButton
                    
                    // Terms
                    termsView
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
        .alert(localization.purchaseError(), isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var availablePlans: [CriptionPlusPlan] {
        [
            CriptionPlusPlan(
                id: "weekly",
                title: localization.weekly(),
                price: "$10.00",
                period: localization.perWeek(),
                description: localization.weeklyDescription(),
                productID: "Cription.plus.weekly"
            ),
            CriptionPlusPlan(
                id: "monthly",
                title: localization.monthly(),
                price: "$30.00",
                period: localization.perMonth(),
                description: localization.monthlyDescription(),
                productID: "Cription.plus.monthly"
            ),
            CriptionPlusPlan(
                id: "yearly",
                title: localization.yearly(),
                price: "$300.00",
                period: localization.perYear(),
                description: localization.yearlyDescription(),
                productID: "Cription.plus.yearly"
            )
        ]
    }
    
    private var selectedPlan: CriptionPlusPlan {
        availablePlans[selectedPlanIndex]
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
            }
            
            // Title
            VStack(spacing: 8) {
                Text(localization.title())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(localization.subtitle())
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var planSelectionView: some View {
        VStack(spacing: 16) {
            Text(localization.choosePlan())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            TabView(selection: $selectedPlanIndex) {
                ForEach(Array(availablePlans.enumerated()), id: \.element.id) { index, plan in
                    PlanCardView(plan: plan, isSelected: selectedPlanIndex == index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 200)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<availablePlans.count, id: \.self) { index in
                    Circle()
                        .fill(selectedPlanIndex == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private var featuresView: some View {
        VStack(spacing: 0) {
            // Feature rows
            FeatureRowView(
                title: localization.liveTranscription(),
                description: localization.liveTranscriptionDesc(),
                isIncluded: true
            )
            
            FeatureRowView(
                title: localization.languageTranslation(),
                description: localization.languageTranslationDesc(),
                isIncluded: true
            )

            FeatureRowView(
                title: localization.offlineTranscription(),
                description: localization.offlineTranscriptionDesc(),
                isIncluded: true
            )
            
            FeatureRowView(
                title: localization.fileTranscription(),
                description: localization.fileTranscriptionDesc(),
                isIncluded: true
            )
            
            FeatureRowView(
                title: localization.fileTranslation(),
                description: localization.fileTranslationDesc(),
                isIncluded: true
            )
            
            FeatureRowView(
                title: localization.exportTextAudio(),
                description: localization.exportTextAudioDesc(),
                isIncluded: true
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
        )
    }
    
    private var privacyTermsLinks: some View {
        HStack(spacing: 16) {
            Button(action: {
                openURL("https://cription-website.vercel.app/privacy")
            }) {
                Text(localization.privacyPolicy())
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .underline()
            }
            
            Text("•")
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
            
            Button(action: {
                openURL("https://cription-website.vercel.app/terms")
            }) {
                Text(localization.termsOfUse())
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .underline()
            }
        }
    }
    
    private var upgradeButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await purchaseSelectedPlan()
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isPurchasing ? localization.processing() : localization.upgradeButton(price: selectedPlan.price))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPurchasing ? Color.accentColor.opacity(0.6) : Color.accentColor)
                )
            }
            .disabled(isPurchasing)
            
            Text(localization.autoRenews(period: selectedPlan.period))
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
        }
    }
    
    private var termsView: some View {
        VStack(spacing: 8) {
            Text(localization.termsAgreement())
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSelectedPlan() async {
        isPurchasing = true
        errorMessage = ""
        
        do {
            guard let product = subscriptionManager.availableProducts.first(where: { $0.id == selectedPlan.productID }) else {
                throw SubCriptionError.productNotFound
            }
            
            try await subscriptionManager.purchaseProduct(product)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isPurchasing = false
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

struct FeatureRowView: View {
    let title: String
    let description: String
    let isIncluded: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Checkmark
            Image(systemName: isIncluded ? "checkmark" : "minus")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isIncluded ? .accentColor : (themeManager.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.3)))
                .frame(width: 20, height: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Supporting Views

struct CriptionPlusPlan {
    let id: String
    let title: String
    let price: String
    let period: String
    let description: String
    let productID: String
}

struct PlanCardView: View {
    let plan: CriptionPlusPlan
    let isSelected: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(plan.price)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text(plan.period)
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            Text(plan.description)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.02)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    CriptionPlusView()
        .environmentObject(ThemeManager.shared)
}
