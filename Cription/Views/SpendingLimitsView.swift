//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI

struct SpendingLimitsView: View {
    @StateObject private var viewModel = SpendingLimitsViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var tierSystemManager = TierSystemManager.shared
    @State private var showingInfoSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    currentStatusCard
                    
                    // Tier Information
                    tierInformationSection
                    
                    // Available Tiers
                    availableTiersSection
                    
                    // Credit Purchase Section
                    if tierSystemManager.getNextTier() != nil {
                        creditPurchaseSection
                    }
                    
                    // Custom Limit Section
                    customLimitSection
                    
                    // Refresh Button
                    refreshSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationTitle(String(localized: LocalizedStringResource("Spending Limits", comment: "Spending limits view title")))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfoSheet = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    }
                }
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            infoSheet
        }
        .sheet(isPresented: $viewModel.showingCreditPurchaseDialog) {
            creditPurchaseSheet
        }
        .sheet(isPresented: $viewModel.showingCustomLimitDialog) {
            customLimitSheet
        }
    }
    
    // MARK: - Current Status Card
    private var currentStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: LocalizedStringResource("Current Tier", comment: "Current tier label")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.currentTier.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(localized: LocalizedStringResource("Monthly Limit", comment: "Monthly limit label")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.0f", viewModel.currentLimit))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: LocalizedStringResource("This Month", comment: "This month spending label")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", viewModel.currentMonthlySpend)) / $\(String(format: "%.0f", viewModel.currentLimit))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.currentMonthlySpend, total: viewModel.currentLimit)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Historical Spend
            HStack {
                Text(String(localized: LocalizedStringResource("Total Historical Spend", comment: "Historical spend label")))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("$\(String(format: "%.2f", tierSystemManager.historicalSpend))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
            }
            
            // Days since first payment
            if let firstPaymentDate = tierSystemManager.firstPaymentDate {
                HStack {
                    Text(String(localized: LocalizedStringResource("Days since first payment", comment: "Days since first payment label")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let daysSince = Calendar.current.dateComponents([.day], from: firstPaymentDate, to: Date()).day ?? 0
                    Text("\(daysSince) days")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Tier Information Section
    private var tierInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("Spending Tiers", comment: "Spending tiers section title")))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            LazyVStack(spacing: 12) {
                ForEach(tierSystemManager.getAvailableTiers().filter { $0 != .custom }) { tier in
                    tierRow(tier)
                }
            }
        }
    }
    
    private func tierRow(_ tier: SpendingTier) -> some View {
        HStack(spacing: 16) {
            // Tier Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tier.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    if tier == tierSystemManager.currentTier {
                        Text(String(localized: LocalizedStringResource("Current Tier", comment: "Current tier indicator")))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(tier.qualificationText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Monthly Limit
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.0f", tier.monthlyLimit))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(String(localized: LocalizedStringResource("/ month", comment: "Per month label")))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Buy Credits Button
            if tier.canBuyCredits && tier != tierSystemManager.currentTier {
                Button(action: {
                    viewModel.creditAmount = tier.requiredHistoricalSpend - tierSystemManager.historicalSpend
                    viewModel.showingCreditPurchaseDialog = true
                }) {
                    Text(String(localized: LocalizedStringResource("Buy Credits", comment: "Buy credits button")))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Credit Purchase Section
    private var creditPurchaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("Upgrade to Next Tier", comment: "Upgrade section title")))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            if let nextTier = tierSystemManager.getNextTier(),
               let requiredSpend = tierSystemManager.getRequiredSpendForNextTier() {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: LocalizedStringResource("Next Tier", comment: "Next tier label")))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(nextTier.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(localized: LocalizedStringResource("Required Spend", comment: "Required spend label")))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("$\(String(format: "%.2f", requiredSpend))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            // Days requirement
                            if let requiredDays = tierSystemManager.getRequiredDaysForNextTier(), requiredDays > 0 {
                                Text("+ \(requiredDays) days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.creditAmount = requiredSpend
                        viewModel.showingCreditPurchaseDialog = true
                    }) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text(String(localized: LocalizedStringResource("Purchase Credits to Upgrade", comment: "Purchase credits button")))
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Custom Limit Section
    private var customLimitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: LocalizedStringResource("Custom Limit", comment: "Custom limit section title")))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            VStack(spacing: 12) {
                Text(String(localized: LocalizedStringResource("Set a custom spending limit for your account. Contact support for assistance.", comment: "Custom limit description")))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.showingCustomLimitDialog = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text(String(localized: LocalizedStringResource("Set Custom Limit", comment: "Set custom limit button")))
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray)
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
            )
        }
    }
    
    // MARK: - Info Sheet
    private var infoSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(String(localized: LocalizedStringResource("About Spending Limits", comment: "Info sheet title")))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: LocalizedStringResource("How Spending Limits Work", comment: "How limits work section")))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Text(String(localized: LocalizedStringResource("Spending limits restrict how much you can spend on the Fireworks platform per calendar month. The spending limit is determined by your total historical Fireworks spend. You can purchase prepaid credits to immediately increase your historical spend.", comment: "Spending limits explanation")))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: LocalizedStringResource("Tier Qualifications", comment: "Tier qualifications section")))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(SpendingTier.allCases.filter { $0 != .custom }) { tier in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(tier.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(tier.qualificationText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        showingInfoSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Credit Purchase Sheet
    private var creditPurchaseSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(String(localized: LocalizedStringResource("Purchase Credits", comment: "Credit purchase title")))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(String(localized: LocalizedStringResource("Add credits to your account to increase your spending limit tier.", comment: "Credit purchase description")))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Text(String(localized: LocalizedStringResource("Credit Amount", comment: "Credit amount label")))
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", viewModel.creditAmount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: $viewModel.creditAmount, in: 10...10000, step: 10)
                        .accentColor(.blue)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                )
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.purchaseCredits()
                    }
                }) {
                    Text(String(localized: LocalizedStringResource("Purchase Credits", comment: "Purchase credits button")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button"))) {
                        viewModel.showingCreditPurchaseDialog = false
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Limit Sheet
    private var customLimitSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(String(localized: LocalizedStringResource("Set Custom Limit", comment: "Custom limit title")))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(String(localized: LocalizedStringResource("Enter a custom monthly spending limit for your account.", comment: "Custom limit description")))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    TextField(String(localized: LocalizedStringResource("Enter amount", comment: "Amount placeholder")), text: $viewModel.customLimitText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                )
                
                Spacer()
                
                Button(action: {
                    viewModel.setCustomLimit()
                }) {
                    Text(String(localized: LocalizedStringResource("Set Limit", comment: "Set limit button")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button"))) {
                        viewModel.showingCustomLimitDialog = false
                    }
                }
            }
        }
    }
    
    // MARK: - Refresh Section
    private var refreshSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await tierSystemManager.refreshData()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(String(localized: LocalizedStringResource("Refresh Data", comment: "Refresh data button")))
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .disabled(tierSystemManager.isLoading)
            
            if tierSystemManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(String(localized: LocalizedStringResource("Refreshing transaction history...", comment: "Refreshing message")))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = tierSystemManager.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

#Preview {
    SpendingLimitsView()
}
