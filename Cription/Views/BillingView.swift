//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import Charts

struct BillingView: View {
    @StateObject private var usageDataManager = UsageDataManager()
    @StateObject private var creditManager = CreditManager.shared
    @StateObject private var subscriptionManager = SubCriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedDateRange = DateRange()
    @State private var showingExportSheet = false
    @State private var showingSubscriptionSheet = false
    @State private var showingCreditPurchaseSheet = false
    @State private var showingCriptionPlusView = false
    
    enum TimeRange: String, CaseIterable {
        case day = "1d"
        case week = "7d"
        case month = "30d"
        case year = "1y"
    }
    
    struct DateRange {
        var startDate = Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date()
        var endDate = Date()
    }
    
    // 実際のデータとサンプルデータを組み合わせた使用量データ
    private var sampleUsageData: [DailyUsage] {
        let calendar = Calendar.current
        var data: [DailyUsage] = []
        
        // 実際のAnalyticsManagerのデータを使用
        let actualTokens = analyticsManager.totalTokens
        let actualTranscriptions = analyticsManager.totalTranCriptions
        
        // 過去15日間のデータを生成（実際のデータに基づく）
        for i in 0..<15 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // 実際のデータから日別の使用量を推定
            let dayTokens = i < 2 ? actualTokens / 15 : 0
            let dayRequests = i < 2 ? actualTranscriptions / 15 : 0
            let cost = Double(dayTokens) * 0.00001 // 1トークンあたりのコスト
            
            data.append(DailyUsage(
                date: date,
                tokens: dayTokens,
                cost: cost,
                requests: dayRequests
            ))
        }
        
        return data.reversed()
    }
    
    private var totalSpend: Double {
        sampleUsageData.reduce(0) { $0 + $1.cost }
    }
    
    private var totalTokens: Int {
        analyticsManager.totalTokens
    }
    
    private var totalRequests: Int {
        analyticsManager.totalTranCriptions
    }
    
    private var maxCost: Double {
        max(sampleUsageData.map { $0.cost }.max() ?? 0, 0.1)
    }
    
    private var previousPeriodSpend: Double {
        0.17 // 画像の値に合わせる
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Subscription Status Card
                subscriptionStatusCard
                
                // Main Content - Single column layout for simplicity
                VStack(alignment: .leading, spacing: 24) {
                    totalSpendSection
                    mainChartSection
                    budgetSection
                    creditSection
                    tokensSection
                    requestsSection
                    apiUsageSection
                    subscriptionPlansSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .background(themeManager.isDarkMode ? Color.black : Color.white)
        .onAppear {
            // データを更新
            analyticsManager.updateActiveModels()
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            SubscriptionManagementView()
        }
        .fullScreenCover(isPresented: $showingCreditPurchaseSheet) {
            NavigationView {
                CreditPurchaseView()
            }
        }
        .fullScreenCover(isPresented: $showingCriptionPlusView) {
            CriptionPlusView()
        }
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    headerSection
                    planInfoSection
                    usageSection
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 16)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Current Plan")
                .font(.headline)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            Button("Manage") {
                showingSubscriptionSheet = true
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                Text(subscriptionManager.subCriptionTier.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                if subscriptionManager.subCriptionTier != .free {
                    Text("Active")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                } else {
                    Text("Free")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
            
            Text(getCurrentPlanDescription())
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
        }
    }
    
    private var usageSection: some View {
        Group {
            if subscriptionManager.subCriptionTier == .free {
                VStack(alignment: .leading, spacing: 8) {
                    let usageLimit = subscriptionManager.subCriptionTier.monthlyUsageLimit == -1 ? "∞" : "\(subscriptionManager.subCriptionTier.monthlyUsageLimit)"
                    Text("Usage: \(subscriptionManager.remainingUsage) / \(usageLimit) minutes")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    if subscriptionManager.remainingUsage <= 0 && subscriptionManager.subCriptionTier != .free {
                        Button("Upgrade") {
                            showingSubscriptionSheet = true
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("Usage")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            // Controls - Simplified layout
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Export
                    Button(action: { showingExportSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.body)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            
                            Text("Export")
                                .font(.body)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                    }
                    
                    Spacer()
                }
                
                // Date Range - Simplified
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                    
                    Text("Last 15 days")
                        .font(.body)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Total Spend Section
    
    private var totalSpendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Spend")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            HStack(alignment: .bottom, spacing: 12) {
                Text("$\(String(format: "%.2f", totalSpend))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text("vs $\(String(format: "%.2f", previousPeriodSpend))")
                    .font(.body)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    // MARK: - Main Chart Section
    
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Group by selector - Simplified
            HStack {
                Text("Daily")
                    .font(.body)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                
                Spacer()
            }
            
            // Chart Container
            VStack(spacing: 0) {
                // Reference line (horizontal dashed line)
                HStack {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 1)
                        .opacity(0.4)
                        .overlay(
                            Rectangle()
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .opacity(0.4)
                        )
                    
                    Spacer()
                }
                .frame(height: 20)
                
                // Bar Chart
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(sampleUsageData, id: \.date) { data in
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 16, height: max(2, CGFloat(data.cost / maxCost) * 140))
                                .cornerRadius(1)
                            
                            Text(formatDate(data.date))
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                                .padding(.top, 6)
                        }
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Credit Section
    
    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Credits")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Button("Buy Credits") {
                    showingCreditPurchaseSheet = true
                }
                .font(.body)
                .foregroundColor(.accentColor)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(String(format: "%.1f", creditManager.currentCredits))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text("credits")
                    .font(.body)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
            }
        }
    }
    
    // MARK: - API Usage Section
    
    private var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Models")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            // Model usage breakdown - Simplified
            VStack(spacing: 8) {
                ForEach(["gpt-4o-mini-transcribe", "gpt-4o-transcribe", "whisper-1"], id: \.self) { model in
                    simplifiedModelCard(model)
                }
            }
        }
    }
    
    private func simplifiedModelCard(_ model: String) -> some View {
        HStack {
            Text(model)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            if subscriptionManager.canUseCloudModel(model) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.subheadline)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
        )
    }
    
    // MARK: - Subscription Plans Section
    
    private var subscriptionPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Plans")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Text(subscriptionManager.subCriptionTier.displayName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
            }
            
            VStack(spacing: 12) {
                // Free Plan
                subscriptionPlanCard(
                    title: "Free Plan",
                    price: "Free",
                    features: [
                        "10 minutes/month",
                        "Basic transcription",
                        "Standard quality"
                    ],
                    isCurrent: subscriptionManager.subCriptionTier == .free
                )
                
                // Plus Plan (Weekly/Pro equivalent)
                subscriptionPlanCard(
                    title: "Plus Plan",
                    price: "$20.00/month",
                    features: [
                        "300 minutes/month",
                        "High precision transcription",
                        "100+ languages support",
                        "Custom vocabulary"
                    ],
                    isCurrent: subscriptionManager.subCriptionTier == .weekly || subscriptionManager.subCriptionTier == .monthly
                )
                
                
                // Credit Packages
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credit Packages")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    VStack(spacing: 8) {
                        creditPackageCard("15 Credits", "$19.99", "~1,071 min", credits: 15.0, price: 19.99)
                        creditPackageCard("38 Credits", "$49.99", "~2,714 min", credits: 38.0, price: 49.99)
                        creditPackageCard("77 Credits", "$99.99", "~5,500 min", credits: 77.0, price: 99.99)
                        creditPackageCard("154 Credits", "$199.99", "~11,000 min", credits: 154.0, price: 199.99)
                        creditPackageCard("769 Credits", "$999.99", "~54,929 min", credits: 769.0, price: 999.99)
                    }
                }
            }
        }
    }
    
    private func subscriptionPlanCard(title: String, price: String, features: [String], isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                }
                
                Spacer()
                
                if isCurrent {
                    Text("Current")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                } else {
                    Button("Upgrade") {
                        if title == "Plus Plan" {
                            showingCriptionPlusView = true
                        } else {
                            showingSubscriptionSheet = true
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
        )
    }
    
    private func creditPackageCard(_ name: String, _ priceString: String, _ minutes: String, credits: Double, price: Double) -> some View {
        Button(action: {
            // クレジット購入ページを表示
            showingCreditPurchaseSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text(minutes)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.accentColor)
                    
                    Text("Tap to buy")
                        .font(.caption)
                        .foregroundColor(Color.accentColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Budget Section
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("$\(String(format: "%.2f", totalSpend))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text("/ $50")
                    .font(.body)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * (totalSpend / 50.0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 8)
            
            Text("Resets in 22 days")
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
        }
    }
    
    // MARK: - Tokens Section
    
    private var tokensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Tokens")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Text("\(formatTokens(totalTokens))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            // Mini line chart
            GeometryReader { geometry in
                Path { path in
                    let stepX = geometry.size.width / CGFloat(sampleUsageData.count - 1)
                    let maxTokens = sampleUsageData.map { $0.tokens }.max() ?? 1
                    
                    for (index, data) in sampleUsageData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (CGFloat(data.tokens) / CGFloat(maxTokens) * geometry.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
                
                // Data point
                if let lastData = sampleUsageData.last {
                    let stepX = geometry.size.width / CGFloat(sampleUsageData.count - 1)
                    let maxTokens = sampleUsageData.map { $0.tokens }.max() ?? 1
                    let x = CGFloat(sampleUsageData.count - 1) * stepX
                    let y = geometry.size.height - (CGFloat(lastData.tokens) / CGFloat(maxTokens) * geometry.size.height)
                    
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 4, height: 4)
                        .position(x: x, y: y)
                }
            }
            .frame(height: 40)
        }
    }
    
    // MARK: - Requests Section
    
    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Requests")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Text("\(totalRequests)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            // Mini bar chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(sampleUsageData, id: \.date) { data in
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: max(2, CGFloat(data.requests) / 50.0 * 30))
                        .cornerRadius(1)
                }
            }
            .frame(height: 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentPlanDescription() -> String {
        switch subscriptionManager.subCriptionTier {
        case .free:
            return "10 min/month • Basic"
        case .weekly:
            return "300 min/month • Premium"
        case .monthly:
            return "3000 min/month • Premium"
        case .yearly:
            return "Unlimited • All features"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    private func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        } else {
            return "\(tokens)"
        }
    }
}

// MARK: - Data Models

struct DailyUsage {
    let date: Date
    let tokens: Int
    let cost: Double
    let requests: Int
}

// MARK: - Subscription Management View

struct SubscriptionManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubCriptionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Subscription Management")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text("Manage your subscription and billing")
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                
                Spacer()
                
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                
                Spacer()
            }
            .padding()
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BillingView()
        .environmentObject(AnalyticsManager.shared)
}
