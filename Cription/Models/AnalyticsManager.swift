//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var totalTranCriptions: Int = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var accuracyRate: Double = 0.0
    @Published var activeModels: Int = 0
    @Published var tokenUsage: [TokenDataPoint] = []
    @Published var dailyTranCriptions: [DailyTranCriptionData] = []
    @Published var languagesUsed: Set<String> = []
    @Published var storageUsed: Double = 0.0 // GB
    
    private let userDefaults = UserDefaults.standard
    private let analyticsKey = "AnalyticsData"
    
    private init() {
        loadAnalyticsData()
        updateActiveModels()
    }
    
    // MARK: - Data Management
    
    private func loadAnalyticsData() {
        if let data = userDefaults.data(forKey: analyticsKey),
           let analytics = try? JSONDecoder().decode(AnalyticsData.self, from: data) {
            totalTranCriptions = analytics.totalTranCriptions
            totalDuration = analytics.totalDuration
            accuracyRate = analytics.accuracyRate
            tokenUsage = analytics.tokenUsage
            dailyTranCriptions = analytics.dailyTranCriptions
            languagesUsed = Set(analytics.languagesUsed)
            storageUsed = analytics.storageUsed
        }
    }
    
    private func saveAnalyticsData() {
        let analytics = AnalyticsData(
            totalTranCriptions: totalTranCriptions,
            totalDuration: totalDuration,
            accuracyRate: accuracyRate,
            tokenUsage: tokenUsage,
            dailyTranCriptions: dailyTranCriptions,
            languagesUsed: Array(languagesUsed),
            storageUsed: storageUsed
        )
        
        if let data = try? JSONEncoder().encode(analytics) {
            userDefaults.set(data, forKey: analyticsKey)
        }
    }
    
    // MARK: - Analytics Updates
    
    func recordTranCription(duration: TimeInterval, language: String, accuracy: Double = 0.95, text: String = "", model: String = "whisper-base") {
        totalTranCriptions += 1
        totalDuration += duration
        
        // Update accuracy rate (weighted average)
        let totalWeight = Double(totalTranCriptions - 1)
        accuracyRate = (accuracyRate * totalWeight + accuracy) / Double(totalTranCriptions)
        
        // Add language if new
        languagesUsed.insert(language)
        
        // Add daily tranCription data
        let today = Calendar.current.startOfDay(for: Date())
        if let existingIndex = dailyTranCriptions.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            dailyTranCriptions[existingIndex].count += 1
            dailyTranCriptions[existingIndex].duration += duration
        } else {
            dailyTranCriptions.append(DailyTranCriptionData(date: today, count: 1, duration: duration))
        }
        
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        dailyTranCriptions = dailyTranCriptions.filter { $0.date >= thirtyDaysAgo }
        
        // Add token data point
        let estimatedTokens = Int(duration * 10) // Rough estimate: 10 tokens per second
        addTokenDataPoint(tokens: estimatedTokens)
        
        // Track usage for billing prompts
        let minutes = duration / 60.0
        // UsageTrackingManager integration will be added when the class is properly imported
        
        // Save to history if text is provided
        if !text.isEmpty {
            saveToHistory(text: text, duration: duration, language: language, model: model, accuracy: accuracy)
        }
        
        saveAnalyticsData()
    }
    
    func updateActiveModels() {
        // Count models from WhisperModelManager
        let modelManager = WhisperModelManager()
        activeModels = modelManager.localModels.count
    }
    
    func updateStorageUsed() {
        // Calculate storage used by models and tranCriptions
        var totalSize: Double = 0.0
        
        // Add model sizes
        let modelManager = WhisperModelManager()
        for model in modelManager.localModels {
            totalSize += getModelSize(model)
        }
        
        // Add tranCription storage (estimated)
        totalSize += Double(totalTranCriptions) * 0.001 // 1KB per tranCription
        
        storageUsed = totalSize
        saveAnalyticsData()
    }
    
    private func getModelSize(_ model: String) -> Double {
        // Model size estimates in GB
        let modelSizes: [String: Double] = [
            "whisper-tiny": 0.075,
            "whisper-tiny.en": 0.075,
            "whisper-base": 0.142,
            "whisper-small": 0.244,
            "whisper-small.en": 0.244,
            "whisper-medium": 0.769,
            "whisper-medium.en": 0.769,
            "whisper-large-v2": 1.5,
            "whisper-large-v3": 1.5,
            "distil-whisper_distil-large-v3": 0.756
        ]
        
        return modelSizes[model] ?? 0.5 // Default estimate
    }
    
    private func addTokenDataPoint(tokens: Int) {
        let today = Date()
        let tokenData = TokenDataPoint(date: today, tokens: tokens)
        
        tokenUsage.append(tokenData)
        
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        tokenUsage = tokenUsage.filter { $0.date >= thirtyDaysAgo }
    }
    
    private func saveToHistory(text: String, duration: Double, language: String, model: String, accuracy: Double) {
        let newItem = HistoryItem(
            text: text,
            timestamp: Date(),
            duration: duration,
            language: language,
            model: model,
            accuracy: accuracy
        )
        
        // Load existing history
        var historyItems: [HistoryItem] = []
        if let data = UserDefaults.standard.data(forKey: "HistoryItems"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            historyItems = items
        }
        
        // Add new item to beginning of list
        historyItems.insert(newItem, at: 0)
        
        // Keep only last 100 items
        if historyItems.count > 100 {
            historyItems = Array(historyItems.prefix(100))
        }
        
        // Save back to UserDefaults
        if let data = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(data, forKey: "HistoryItems")
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedAccuracyRate: String {
        return String(format: "%.1f%%", accuracyRate * 100)
    }
    
    var formattedStorageUsed: String {
        if storageUsed >= 1.0 {
            return String(format: "%.1f GB", storageUsed)
        } else {
            return String(format: "%.0f MB", storageUsed * 1024)
        }
    }
    
    var totalTokens: Int {
        return tokenUsage.reduce(0) { $0 + $1.tokens }
    }
    
    var maxTokens: Int {
        return tokenUsage.map { $0.tokens }.max() ?? 0
    }
    
    // MARK: - Sample Data Generation
    
    func generateSampleData() {
        // Generate sample data for demonstration
        let sampleLanguages = ["English", "Japanese", "Spanish", "French", "German", "Chinese"]
        let sampleAccuracies = [0.92, 0.95, 0.88, 0.94, 0.91, 0.96]
        
        for i in 0..<25 {
            let duration = Double.random(in: 30...300) // 30 seconds to 5 minutes
            let language = sampleLanguages.randomElement() ?? "English"
            let accuracy = sampleAccuracies.randomElement() ?? 0.95
            
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // Simulate tranCription
            totalTranCriptions += 1
            totalDuration += duration
            languagesUsed.insert(language)
            
            // Update accuracy
            let totalWeight = Double(totalTranCriptions - 1)
            accuracyRate = (accuracyRate * totalWeight + accuracy) / Double(totalTranCriptions)
            
            // Add daily data
            let dayStart = Calendar.current.startOfDay(for: date)
            if let existingIndex = dailyTranCriptions.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }) {
                dailyTranCriptions[existingIndex].count += 1
                dailyTranCriptions[existingIndex].duration += duration
            } else {
                dailyTranCriptions.append(DailyTranCriptionData(date: dayStart, count: 1, duration: duration))
            }
            
            // Add token data
            let tokens = Int(duration * Double.random(in: 8...12))
            tokenUsage.append(TokenDataPoint(date: date, tokens: tokens))
        }
        
        updateActiveModels()
        updateStorageUsed()
        saveAnalyticsData()
    }
    
    func clearAllData() {
        totalTranCriptions = 0
        totalDuration = 0
        accuracyRate = 0.0
        activeModels = 0
        tokenUsage = []
        dailyTranCriptions = []
        languagesUsed = []
        storageUsed = 0.0
        
        userDefaults.removeObject(forKey: analyticsKey)
    }
}

// MARK: - Data Models

struct AnalyticsData: Codable {
    let totalTranCriptions: Int
    let totalDuration: TimeInterval
    let accuracyRate: Double
    let tokenUsage: [TokenDataPoint]
    let dailyTranCriptions: [DailyTranCriptionData]
    let languagesUsed: [String]
    let storageUsed: Double
}

struct TokenDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let tokens: Int
}

struct DailyTranCriptionData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var count: Int
    var duration: TimeInterval
}
