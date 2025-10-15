//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import StoreKit

struct CreditPurchaseView: View {
    @StateObject private var creditManager = CreditManager.shared
    @StateObject private var subscriptionManager = SubCriptionManager.shared
    @State private var showingPurchaseAlert = false
    @State private var purchaseError: String?
    @State private var isRestoring = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    private let creditPackages = [
        CreditPackage(id: "Cription.credits.22", title: String(localized: LocalizedStringResource("15 Credits", comment: "15 credits package name")), price: String(localized: LocalizedStringResource("$19.99", comment: "19.99 price")), credits: 15.0, description: String(localized: LocalizedStringResource("Perfect for trying out our services", comment: "15 credits description"))),
        CreditPackage(id: "Cription.credits.55", title: String(localized: LocalizedStringResource("38 Credits", comment: "38 credits package name")), price: String(localized: LocalizedStringResource("$49.99", comment: "49.99 price")), credits: 38.0, description: String(localized: LocalizedStringResource("Great for regular usage", comment: "38 credits description"))),
        CreditPackage(id: "Cription.credits.110", title: String(localized: LocalizedStringResource("77 Credits", comment: "77 credits package name")), price: String(localized: LocalizedStringResource("$99.99", comment: "99.99 price")), credits: 77.0, description: String(localized: LocalizedStringResource("Best value for frequent users", comment: "77 credits description"))),
        CreditPackage(id: "Cription.credits.220", title: String(localized: LocalizedStringResource("154 Credits", comment: "154 credits package name")), price: String(localized: LocalizedStringResource("$199.99", comment: "199.99 price")), credits: 154.0, description: String(localized: LocalizedStringResource("Maximum value for power users", comment: "154 credits description"))),
        CreditPackage(id: "Cription.credits.1100", title: String(localized: LocalizedStringResource("769 Credits", comment: "769 credits package name")), price: String(localized: LocalizedStringResource("$999.99", comment: "999.99 price")), credits: 769.0, description: String(localized: LocalizedStringResource("Ultimate package for heavy usage", comment: "769 credits description")))
    ]
    
    var currentCreditsSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: LocalizedStringResource("Current Credits", comment: "Current credits section title")))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(String(format: "%.1f", creditManager.currentCredits))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(String(localized: LocalizedStringResource("credits", comment: "Credits unit label")))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                    .font(.caption)
                
                Text(String(localized: LocalizedStringResource("Available for cloud model usage", comment: "Cloud model usage description")))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    var subscriptionStatusSection: some View {
        if subscriptionManager.subCriptionTier == .free {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(String(localized: LocalizedStringResource("Subscription Status", comment: "Subscription status section title")))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(subscriptionManager.subCriptionTier.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(String(localized: LocalizedStringResource("Free users need credits to use cloud models", comment: "Free user credit requirement message")))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    var creditPackagesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(String(localized: LocalizedStringResource("Purchase Credits", comment: "Purchase credits section title")))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(localized: LocalizedStringResource("Choose a package", comment: "Package selection instruction")))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                ForEach(creditPackages, id: \.id) { package in
                    CreditPackageCard(
                        package: package,
                        isLoading: creditManager.isLoading,
                        onPurchase: {
                            await purchaseCredits(package: package)
                        }
                    )
                }
            }
        }
    }
    
    var creditUsageInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                
                Text(String(localized: LocalizedStringResource("How Credits Work", comment: "Credits explanation section title")))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                CreditInfoRow(icon: "dollarsign.circle.fill", text: String(localized: LocalizedStringResource("1 credit = $1.30 (統一価格)", comment: "Credit value explanation")), color: .green)
                CreditInfoRow(icon: "waveform", text: String(localized: LocalizedStringResource("1 credit ≈ 217 minutes of Whisper-1 transcription", comment: "Whisper-1 credit usage explanation")), color: .accentColor)
                CreditInfoRow(icon: "waveform", text: String(localized: LocalizedStringResource("1 credit ≈ 108 minutes of GPT-4o Transcribe", comment: "GPT-4o credit usage explanation")), color: .accentColor)
                CreditInfoRow(icon: "waveform", text: String(localized: LocalizedStringResource("1 credit ≈ 163 minutes of GPT-4o Mini Transcribe", comment: "GPT-4o Mini credit usage explanation")), color: .accentColor)
                CreditInfoRow(icon: "text.bubble", text: String(localized: LocalizedStringResource("1 credit ≈ 1,300 text translation requests", comment: "Text translation credit usage explanation")), color: .accentColor)
                CreditInfoRow(icon: "cloud.fill", text: String(localized: LocalizedStringResource("Credits are consumed only for cloud models", comment: "Cloud model credit consumption explanation")), color: .gray)
                CreditInfoRow(icon: "checkmark.circle.fill", text: String(localized: LocalizedStringResource("Bundle models (whisper-base, whisper-small, whisper-tiny) are free", comment: "Bundle models free explanation")), color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                currentCreditsSection
                
                subscriptionStatusSection
                
                creditPackagesSection
                
                Spacer()
                
                // Restore Purchases Button
                restorePurchasesButton
                
                creditUsageInfoSection
            }
            .padding()
            .navigationTitle(String(localized: LocalizedStringResource("Credits", comment: "Credits title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .alert(String(localized: LocalizedStringResource("Purchase Error", comment: "Purchase error alert title")), isPresented: $showingPurchaseAlert) {
                Button(String(localized: LocalizedStringResource("OK", comment: "OK button text"))) { }
            } message: {
                Text(purchaseError ?? String(localized: LocalizedStringResource("Unknown error occurred", comment: "Unknown error message")))
            }
            .alert(String(localized: LocalizedStringResource("Restore Purchases", comment: "Restore purchases button text")), isPresented: $showingRestoreAlert) {
                Button(String(localized: LocalizedStringResource("OK", comment: "OK button text"))) { }
            } message: {
                Text(restoreMessage)
            }
        }
        }
    
    private func purchaseCredits(package: CreditPackage) async {
        do {
            try await creditManager.purchaseCredits(productID: package.id)
        } catch {
            purchaseError = error.localizedDescription
            showingPurchaseAlert = true
        }
    }
    
    // MARK: - Restore Purchases Button
    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                await restorePurchases()
            }
        }) {
            HStack(spacing: 8) {
                if isRestoring {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.primary)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text(String(localized: LocalizedStringResource("Restore Purchases", comment: "Restore purchases button text")))
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
        }
        .disabled(isRestoring)
    }
    
    // MARK: - Restore Logic
    private func restorePurchases() async {
        isRestoring = true
        
        let success = await subscriptionManager.restorePurchasesWithProgress()
        
        if success {
            restoreMessage = String(localized: LocalizedStringResource("Purchases restored successfully!", comment: "Purchases restored success message"))
        } else {
            restoreMessage = String(localized: LocalizedStringResource("No purchases found to restore or restore failed.", comment: "No purchases found message"))
        }
        
        showingRestoreAlert = true
        isRestoring = false
    }
}

struct CreditPackage {
    let id: String
    let title: String
    let price: String
    let credits: Double
    let description: String
}

struct CreditPackageCard: View {
    let package: CreditPackage
    let isLoading: Bool
    let onPurchase: () async -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.0f", package.credits)) credits")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
            }
            
            // Price section
            VStack(alignment: .leading, spacing: 4) {
                Text(package.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            // Description
            Text(package.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Purchase button
            Button(action: {
                Task {
                    await onPurchase()
                }
            }) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(String(localized: LocalizedStringResource("Purchase", comment: "Purchase button text")))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(isLoading)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
        }
        .padding(20)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct CreditInfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    CreditPurchaseView()
}
