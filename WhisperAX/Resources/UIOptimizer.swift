//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation
import SwiftUI

/// UI更新の最適化管理
class UIOptimizer: ObservableObject {
    static let shared = UIOptimizer()
    
    private var pendingUpdates: [() -> Void] = []
    private var batchTimer: Timer?
    private var isRealtimeProcessing: Bool = false
    private let updateQueue = DispatchQueue(label: "com.scribe.ui-updates", qos: .userInitiated)
    
    private init() {}
    
    /// リアルタイム処理モードの設定
    func setRealtimeProcessing(_ enabled: Bool) {
        isRealtimeProcessing = enabled
        if enabled {
            startBatchUpdates()
        } else {
            flushPendingUpdates()
            stopBatchUpdates()
        }
    }
    
    /// バッチ更新の開始
    private func startBatchUpdates() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.flushPendingUpdates()
        }
    }
    
    /// バッチ更新の停止
    private func stopBatchUpdates() {
        batchTimer?.invalidate()
        batchTimer = nil
    }
    
    /// 保留中の更新を実行
    private func flushPendingUpdates() {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        
        Task { @MainActor in
            for update in updates {
                update()
            }
        }
    }
    
    /// UI更新のスケジュール
    func scheduleUpdate(_ update: @escaping () -> Void) {
        if isRealtimeProcessing {
            // リアルタイム処理中はバッチ化
            updateQueue.async { [weak self] in
                self?.pendingUpdates.append(update)
            }
        } else {
            // 通常時は即座に実行
            Task { @MainActor in
                update()
            }
        }
    }
    
    /// 複数のUI更新をバッチ化
    func batchUpdates(_ updates: [() -> Void]) {
        if isRealtimeProcessing {
            updateQueue.async { [weak self] in
                self?.pendingUpdates.append(contentsOf: updates)
            }
        } else {
            Task { @MainActor in
                for update in updates {
                    update()
                }
            }
        }
    }
}

/// パフォーマンス測定用の構造体
struct PerformanceMetrics {
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    
    init() {
        self.startTime = Date()
    }
    
    mutating func finish() {
        self.endTime = Date()
    }
}

/// パフォーマンス測定マネージャー
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var currentMetrics: [String: PerformanceMetrics] = [:]
    @Published var averageDurations: [String: TimeInterval] = [:]
    @Published var realtimeFactor: Double = 0.0
    
    private var measurementCounts: [String: Int] = [:]
    private let metricsQueue = DispatchQueue(label: "com.scribe.performance", qos: .utility)
    
    private init() {}
    
    /// 測定開始
    func startMeasurement(_ operation: String) {
        metricsQueue.async { [weak self] in
            self?.currentMetrics[operation] = PerformanceMetrics()
        }
    }
    
    /// 測定終了
    func endMeasurement(_ operation: String) {
        metricsQueue.async { [weak self] in
            guard var metrics = self?.currentMetrics[operation] else { return }
            metrics.finish()
            self?.currentMetrics[operation] = metrics
            
            // 平均値の更新
            let count = (self?.measurementCounts[operation] ?? 0) + 1
            self?.measurementCounts[operation] = count
            
            let currentAverage = self?.averageDurations[operation] ?? 0.0
            let newAverage = (currentAverage * Double(count - 1) + metrics.duration) / Double(count)
            self?.averageDurations[operation] = newAverage
            
            // ログ出力
            LogPerformance(operation, duration: metrics.duration)
        }
    }
    
    /// リアルタイムファクターの更新
    func updateRealtimeFactor(_ factor: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.realtimeFactor = factor
            LogRealtimeFactor(factor)
        }
    }
    
    /// 測定結果の取得
    func getMetrics(for operation: String) -> (current: TimeInterval, average: TimeInterval) {
        let current = currentMetrics[operation]?.duration ?? 0.0
        let average = averageDurations[operation] ?? 0.0
        return (current, average)
    }
    
    /// 全測定のリセット
    func resetAll() {
        metricsQueue.async { [weak self] in
            self?.currentMetrics.removeAll()
            self?.averageDurations.removeAll()
            self?.measurementCounts.removeAll()
        }
    }
}

/// 便利なパフォーマンス測定関数
func measurePerformance<T>(_ operation: String, block: () throws -> T) rethrows -> T {
    PerformanceManager.shared.startMeasurement(operation)
    defer {
        PerformanceManager.shared.endMeasurement(operation)
    }
    return try block()
}

func measurePerformanceAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
    PerformanceManager.shared.startMeasurement(operation)
    defer {
        PerformanceManager.shared.endMeasurement(operation)
    }
    return try await block()
}
