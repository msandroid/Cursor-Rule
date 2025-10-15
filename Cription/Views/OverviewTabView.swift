//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI

struct OverviewTabView: View {
    @State private var selectedTimeRange: TimeRange = .week
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject var analyticsManager: AnalyticsManager
    @State private var chartAnimationProgress: CGFloat = 0
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Convert token data to display format
    private var tokenData: [(date: String, tokens: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        var data: [(date: String, tokens: Int)] = []
        
        switch selectedTimeRange {
        case .week:
            // Show last 7 days
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let dayStart = calendar.startOfDay(for: date)
                
                let dayTokens = analyticsManager.tokenUsage
                    .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                    .reduce(0) { $0 + $1.tokens }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd"
                
                data.append((date: dateFormatter.string(from: date), tokens: dayTokens))
            }
            
        case .month:
            // Show last 30 days
            for i in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
                let dayStart = calendar.startOfDay(for: date)
                
                let dayTokens = analyticsManager.tokenUsage
                    .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                    .reduce(0) { $0 + $1.tokens }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd"
                
                data.append((date: dateFormatter.string(from: date), tokens: dayTokens))
            }
            
        case .year:
            // Show last 12 months
            for i in 0..<12 {
                let date = calendar.date(byAdding: .month, value: -i, to: now) ?? now
                let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
                let monthEnd = calendar.dateInterval(of: .month, for: date)?.end ?? date
                
                let monthTokens = analyticsManager.tokenUsage
                    .filter { $0.date >= monthStart && $0.date < monthEnd }
                    .reduce(0) { $0 + $1.tokens }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM"
                
                data.append((date: dateFormatter.string(from: date), tokens: monthTokens))
            }
        }
        
        return data.reversed() // Show oldest to newest
    }
    
    private var totalTokens: Int {
        analyticsManager.totalTokens
    }
    
    private var maxTokens: Int {
        max(analyticsManager.maxTokens, 1) // Prevent division by zero
    }
    
    private var hasData: Bool {
        analyticsManager.totalTokens > 0
    }
    
    private var averageTokensPerDay: Int {
        let periods: Int
        switch selectedTimeRange {
        case .week:
            periods = 7
        case .month:
            periods = 30
        case .year:
            periods = 12 // 12 months
        }
        return analyticsManager.totalTokens / max(periods, 1)
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
                    // Chart Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Token Usage")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            
                            if hasData {
                                let averageLabel = selectedTimeRange == .year ? "tokens/month" : "tokens/day"
                                Text("Average: \(averageTokensPerDay.formatted()) \(averageLabel)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        // Time Range Selector
                        HStack(spacing: 8) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedTimeRange = range
                                        chartAnimationProgress = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeInOut(duration: 0.8)) {
                                            chartAnimationProgress = 1
                                        }
                                    }
                                }) {
                                    Text(range.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedTimeRange == range ? .white : (themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7)))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedTimeRange == range ? Color("006337") : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 6)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Chart Container
                    VStack(alignment: .leading, spacing: 0) {
                        if hasData {
                            // Total Tokens Display
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(totalTokens.formatted())")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                        .scaleEffect(chartAnimationProgress)
                                    
                                    Text(String(localized: LocalizedStringResource("Total Tokens", comment: "Total tokens label")))
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                // Trend indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("+12%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
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
                                        // Background gradient
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color("006337").opacity(0.1),
                                                Color("006337").opacity(0.05)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 180)
                                        
                                        // Grid lines
                                        VStack(spacing: 0) {
                                            ForEach(0..<5, id: \.self) { _ in
                                                Rectangle()
                                                    .fill(themeManager.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                                    .frame(height: 1)
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(height: 180)
                                        
                                        // Area chart
                                        GeometryReader { geometry in
                                            let chartWidth = geometry.size.width
                                            let chartHeight = geometry.size.height
                                            let stepX = tokenData.count > 1 ? chartWidth / CGFloat(tokenData.count - 1) : chartWidth
                                            
                                            // Area fill
                                            Path { path in
                                                for (index, data) in tokenData.enumerated() {
                                                    let x = CGFloat(index) * stepX
                                                    let y = chartHeight - (CGFloat(data.tokens) / CGFloat(maxTokens) * chartHeight)
                                                    
                                                    if index == 0 {
                                                        path.move(to: CGPoint(x: x, y: chartHeight))
                                                        path.addLine(to: CGPoint(x: x, y: y))
                                                    } else {
                                                        path.addLine(to: CGPoint(x: x, y: y))
                                                    }
                                                }
                                                // Close the area
                                                if !tokenData.isEmpty {
                                                    let lastX = CGFloat(tokenData.count - 1) * stepX
                                                    path.addLine(to: CGPoint(x: lastX, y: chartHeight))
                                                    path.closeSubpath()
                                                }
                                            }
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color("006337").opacity(0.3),
                                                        Color("006337").opacity(0.1)
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .scaleEffect(y: chartAnimationProgress, anchor: .bottom)
                                            
                                            // Line chart
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
                                            .stroke(Color("006337"), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                            .scaleEffect(y: chartAnimationProgress, anchor: .bottom)
                                            
                                            // Data points
                                            ForEach(Array(tokenData.enumerated()), id: \.offset) { index, data in
                                                let x = CGFloat(index) * stepX
                                                let y = chartHeight - (CGFloat(data.tokens) / CGFloat(maxTokens) * chartHeight)
                                                
                                                Circle()
                                                    .fill(Color("006337"))
                                                    .frame(width: 8, height: 8)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: 2)
                                                    )
                                                    .position(x: x, y: y)
                                                    .scaleEffect(chartAnimationProgress)
                                            }
                                        }
                                        .frame(height: 180)
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
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48))
                                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.3))
                                
                                Text("No Data Available")
                                    .font(.headline)
                                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                                
                                Text("Start transcribing to see your usage analytics")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.5) : .black.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
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
                        value: "\(analyticsManager.totalTranCriptions)",
                        icon: "waveform.circle.fill",
                        color: Color("006337"),
                        trend: "+5%"
                    )
                    
                    StatCard(
                        title: "Total Duration",
                        value: analyticsManager.formattedTotalDuration,
                        icon: "clock.circle.fill",
                        color: Color.blue,
                        trend: "+8%"
                    )
                    
                    StatCard(
                        title: "Active Models",
                        value: "\(analyticsManager.activeModels)",
                        icon: "cpu.fill",
                        color: Color.orange,
                        trend: nil
                    )
                    
                    StatCard(
                        title: "Success Rate",
                        value: "98.5%",
                        icon: "checkmark.circle.fill",
                        color: Color.green,
                        trend: "+2%"
                    )
                }
                .padding(.horizontal, 24)
                
                // Sample Data Generation Button (for demo purposes)
                if analyticsManager.totalTranCriptions == 0 {
                    VStack(spacing: 16) {
                        Text(String(localized: LocalizedStringResource("No data available yet", comment: "No data available message")))
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
                        
                        Button(action: {
                            analyticsManager.generateSampleData()
                        }) {
                            Text(String(localized: LocalizedStringResource("Generate Sample Data", comment: "Generate sample data button")))
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
            
            // Start chart animation
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                chartAnimationProgress = 1
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(trend)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .scaleEffect(animationProgress)
                
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                animationProgress = 1
            }
        }
    }
}
