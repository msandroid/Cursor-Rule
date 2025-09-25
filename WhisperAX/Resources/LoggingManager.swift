//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation
import os.log

/// ログレベル
enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

/// ログカテゴリ
enum LogCategory: String {
    case stt = "STT"
    case token = "Token"
    case ui = "UI"
    case performance = "Performance"
    case audio = "Audio"
    case model = "Model"
}

/// 最適化されたログ管理システム
class LoggingManager {
    static let shared = LoggingManager()
    
    private let logger = Logger(subsystem: "com.scribe.whisperax", category: "main")
    private var currentLogLevel: LogLevel = .info
    private var isRealtimeProcessing: Bool = false
    private var logQueue = DispatchQueue(label: "com.scribe.logging", qos: .utility)
    private var bufferedLogs: [(level: LogLevel, category: LogCategory, message: String, timestamp: Date)] = []
    private var batchTimer: Timer?
    
    private init() {
        // 本番環境ではログレベルを調整
        #if DEBUG
        currentLogLevel = .debug
        #else
        currentLogLevel = .warning
        #endif
    }
    
    /// リアルタイム処理モードの設定
    func setRealtimeProcessing(_ enabled: Bool) {
        isRealtimeProcessing = enabled
        if enabled {
            startBatchLogging()
        } else {
            flushBufferedLogs()
            stopBatchLogging()
        }
    }
    
    /// ログレベルの設定
    func setLogLevel(_ level: LogLevel) {
        currentLogLevel = level
    }
    
    /// デバッグログ（条件付き出力）
    func debug(_ message: String, category: LogCategory = .main) {
        log(.debug, message: message, category: category)
    }
    
    /// 情報ログ
    func info(_ message: String, category: LogCategory = .main) {
        log(.info, message: message, category: category)
    }
    
    /// 警告ログ
    func warning(_ message: String, category: LogCategory = .main) {
        log(.warning, message: message, category: category)
    }
    
    /// エラーログ
    func error(_ message: String, category: LogCategory = .main) {
        log(.error, message: message, category: category)
    }
    
    /// 内部ログ関数
    private func log(_ level: LogLevel, message: String, category: LogCategory) {
        // ログレベルチェック
        guard level.rawValue >= currentLogLevel.rawValue else { return }
        
        let formattedMessage = "[\(category.rawValue)] \(message)"
        
        if isRealtimeProcessing {
            // リアルタイム処理中はバッファリング
            bufferLog(level: level, category: category, message: formattedMessage)
        } else {
            // 通常時は即座に出力
            outputLog(level: level, message: formattedMessage)
        }
    }
    
    /// ログのバッファリング
    private func bufferLog(level: LogLevel, category: LogCategory, message: String) {
        logQueue.async { [weak self] in
            self?.bufferedLogs.append((level: level, category: category, message: message, timestamp: Date()))
        }
    }
    
    /// バッチログ出力の開始
    private func startBatchLogging() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.flushBufferedLogs()
        }
    }
    
    /// バッチログ出力の停止
    private func stopBatchLogging() {
        batchTimer?.invalidate()
        batchTimer = nil
    }
    
    /// バッファされたログの出力
    private func flushBufferedLogs() {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let logsToFlush = self.bufferedLogs
            self.bufferedLogs.removeAll()
            
            DispatchQueue.main.async {
                for logEntry in logsToFlush {
                    self.outputLog(level: logEntry.level, message: logEntry.message)
                }
            }
        }
    }
    
    /// 実際のログ出力
    private func outputLog(level: LogLevel, message: String) {
        logger.log(level: level.osLogType, "\(message)")
    }
    
    /// パフォーマンス測定用ログ
    func performance(_ operation: String, duration: TimeInterval, category: LogCategory = .performance) {
        let message = "\(operation): \(String(format: "%.3f", duration))s"
        log(.info, message: message, category: category)
    }
    
    /// リアルタイムファクターのログ
    func realtimeFactor(_ factor: Double, category: LogCategory = .performance) {
        let message = "Real-time factor: \(String(format: "%.2f", factor))"
        log(.info, message: message, category: category)
    }
}

/// 便利なログ関数
func LogDebug(_ message: String, category: LogCategory = .main) {
    LoggingManager.shared.debug(message, category: category)
}

func LogInfo(_ message: String, category: LogCategory = .main) {
    LoggingManager.shared.info(message, category: category)
}

func LogWarning(_ message: String, category: LogCategory = .main) {
    LoggingManager.shared.warning(message, category: category)
}

func LogError(_ message: String, category: LogCategory = .main) {
    LoggingManager.shared.error(message, category: category)
}

func LogPerformance(_ operation: String, duration: TimeInterval, category: LogCategory = .performance) {
    LoggingManager.shared.performance(operation, duration: duration, category: category)
}

func LogRealtimeFactor(_ factor: Double, category: LogCategory = .performance) {
    LoggingManager.shared.realtimeFactor(factor, category: category)
}
