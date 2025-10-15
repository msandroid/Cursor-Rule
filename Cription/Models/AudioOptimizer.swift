//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import AVFoundation

// MARK: - Audio Optimizer

/// 音声データのコスト最適化を行うユーティリティクラス
class AudioOptimizer {
    
    // MARK: - Silence Detection
    
    /// 音声データから無音部分を検出して削除
    /// - Parameters:
    ///   - audioData: 元の音声データ
    ///   - silenceThreshold: 無音判定の閾値（0.0〜1.0、デフォルト: 0.02）
    ///   - minSilenceDuration: 削除する最小無音時間（秒、デフォルト: 0.5秒）
    /// - Returns: 無音部分を削除した音声データ
    static func removeSilence(from audioData: Data, silenceThreshold: Float = 0.02, minSilenceDuration: TimeInterval = 0.5) async throws -> Data {
        // 一時ファイルに書き込み
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_\(UUID().uuidString).m4a")
        try audioData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // AVAudioFileを使用して音声データを読み込み
        let audioFile = try AVAudioFile(forReading: tempURL)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount) else {
            throw AudioOptimizerError.invalidAudioData
        }
        
        try audioFile.read(into: audioBuffer)
        
        guard let channelData = audioBuffer.floatChannelData else {
            throw AudioOptimizerError.invalidAudioData
        }
        
        let frameLength = Int(audioBuffer.frameLength)
        let sampleRate = audioFormat.sampleRate
        let minSilenceFrames = Int(minSilenceDuration * sampleRate)
        
        // 無音部分を検出
        var nonSilentRanges: [(start: Int, end: Int)] = []
        var currentStart: Int?
        var silenceCount = 0
        
        for i in 0..<frameLength {
            let sample = abs(channelData[0][i])
            
            if sample > silenceThreshold {
                // 音声あり
                if currentStart == nil {
                    currentStart = i
                }
                silenceCount = 0
            } else {
                // 無音
                silenceCount += 1
                
                if silenceCount >= minSilenceFrames, let start = currentStart {
                    // 無音が閾値を超えた場合、非無音範囲を記録
                    nonSilentRanges.append((start: start, end: i - silenceCount))
                    currentStart = nil
                }
            }
        }
        
        // 最後の範囲を追加
        if let start = currentStart {
            nonSilentRanges.append((start: start, end: frameLength))
        }
        
        // 無音削除なしの場合は元のデータを返す
        if nonSilentRanges.isEmpty || (nonSilentRanges.count == 1 && nonSilentRanges[0].start == 0 && nonSilentRanges[0].end == frameLength) {
            print("📊 No significant silence detected, returning original audio")
            return audioData
        }
        
        // 非無音部分を結合
        let totalNonSilentFrames = nonSilentRanges.reduce(0) { $0 + ($1.end - $1.start) }
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(totalNonSilentFrames)) else {
            throw AudioOptimizerError.bufferCreationFailed
        }
        
        var outputIndex = 0
        for range in nonSilentRanges {
            let rangeLength = range.end - range.start
            for i in 0..<Int(audioFormat.channelCount) {
                let sourcePointer = channelData[i] + range.start
                let destPointer = outputBuffer.floatChannelData![i] + outputIndex
                destPointer.initialize(from: sourcePointer, count: rangeLength)
            }
            outputIndex += rangeLength
        }
        
        outputBuffer.frameLength = AVAudioFrameCount(totalNonSilentFrames)
        
        // バッファを新しいファイルに書き込み
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("optimized_\(UUID().uuidString).m4a")
        
        defer {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: audioFormat.settings)
        try outputFile.write(from: outputBuffer)
        
        let optimizedData = try Data(contentsOf: outputURL)
        
        let reductionPercent = (1.0 - Double(optimizedData.count) / Double(audioData.count)) * 100.0
        print("📊 Silence removed: \(String(format: "%.1f", reductionPercent))% reduction (\(audioData.count) → \(optimizedData.count) bytes)")
        
        return optimizedData
    }
    
    // MARK: - Compression
    
    /// 音声データを最適な圧縮率で圧縮
    /// - Parameters:
    ///   - audioData: 元の音声データ
    ///   - quality: 品質（0.0〜1.0、デフォルト: 0.7）
    /// - Returns: 圧縮された音声データ
    static func compressAudio(_ audioData: Data, quality: Float = 0.7) async throws -> Data {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_\(UUID().uuidString).m4a")
        try audioData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let audioFile = try AVAudioFile(forReading: tempURL)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount) else {
            throw AudioOptimizerError.invalidAudioData
        }
        
        try audioFile.read(into: audioBuffer)
        
        // 圧縮設定（ビットレートを品質に応じて調整）
        let bitRate = Int(64000 * quality) // 64kbps * quality
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("compressed_\(UUID().uuidString).m4a")
        
        defer {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: audioFormat.sampleRate,
            AVNumberOfChannelsKey: audioFormat.channelCount,
            AVEncoderBitRateKey: bitRate,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)
        try outputFile.write(from: audioBuffer)
        
        let compressedData = try Data(contentsOf: outputURL)
        
        let reductionPercent = (1.0 - Double(compressedData.count) / Double(audioData.count)) * 100.0
        print("📊 Audio compressed: \(String(format: "%.1f", reductionPercent))% reduction (\(audioData.count) → \(compressedData.count) bytes)")
        
        return compressedData
    }
    
    // MARK: - Cost Estimation
    
    /// 音声データの処理コストを推定
    /// - Parameters:
    ///   - audioData: 音声データ
    ///   - model: 使用するモデル
    ///   - isTranslation: 翻訳かどうか
    /// - Returns: 推定コスト（USD）
    static func estimateCost(for audioData: Data, model: String, isTranslation: Bool = false) async throws -> Double {
        let duration = try await getAudioDuration(audioData)
        
        let baseCostPerMinute: Double
        
        switch model {
        case "whisper-1":
            baseCostPerMinute = 0.006
        case "gpt-4o-transcribe":
            baseCostPerMinute = 0.006
        case "gpt-4o-mini-transcribe":
            baseCostPerMinute = 0.003
        default:
            baseCostPerMinute = 0.006
        }
        
        let minutes = duration / 60.0
        var cost = minutes * baseCostPerMinute
        
        if isTranslation {
            cost += 0.001
        }
        
        return cost
    }
    
    /// 音声データの長さを取得
    private static func getAudioDuration(_ audioData: Data) async throws -> TimeInterval {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_\(UUID().uuidString).m4a")
        try audioData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let audioFile = try AVAudioFile(forReading: tempURL)
        let frameCount = audioFile.length
        let sampleRate = audioFile.processingFormat.sampleRate
        
        return Double(frameCount) / sampleRate
    }
    
    // MARK: - Cost Comparison
    
    /// 最適化前後のコスト比較
    static func compareOptimization(originalData: Data, optimizedData: Data, model: String, isTranslation: Bool = false) async throws -> CostComparison {
        let originalCost = try await estimateCost(for: originalData, model: model, isTranslation: isTranslation)
        let optimizedCost = try await estimateCost(for: optimizedData, model: model, isTranslation: isTranslation)
        
        let originalDuration = try await getAudioDuration(originalData)
        let optimizedDuration = try await getAudioDuration(optimizedData)
        
        return CostComparison(
            originalCost: originalCost,
            optimizedCost: optimizedCost,
            savings: originalCost - optimizedCost,
            savingsPercent: ((originalCost - optimizedCost) / originalCost) * 100.0,
            originalDuration: originalDuration,
            optimizedDuration: optimizedDuration,
            originalSize: originalData.count,
            optimizedSize: optimizedData.count
        )
    }
}

// MARK: - Supporting Types

struct CostComparison {
    let originalCost: Double
    let optimizedCost: Double
    let savings: Double
    let savingsPercent: Double
    let originalDuration: TimeInterval
    let optimizedDuration: TimeInterval
    let originalSize: Int
    let optimizedSize: Int
    
    var savingsDescription: String {
        return String(format: "Saved $%.4f (%.1f%%) - Duration: %.1fs → %.1fs, Size: %.1fMB → %.1fMB",
                     savings, savingsPercent,
                     originalDuration, optimizedDuration,
                     Double(originalSize) / 1_048_576, Double(optimizedSize) / 1_048_576)
    }
}

enum AudioOptimizerError: LocalizedError {
    case invalidAudioData
    case bufferCreationFailed
    case fileOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "Invalid audio data format"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .fileOperationFailed:
            return "File operation failed"
        }
    }
}

