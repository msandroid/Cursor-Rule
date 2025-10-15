//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

/// 使用量データのモデル
struct UsageData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let model: String
    let tokens: Int
    let cost: Double
    let type: UsageType
    
    enum UsageType: String, Codable, CaseIterable {
        case included = "Included"
        case onDemand = "On-Demand"
    }
}

/// 月間使用量サマリー
struct MonthlyUsageSummary: Codable {
    let month: String
    let year: Int
    var includedUsage: [UsageData]
    var onDemandUsage: [UsageData]
    var totalTokens: Int
    var totalCost: Double
    var includedCost: Double
    var onDemandCost: Double
    
    var formattedMonth: String {
        return "\(month) \(year)"
    }
}

/// 使用量管理マネージャー
@MainActor
class UsageDataManager: ObservableObject {
    static let shared = UsageDataManager()
    
    @Published var currentMonthUsage: MonthlyUsageSummary?
    @Published var usageHistory: [MonthlyUsageSummary] = []
    
    private let userDefaults = UserDefaults.standard
    private let usageDataKey = "UsageData"
    private let historyKey = "UsageHistory"
    
    // 1トークンあたりのコスト（$0.00001）
    private let tokenCost: Double = 0.00001
    
    init() {
        loadUsageData()
    }
    
    // MARK: - Usage Tracking
    
    func addUsage(model: String, tokens: Int, type: UsageData.UsageType = .onDemand) {
        let cost = Double(tokens) * tokenCost
        let usage = UsageData(
            date: Date(),
            model: model,
            tokens: tokens,
            cost: cost,
            type: type
        )
        
        updateCurrentMonthUsage(with: usage)
        saveUsageData()
    }
    
    private func updateCurrentMonthUsage(with usage: UsageData) {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let monthName = DateFormatter().monthSymbols[currentMonth - 1]
        
        if var current = currentMonthUsage,
           current.month == monthName,
           current.year == currentYear {
            
            if usage.type == .included {
                current.includedUsage.append(usage)
                current.includedCost += usage.cost
            } else {
                current.onDemandUsage.append(usage)
                current.onDemandCost += usage.cost
            }
            
            current.totalTokens += usage.tokens
            current.totalCost += usage.cost
            
            currentMonthUsage = current
        } else {
            // 新しい月のデータを作成
            let includedUsage = usage.type == .included ? [usage] : []
            let onDemandUsage = usage.type == .onDemand ? [usage] : []
            
            let includedCost = usage.type == .included ? usage.cost : 0.0
            let onDemandCost = usage.type == .onDemand ? usage.cost : 0.0
            
            currentMonthUsage = MonthlyUsageSummary(
                month: monthName,
                year: currentYear,
                includedUsage: includedUsage,
                onDemandUsage: onDemandUsage,
                totalTokens: usage.tokens,
                totalCost: usage.cost,
                includedCost: includedCost,
                onDemandCost: onDemandCost
            )
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadUsageData() {
        if let data = userDefaults.data(forKey: usageDataKey),
           let usage = try? JSONDecoder().decode(MonthlyUsageSummary.self, from: data) {
            currentMonthUsage = usage
        }
        
        if let data = userDefaults.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([MonthlyUsageSummary].self, from: data) {
            usageHistory = history
        }
    }
    
    private func saveUsageData() {
        if let current = currentMonthUsage,
           let data = try? JSONEncoder().encode(current) {
            userDefaults.set(data, forKey: usageDataKey)
        }
        
        if let data = try? JSONEncoder().encode(usageHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    // MARK: - Helper Methods
    
    func getModelDisplayName(_ model: String) -> String {
        switch model {
        case "gpt-4o-transcribe":
            return "gpt-4o-transcribe"
        case "gpt-4o-mini":
            return "gpt-4o-mini"
        case "claude-4.5-sonnet-thinking":
            return "claude-4.5-sonnet-thinking"
        case "claude-4-sonnet":
            return "claude-4-sonnet"
        case "gpt-5":
            return "gpt-5"
        default:
            return model
        }
    }
    
    func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.1fB", Double(tokens) / 1_000_000_000)
        } else if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        } else {
            return "\(tokens)"
        }
    }
    
    func formatCost(_ cost: Double) -> String {
        return String(format: "$%.2f", cost)
    }
}
