//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI

// MARK: - Cost Report Manager

@MainActor
class CostReportManager: ObservableObject {
    static let shared = CostReportManager()
    
    @Published var dailyUsage: [CostReportDailyUsage] = []
    @Published var totalCostThisMonth: Double = 0.0
    @Published var totalDurationThisMonth: TimeInterval = 0.0
    @Published var mostUsedModel: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let usageKey = "CostReportUsage"
    
    private init() {
        loadUsage()
        calculateMonthlyStats()
    }
    
    // MARK: - Usage Tracking
    
    func recordUsage(duration: TimeInterval, model: String, cost: Double, isTranslation: Bool = false, optimizationSavings: Double = 0.0) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = dailyUsage.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // 今日の使用量を更新
            dailyUsage[index].duration += duration
            dailyUsage[index].cost += cost
            dailyUsage[index].usageCount += 1
            dailyUsage[index].optimizationSavings += optimizationSavings
            
            if isTranslation {
                dailyUsage[index].translationCount += 1
            } else {
                dailyUsage[index].transcriptionCount += 1
            }
            
            // モデル別の使用量を更新
            dailyUsage[index].modelUsage[model, default: 0] += duration
        } else {
            // 新しい日の使用量を作成
            var modelUsage: [String: TimeInterval] = [:]
            modelUsage[model] = duration
            
            let newUsage = CostReportDailyUsage(
                date: today,
                duration: duration,
                cost: cost,
                transcriptionCount: isTranslation ? 0 : 1,
                translationCount: isTranslation ? 1 : 0,
                usageCount: 1,
                modelUsage: modelUsage,
                optimizationSavings: optimizationSavings
            )
            
            dailyUsage.append(newUsage)
        }
        
        saveUsage()
        calculateMonthlyStats()
    }
    
    // MARK: - Statistics
    
    func calculateMonthlyStats() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // 今月の使用量を集計
        let thisMonthUsage = dailyUsage.filter { usage in
            let usageMonth = calendar.component(.month, from: usage.date)
            let usageYear = calendar.component(.year, from: usage.date)
            return usageMonth == currentMonth && usageYear == currentYear
        }
        
        totalCostThisMonth = thisMonthUsage.reduce(0.0) { $0 + $1.cost }
        totalDurationThisMonth = thisMonthUsage.reduce(0.0) { $0 + $1.duration }
        
        // 最もよく使われるモデルを計算
        var modelDurations: [String: TimeInterval] = [:]
        for usage in thisMonthUsage {
            for (model, duration) in usage.modelUsage {
                modelDurations[model, default: 0] += duration
            }
        }
        
        if let topModel = modelDurations.max(by: { $0.value < $1.value }) {
            mostUsedModel = topModel.key
        } else {
            mostUsedModel = ""
        }
    }
    
    func getCostBreakdownByModel() -> [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let thisMonthUsage = dailyUsage.filter { usage in
            let usageMonth = calendar.component(.month, from: usage.date)
            let usageYear = calendar.component(.year, from: usage.date)
            return usageMonth == currentMonth && usageYear == currentYear
        }
        
        var modelCosts: [String: Double] = [:]
        
        for usage in thisMonthUsage {
            for (model, duration) in usage.modelUsage {
                let costPerMinute: Double
                
                switch model {
                case "whisper-1":
                    costPerMinute = 0.006
                case "gpt-4o-transcribe":
                    costPerMinute = 0.006
                case "gpt-4o-mini-transcribe":
                    costPerMinute = 0.003
                default:
                    costPerMinute = 0.003
                }
                
                let cost = (duration / 60.0) * costPerMinute
                modelCosts[model, default: 0] += cost
            }
        }
        
        return modelCosts
    }
    
    func getTotalOptimizationSavings() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let thisMonthUsage = dailyUsage.filter { usage in
            let usageMonth = calendar.component(.month, from: usage.date)
            let usageYear = calendar.component(.year, from: usage.date)
            return usageMonth == currentMonth && usageYear == currentYear
        }
        
        return thisMonthUsage.reduce(0.0) { $0 + $1.optimizationSavings }
    }
    
    func getUsageReport() -> UsageReport {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let thisMonthUsage = dailyUsage.filter { usage in
            let usageMonth = calendar.component(.month, from: usage.date)
            let usageYear = calendar.component(.year, from: usage.date)
            return usageMonth == currentMonth && usageYear == currentYear
        }
        
        let totalTranscriptions = thisMonthUsage.reduce(0) { $0 + $1.transcriptionCount }
        let totalTranslations = thisMonthUsage.reduce(0) { $0 + $1.translationCount }
        let averageCostPerRequest = totalCostThisMonth / Double(max(totalTranscriptions + totalTranslations, 1))
        let costBreakdown = getCostBreakdownByModel()
        let optimizationSavings = getTotalOptimizationSavings()
        
        return UsageReport(
            totalCost: totalCostThisMonth,
            totalDuration: totalDurationThisMonth,
            totalTranscriptions: totalTranscriptions,
            totalTranslations: totalTranslations,
            mostUsedModel: mostUsedModel,
            averageCostPerRequest: averageCostPerRequest,
            costBreakdownByModel: costBreakdown,
            optimizationSavings: optimizationSavings,
            period: "This Month"
        )
    }
    
    // MARK: - Data Persistence
    
    private func loadUsage() {
        if let data = userDefaults.data(forKey: usageKey),
           let usage = try? JSONDecoder().decode([CostReportDailyUsage].self, from: data) {
            dailyUsage = usage
        }
    }
    
    private func saveUsage() {
        if let data = try? JSONEncoder().encode(dailyUsage) {
            userDefaults.set(data, forKey: usageKey)
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData(olderThan days: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        dailyUsage = dailyUsage.filter { $0.date >= cutoffDate }
        saveUsage()
    }
}

// MARK: - Supporting Types

struct CostReportDailyUsage: Codable, Identifiable {
    let id: UUID
    let date: Date
    var duration: TimeInterval
    var cost: Double
    var transcriptionCount: Int
    var translationCount: Int
    var usageCount: Int
    var modelUsage: [String: TimeInterval]
    var optimizationSavings: Double
    
    init(date: Date, duration: TimeInterval, cost: Double, transcriptionCount: Int, translationCount: Int, usageCount: Int, modelUsage: [String: TimeInterval], optimizationSavings: Double = 0.0) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.cost = cost
        self.transcriptionCount = transcriptionCount
        self.translationCount = translationCount
        self.usageCount = usageCount
        self.modelUsage = modelUsage
        self.optimizationSavings = optimizationSavings
    }
}

struct UsageReport {
    let totalCost: Double
    let totalDuration: TimeInterval
    let totalTranscriptions: Int
    let totalTranslations: Int
    let mostUsedModel: String
    let averageCostPerRequest: Double
    let costBreakdownByModel: [String: Double]
    let optimizationSavings: Double
    let period: String
    
    var formattedTotalCost: String {
        return String(format: "$%.4f", totalCost)
    }
    
    var formattedDuration: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var formattedAverageCost: String {
        return String(format: "$%.4f", averageCostPerRequest)
    }
    
    var formattedOptimizationSavings: String {
        return String(format: "$%.4f", optimizationSavings)
    }
    
    var savingsPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (optimizationSavings / (totalCost + optimizationSavings)) * 100.0
    }
}

