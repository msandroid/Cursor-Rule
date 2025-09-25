//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI


struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DashboardTab = .overview
    @State private var isSidebarVisible = false
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case models = "Models"
        case history = "History"
        case billing = "Billing"
        case documents = "Documents"
        
        var icon: String {
            switch self {
            case .overview:
                return "chart.bar.xaxis"
            case .models:
                return "square.stack.3d.up.fill"
            case .history:
                return "equal"
            case .billing:
                return "creditcard.circle"
            case .documents:
                return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                contentArea
                sidebarOverlay
                sidebar
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                    isSidebarVisible = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        Group {
            switch selectedTab {
            case .overview:
                OverviewTabView(analyticsManager: analyticsManager)
            case .models:
                ModelsTabView()
            case .history:
                HistoryTabView()
            case .billing:
                BillingTabView()
            case .documents:
                DocumentsTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.isDarkMode ? Color.black : Color.white)
    }
    
    @ViewBuilder
    private var sidebarOverlay: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = true
                    }
                }) {
                    EmptyView()
                }
                .frame(width: 44, height: 44)
                
                Spacer()
            }
            Spacer()
        }
        .overlay(
            Color.black.opacity(isSidebarVisible ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = false
                    }
                }
        )
    }
    
    @ViewBuilder
    private var sidebar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                sidebarHeader
                navigationItems
                Spacer()
                themeToggleButton
            }
            .frame(width: 280)
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .offset(x: isSidebarVisible ? 0 : -280)
            .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(String(localized: LocalizedStringResource("Scribe", comment: "App name")))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder
    private var navigationItems: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSidebarVisible = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            .frame(width: 20)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ? (themeManager.isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.1)) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private var themeToggleButton: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            HStack(spacing: 12) {
                Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .frame(width: 20)
                
                Text(themeManager.isDarkMode ? "Light Mode" : "Dark Mode")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
}

struct OverviewTabView: View {
    @State private var selectedTimeRange: TimeRange = .week
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject var analyticsManager: AnalyticsManager
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Convert token data to display format
    private var tokenData: [(date: String, tokens: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        let daysToShow: Int
        switch selectedTimeRange {
        case .week:
            daysToShow = 7
        case .month:
            daysToShow = 30
        case .year:
            daysToShow = 365
        }
        
        var data: [(date: String, tokens: Int)] = []
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let dayStart = calendar.startOfDay(for: date)
            
            // Find tokens for this day
            let dayTokens = analyticsManager.tokenUsage
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .reduce(0) { $0 + $1.tokens }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = selectedTimeRange == .year ? "MMM" : "MM/dd"
            
            data.append((date: dateFormatter.string(from: date), tokens: dayTokens))
        }
        
        return data.reversed() // Show oldest to newest
    }
    
    private var totalTokens: Int {
        analyticsManager.totalTokens
    }
    
    private var maxTokens: Int {
        analyticsManager.maxTokens
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: LocalizedStringResource("Your Analytics", comment: "Analytics title")))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Token Usage Chart
                VStack(alignment: .leading, spacing: 16) {
                    // Time Range Selector
                    HStack {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                            }) {
                                Text(range.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedTimeRange == range ? (themeManager.isDarkMode ? .white : .black) : (themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6)))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTimeRange == range ? Color("006337") : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Chart Container
                    VStack(alignment: .leading, spacing: 0) {
                        // Total Tokens Display
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(totalTokens.formatted())")
                                    .font(.custom("Lato-ExtraBold", size: 32))
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                
                                Text(String(localized: LocalizedStringResource("Total Tokens", comment: "Total tokens label")))
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Chart Area
                        VStack(spacing: 0) {
                            // Y-axis labels and chart
                            HStack(alignment: .bottom, spacing: 0) {
                                // Y-axis
                                VStack(alignment: .trailing, spacing: 0) {
                                    ForEach((0...4).reversed(), id: \.self) { i in
                                        Text("\(Int(maxTokens * i / 4))")
                                            .font(.caption)
                                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                                            .frame(height: 40)
                                    }
                                }
                                .frame(width: 40)
                                .padding(.trailing, 8)
                                
                                // Chart
                                ZStack {
                                    // Grid lines
                                    VStack(spacing: 0) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 1)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .frame(height: 160)
                                    
                                    // Line chart
                                    GeometryReader { geometry in
                                        let chartWidth = geometry.size.width
                                        let chartHeight = geometry.size.height
                                        let stepX = chartWidth / CGFloat(tokenData.count - 1)
                                        
                                        Path { path in
                                            for (index, data) in tokenData.enumerated() {
                                                let x = CGFloat(index) * stepX
                                                let y = chartHeight - (CGFloat(data.tokens) / CGFloat(maxTokens) * chartHeight)
                                                
                                                if index == 0 {
                                                    path.move(to: CGPoint(x: x, y: y))
                                                } else {
                                                    path.addLine(to: CGPoint(x: x, y: y))
                                                }
                                            }
                                        }
                                        .stroke(Color("006337"), lineWidth: 2)
                                        
                                        // Data points
                                        ForEach(Array(tokenData.enumerated()), id: \.offset) { index, data in
                                            let x = CGFloat(index) * stepX
                                            let y = chartHeight - (CGFloat(data.tokens) / CGFloat(maxTokens) * chartHeight)
                                            
                                            Circle()
                                                .fill(Color("006337"))
                                                .frame(width: 6, height: 6)
                                                .position(x: x, y: y)
                                        }
                                    }
                                    .frame(height: 160)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            
                            // X-axis labels
                            HStack {
                                Spacer()
                                    .frame(width: 48) // Match Y-axis width
                                
                                HStack(spacing: 0) {
                                    ForEach(tokenData, id: \.date) { data in
                                        Text(data.date)
                                            .font(.caption)
                                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        }
                    }
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
                
                // Stats Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Transcriptions",
                        value: "\(analyticsManager.totalTranscriptions)",
                        icon: "waveform.circle.fill",
                        color: Color("006337")
                    )
                    
                    StatCard(
                        title: "Total Duration",
                        value: analyticsManager.formattedTotalDuration,
                        icon: "clock.circle.fill",
                        color: Color("006337")
                    )
                    
                    StatCard(
                        title: "Accuracy Rate",
                        value: analyticsManager.formattedAccuracyRate,
                        icon: "checkmark.circle.fill",
                        color: Color("006337")
                    )
                    
                    StatCard(
                        title: "Active Models",
                        value: "\(analyticsManager.activeModels)",
                        icon: "cpu.circle.fill",
                        color: Color("006337")
                    )
                }
                .padding(.horizontal, 24)
                
                // Sample Data Generation Button (for demo purposes)
                if analyticsManager.totalTranscriptions == 0 {
                    VStack(spacing: 16) {
                        Text("No data available yet")
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        
                        Button(action: {
                            analyticsManager.generateSampleData()
                        }) {
                            Text("Generate Sample Data")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color("006337"), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            analyticsManager.updateActiveModels()
            analyticsManager.updateStorageUsed()
        }
    }
}

struct ModelsTabView: View {
    @StateObject private var modelManager = WhisperModelManager()
    @State private var selectedCategory: ModelCategory = .basicMultilingual
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: LocalizedStringResource("Available Models", comment: "Models title")))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Model Categories
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: LocalizedStringResource("Model Categories", comment: "Model categories title")))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    // Category Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ModelCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedCategory == category ? .black : (themeManager.isDarkMode ? .white : .black))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == category ? Color.white : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 6)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(themeManager.isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Models Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(WhisperModels.shared.getModels(by: selectedCategory), id: \.id) { model in
                            ModelCard(model: model)
                        }
                    }
                    .padding(.horizontal, 24)

                                    // Token Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: LocalizedStringResource("About Tokens & Pricing", comment: "Tokens pricing title")))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TokenInfoRow(
                            icon: "info.circle.fill",
                            title: "What are Tokens?",
                            description: "Basic units of text that AI models process."
                        )
                        
                        TokenInfoRow(
                            icon: "dollarsign.circle.fill",
                            title: "Pricing Information",
                            description: "Scribe Core models are free to use."
                        )
                        
                        TokenInfoRow(
                            icon: "globe",
                            title: "Language Support",
                            description: "All models support 99 languages."
                        )
                        
                        // Scribe Core Documentation Link
                        Button(action: {
                            if let url = URL(string: "https://github.com/argmaxinc/WhisperKit") {
                                #if os(iOS)
                                UIApplication.shared.open(url)
                                #elseif os(macOS)
                                NSWorkspace.shared.open(url)
                                #endif
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Scribe Core Documentation")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("View documentation")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct TokenInfoRow: View {
    let icon: String
    let title: String
    let description: String
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
                
                Text(description)
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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("006337"))
                
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
                
                Text(model.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                
                HStack {
                    Text(model.size)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                    
                    Spacer()
                    
                    Text(model.languages)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                }
                
                // Pricing Information
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: LocalizedStringResource("Scribe Core - Free", comment: "Scribe Core free label")))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("006337"))
                }
                .padding(.top, 4)
                
                if let quantization = model.quantization {
                    Text(quantization.description)
                        .font(.caption2)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct HistoryTabView: View {
    var body: some View {
        HistoryView()
    }
}







struct BillingTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("dashboard.billing_subscription")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                    Text("Beta version - Free plan")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                
                // Current Plan
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Free Plan")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            
                            Spacer()
                            
                            Text("$0/month")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color("006337"))
                        }
                        
                        HStack {
                            Text("Plan status:")
                                .font(.subheadline)
                                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                            
                            Spacer()
                            
                            Text("Active")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("006337"))
                        }
                        
                        Text("All features are free during open beta testing")
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .padding(20)
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("006337").opacity(0.3), lineWidth: 2)
                    )
                }
                .padding(.horizontal, 24)
                
            }
            .padding(.bottom, 24)
        }
    }
}

struct TokenInfoTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Tokens")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Token Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "info.circle.fill",
                            title: "What are Tokens?",
                            description: "Basic units of text that AI models process."
                        )
                        
                        InfoRow(
                            icon: "function",
                            title: "Token Calculation",
                            description: "Handled automatically by our system."
                        )
                        
                        InfoRow(
                            icon: "globe",
                            title: "Language Support",
                            description: "Supports all 100 languages from Whisper."
                        )
                        
                        InfoRow(
                            icon: "cpu",
                            title: "Processing Efficiency",
                            description: "Efficient handling of different languages."
                        )
                    }
                    .padding(20)
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
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
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
            }
        }
        .padding(20)
        .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct UsageRow: View {
    let title: String
    let value: String
    let limit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value) / \(limit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct BillingRow: View {
    let date: String
    let amount: String
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Documents Tab View
struct DocumentsTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Documentation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Core Features Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Core Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        DocumentSection(
                            icon: "waveform.circle.fill",
                            title: "Speech Recognition",
                            description: "High-accuracy speech-to-text conversion.",
                            features: [
                                "Real-time streaming transcription",
                                "Voice Activity Detection",
                                "Multi-language support",
                                "High-precision timestamps"
                            ]
                        )
                        
                        DocumentSection(
                            icon: "cpu.fill",
                            title: "Model Management",
                            description: "Model selection with automatic optimization.",
                            features: [
                                "20+ model variants",
                                "Automatic device optimization",
                                "Quantized models",
                                "Local processing"
                            ]
                        )
                        
                        DocumentSection(
                            icon: "globe",
                            title: "Language Support",
                            description: "Language coverage with intelligent detection.",
                            features: [
                                "99 languages supported",
                                "Automatic language detection",
                                "Specialized models",
                                "Real-time language switching"
                            ]
                        )
                        
                        DocumentSection(
                            icon: "slider.horizontal.3",
                            title: "Configuration",
                            description: "Control over transcription parameters.",
                            features: [
                                "Temperature controls",
                                "Chunking strategy",
                                "Silence threshold",
                                "Worker management"
                            ]
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                // Technical Specifications
                VStack(alignment: .leading, spacing: 16) {
                    Text("Technical Specifications")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        SpecRow(
                            title: "Processing Engine",
                            value: "CoreML optimization"
                        )
                        
                        SpecRow(
                            title: "Supported Platforms",
                            value: "iOS, macOS, watchOS"
                        )
                        
                        SpecRow(
                            title: "Model Sizes",
                            value: "75MB to 2.9GB"
                        )
                        
                        SpecRow(
                            title: "Audio Formats",
                            value: "WAV, MP3, M4A, and more"
                        )
                        
                        SpecRow(
                            title: "Sampling Rate",
                            value: "16kHz (standard), 48kHz (high-quality)"
                        )
                        
                        SpecRow(
                            title: "Latency",
                            value: "Sub-second for real-time processing"
                        )
                    }
                    .padding(20)
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                // Getting Started
                VStack(alignment: .leading, spacing: 16) {
                    Text("Getting Started")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        GettingStartedStep(
                            number: "1",
                            title: "Model Selection",
                            description: "Choose from our curated collection of models."
                        )
                        
                        GettingStartedStep(
                            number: "2",
                            title: "Language Configuration",
                            description: "Set your preferred language or enable auto-detection."
                        )
                        
                        GettingStartedStep(
                            number: "3",
                            title: "Audio Input Setup",
                            description: "Configure your audio input device."
                        )
                        
                        GettingStartedStep(
                            number: "4",
                            title: "Start Transcribing",
                            description: "Begin real-time transcription."
                        )
                    }
                    .padding(20)
                    .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct DocumentSection: View {
    let icon: String
    let title: String
    let description: String
    let features: [String]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("006337"))
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("006337"))
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(themeManager.isDarkMode ? Color.black : Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SpecRow: View {
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
        }
    }
}

struct GettingStartedStep: View {
    let number: String
    let title: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("006337"))
                    .frame(width: 24, height: 24)
                
                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct BetaFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("006337"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

struct BetaInfoRow: View {
    let icon: String
    let title: String
    let description: String
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
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}


#Preview {
    DashboardView()
}
