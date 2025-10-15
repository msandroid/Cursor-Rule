//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


/// Token計算機能を提供するクラス
class TokenCalculator: ObservableObject {
    @Published var inputText: String = ""
    @Published var tokenCount: Int = 0
    @Published var characterCount: Int = 0
    @Published var wordCount: Int = 0
    @Published var estimatedCost: Double = 0.0
    @Published var detectedLanguage: LanguageType = .unknown
    @Published var languageConfidence: Double = 0.0
    @Published var audioDuration: Double = 0.0  // 音声の長さ（秒）
    @Published var selectedModel: String = "gpt-4o-transcribe"  // 選択されたモデル
    @Published var isTranslation: Bool = false  // 翻訳処理かどうか
    @Published var translationCost: Double = 0.0  // 翻訳コスト
    
    // 料金設定（音声文字起こし用・分単位）
    // OpenAI Whisper API料金（2025年最新）
    private let whisperCostPerMinute: Double = 0.006  // whisper-1
    private let gpt4oTranscribeCostPerMinute: Double = 0.006  // gpt-4o-transcribe
    private let gpt4oMiniTranscribeCostPerMinute: Double = 0.003  // gpt-4o-mini-transcribe
    
    // テキスト翻訳用料金（GPT-4o-mini）
    private let gpt4oMiniInputCostPer1KTokens: Double = 0.000075  // GPT-4o-mini input ($0.075/1M tokens)
    private let gpt4oMiniOutputCostPer1KTokens: Double = 0.0003   // GPT-4o-mini output ($0.30/1M tokens)
    
    // テキストベースの料金（参考用・GPT-4o）
    private let textInputCostPer1KTokens: Double = 0.0025  // GPT-4o input
    private let textOutputCostPer1KTokens: Double = 0.01  // GPT-4o output
    
    // パフォーマンス最適化用
    private var isRealtimeProcessing: Bool = false
    private var languageCache: [String: (LanguageType, Double)] = [:]
    private var lastProcessedText: String = ""
    private var batchUpdateTimer: Timer?
    
    init() {
        updateCounts()
    }
    
    /// テキストの各種カウントを更新
    func updateCounts() {
        // リアルタイム処理中は軽量な更新のみ
        if isRealtimeProcessing {
            characterCount = inputText.count
            wordCount = countWords(in: inputText)
            // 言語判定とトークン計算はスキップ
            return
        }
        
        characterCount = inputText.count
        wordCount = countWords(in: inputText)
        detectLanguage()
        tokenCount = estimateTokenCount(for: inputText)
        estimatedCost = calculateEstimatedCost()
    }
    
    /// バックグラウンドでトークン計算を実行
    func updateCountsInBackground() {
        Task {
            await MainActor.run {
                characterCount = inputText.count
                wordCount = countWords(in: inputText)
            }
            
            // バックグラウンドで重い処理を実行
            let backgroundLanguage = await detectLanguageInBackground()
            let backgroundTokenCount = await estimateTokenCountInBackground()
            let backgroundCost = await calculateEstimatedCostInBackground()
            
            await MainActor.run {
                detectedLanguage = backgroundLanguage.0
                languageConfidence = backgroundLanguage.1
                tokenCount = backgroundTokenCount
                estimatedCost = backgroundCost
            }
        }
    }
    
    /// バックグラウンドで言語検出
    private func detectLanguageInBackground() async -> (LanguageType, Double) {
        // キャッシュチェック
        if let cached = languageCache[inputText] {
            return cached
        }
        
        // テキストが短すぎる場合はスキップ
        guard inputText.count > 10 else {
            return (.unknown, 0.0)
        }
        
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            return (.unknown, 0.0)
        }
        
        let languageScores = calculateLanguageScores(for: trimmedText)
        let sortedLanguages = languageScores.sorted { $0.value > $1.value }
        
        if let topLanguage = sortedLanguages.first {
            // キャッシュに保存（最大100エントリ）
            if languageCache.count > 10000 {
                let firstKey = languageCache.keys.first!
                languageCache.removeValue(forKey: firstKey)
            }
            languageCache[inputText] = (topLanguage.key, topLanguage.value)
            return (topLanguage.key, topLanguage.value)
        } else {
            return (.unknown, 0.0)
        }
    }
    
    /// バックグラウンドでトークン数推定
    private func estimateTokenCountInBackground() async -> Int {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            return 0
        }
        
        let totalCharacters = trimmedText.count
        let ratio = detectedLanguage.tokenRatio
        
        return Int(Double(totalCharacters) / ratio)
    }
    
    /// バックグラウンドでコスト計算
    private func calculateEstimatedCostInBackground() async -> Double {
        return calculateEstimatedCost()
    }
    
    /// リアルタイム処理モードの設定
    func setRealtimeProcessing(_ enabled: Bool) {
        isRealtimeProcessing = enabled
        if !enabled && inputText != lastProcessedText {
            // リアルタイム処理終了時にバッチ更新
            scheduleBatchUpdate()
        }
    }
    
    /// バッチ更新のスケジュール
    private func scheduleBatchUpdate() {
        batchUpdateTimer?.invalidate()
        batchUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performBatchUpdate()
        }
    }
    
    /// バッチ更新の実行
    private func performBatchUpdate() {
        guard !isRealtimeProcessing else { return }
        
        detectLanguage()
        tokenCount = estimateTokenCount(for: inputText)
        estimatedCost = calculateEstimatedCost()
        lastProcessedText = inputText
    }
    
    /// テキストを設定してカウントを更新
    func setText(_ text: String) {
        inputText = text
        updateCounts()
    }
    
    /// テキストをクリア
    func clearText() {
        inputText = ""
        audioDuration = 0.0
        selectedModel = "gpt-4o-transcribe"
        updateCounts()
    }
    
    /// 単語数をカウント
    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    /// 言語を検出（キャッシュ機能付き）
    private func detectLanguage() {
        // キャッシュチェック
        if let cached = languageCache[inputText] {
            detectedLanguage = cached.0
            languageConfidence = cached.1
            return
        }
        
        // テキストが短すぎる場合はスキップ
        guard inputText.count > 10 else {
            detectedLanguage = .unknown
            languageConfidence = 0.0
            return
        }
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            detectedLanguage = .unknown
            languageConfidence = 0.0
            return
        }
        
        let languageScores = calculateLanguageScores(for: trimmedText)
        let sortedLanguages = languageScores.sorted { $0.value > $1.value }
        
        if let topLanguage = sortedLanguages.first {
            detectedLanguage = topLanguage.key
            languageConfidence = topLanguage.value
            
            // キャッシュに保存（最大100エントリ）
            if languageCache.count > 10000 {
                let firstKey = languageCache.keys.first!
                languageCache.removeValue(forKey: firstKey)
            }
            languageCache[inputText] = (topLanguage.key, topLanguage.value)
        } else {
            detectedLanguage = .unknown
            languageConfidence = 0.0
        }
    }
    
    /// 各言語のスコアを計算（100言語対応）
    private func calculateLanguageScores(for text: String) -> [LanguageType: Double] {
        var scores: [LanguageType: Double] = [:]
        let totalChars = text.count
        
        // CJK言語の検出
        let cjkChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x4E00...0x9FFF).contains(scalar.value) || // CJK統合漢字
                   (0x3400...0x4DBF).contains(scalar.value)    // CJK拡張A
        }.count
        
        // 日本語文字の検出
        let japaneseChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x3040...0x309F).contains(scalar.value) || // ひらがな
                   (0x30A0...0x30FF).contains(scalar.value)    // カタカナ
        }.count
        
        // 韓国語文字の検出
        let koreanChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0xAC00...0xD7AF).contains(scalar.value) || // ハングル音節
                   (0x1100...0x11FF).contains(scalar.value) || // ハングル子音
                   (0x3130...0x318F).contains(scalar.value)    // ハングル互換文字
        }.count
        
        // タイ語文字の検出
        let thaiChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0E00...0x0E7F).contains(scalar.value)    // タイ語
        }.count
        
        // ベトナム語文字の検出
        let vietnameseChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x1EA0...0x1EF9).contains(scalar.value)    // ベトナム語拡張
        }.count
        
        // アラビア語文字の検出
        let arabicChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0600...0x06FF).contains(scalar.value) || // アラビア語
                   (0x0750...0x077F).contains(scalar.value)    // アラビア語補助
        }.count
        
        // ペルシャ語文字の検出
        let persianChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0xFB50...0xFDFF).contains(scalar.value) || // アラビア語表示形式A
                   (0xFE70...0xFEFF).contains(scalar.value)    // アラビア語表示形式B
        }.count
        
        // ヒンディー語文字の検出
        let hindiChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0900...0x097F).contains(scalar.value)    // デーヴァナーガリー
        }.count
        
        // ベンガル語文字の検出
        let bengaliChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0980...0x09FF).contains(scalar.value)    // ベンガル語
        }.count
        
        // タミル語文字の検出
        let tamilChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0B80...0x0BFF).contains(scalar.value)    // タミル語
        }.count
        
        // テルグ語文字の検出
        let teluguChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0C00...0x0C7F).contains(scalar.value)    // テルグ語
        }.count
        
        // マラヤーラム語文字の検出
        let malayalamChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0D00...0x0D7F).contains(scalar.value)    // マラヤーラム語
        }.count
        
        // カンナダ語文字の検出
        let kannadaChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0C80...0x0CFF).contains(scalar.value)    // カンナダ語
        }.count
        
        // グジャラート語文字の検出
        let gujaratiChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0A80...0x0AFF).contains(scalar.value)    // グジャラート語
        }.count
        
        // パンジャブ語文字の検出
        let punjabiChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0A00...0x0A7F).contains(scalar.value)    // グルムキー文字
        }.count
        
        // シンハラ語文字の検出
        let sinhalaChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0D80...0x0DFF).contains(scalar.value)    // シンハラ語
        }.count
        
        // ネパール語文字の検出
        let nepaliChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0900...0x097F).contains(scalar.value)    // デーヴァナーガリー（ネパール語も使用）
        }.count
        
        // アッサム語文字の検出
        let assameseChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0980...0x09FF).contains(scalar.value)    // ベンガル語（アッサム語も使用）
        }.count
        
        // マラーティー語文字の検出
        let marathiChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0900...0x097F).contains(scalar.value)    // デーヴァナーガリー（マラーティー語も使用）
        }.count
        
        // キリル文字の検出（ロシア語、ウクライナ語、ブルガリア語など）
        let cyrillicChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0400...0x04FF).contains(scalar.value) || // キリル文字
                   (0x0500...0x052F).contains(scalar.value)    // キリル文字補助
        }.count
        
        // ギリシャ語文字の検出
        let greekChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0370...0x03FF).contains(scalar.value) || // ギリシャ語
                   (0x1F00...0x1FFF).contains(scalar.value)    // ギリシャ語拡張
        }.count
        
        // ヘブライ語文字の検出
        let hebrewChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0590...0x05FF).contains(scalar.value)    // ヘブライ語
        }.count
        
        // アルメニア語文字の検出
        let armenianChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0530...0x058F).contains(scalar.value)    // アルメニア語
        }.count
        
        // グルジア語文字の検出
        let georgianChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x10A0...0x10FF).contains(scalar.value) || // グルジア語
                   (0x2D00...0x2D2F).contains(scalar.value)    // グルジア語補助
        }.count
        
        // モンゴル語文字の検出
        let mongolianChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x1800...0x18AF).contains(scalar.value)    // モンゴル語
        }.count
        
        // ミャンマー語文字の検出
        let myanmarChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x1000...0x109F).contains(scalar.value)    // ミャンマー語
        }.count
        
        // クメール語文字の検出
        let khmerChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x1780...0x17FF).contains(scalar.value)    // クメール語
        }.count
        
        // ラオ語文字の検出
        let laoChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0E80...0x0EFF).contains(scalar.value)    // ラオ語
        }.count
        
        // チベット語文字の検出
        let tibetanChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0F00...0x0FFF).contains(scalar.value)    // チベット語
        }.count
        
        // エチオピア語（アムハラ語）文字の検出
        let amharicChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x1200...0x137F).contains(scalar.value)    // エチオピア語
        }.count
        
        // イディッシュ語文字の検出
        let yiddishChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0590...0x05FF).contains(scalar.value)    // ヘブライ語（イディッシュ語も使用）
        }.count
        
        // ラテン文字の検出（英語、スペイン語、フランス語、ドイツ語など）
        let latinChars = text.filter { character in
            let scalar = character.unicodeScalars.first!
            return (0x0020...0x007F).contains(scalar.value) || // 基本ラテン文字
                   (0x00A0...0x00FF).contains(scalar.value) || // ラテン文字補助
                   (0x0100...0x017F).contains(scalar.value) || // ラテン文字拡張A
                   (0x0180...0x024F).contains(scalar.value)    // ラテン文字拡張B
        }.count
        
        // 各言語のスコアを計算
        scores[.chinese] = Double(cjkChars - japaneseChars - koreanChars) / Double(totalChars)
        scores[.japanese] = Double(japaneseChars + Int(Double(cjkChars) * 0.3)) / Double(totalChars)
        scores[.korean] = Double(koreanChars) / Double(totalChars)
        scores[.cantonese] = Double(Int(Double(cjkChars) * 0.1)) / Double(totalChars)
        scores[.thai] = Double(thaiChars) / Double(totalChars)
        scores[.vietnamese] = Double(vietnameseChars) / Double(totalChars)
        scores[.lao] = Double(laoChars) / Double(totalChars)
        scores[.khmer] = Double(khmerChars) / Double(totalChars)
        scores[.myanmar] = Double(myanmarChars) / Double(totalChars)
        scores[.tibetan] = Double(tibetanChars) / Double(totalChars)
        
        scores[.arabic] = Double(arabicChars) / Double(totalChars)
        scores[.persian] = Double(persianChars) / Double(totalChars)
        scores[.urdu] = Double(Int(Double(arabicChars) * 0.2)) / Double(totalChars)
        scores[.pashto] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        scores[.turkmen] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        scores[.tajik] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        scores[.uzbek] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        scores[.kazakh] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        
        scores[.hindi] = Double(hindiChars) / Double(totalChars)
        scores[.bengali] = Double(bengaliChars) / Double(totalChars)
        scores[.tamil] = Double(tamilChars) / Double(totalChars)
        scores[.telugu] = Double(teluguChars) / Double(totalChars)
        scores[.malayalam] = Double(malayalamChars) / Double(totalChars)
        scores[.kannada] = Double(kannadaChars) / Double(totalChars)
        scores[.gujarati] = Double(gujaratiChars) / Double(totalChars)
        scores[.punjabi] = Double(punjabiChars) / Double(totalChars)
        scores[.sinhala] = Double(sinhalaChars) / Double(totalChars)
        scores[.nepali] = Double(nepaliChars) / Double(totalChars)
        scores[.assamese] = Double(assameseChars) / Double(totalChars)
        scores[.marathi] = Double(marathiChars) / Double(totalChars)
        scores[.sindhi] = Double(Int(Double(arabicChars) * 0.1)) / Double(totalChars)
        
        scores[.russian] = Double(Int(Double(cyrillicChars) * 0.4)) / Double(totalChars)
        scores[.ukrainian] = Double(Int(Double(cyrillicChars) * 0.2)) / Double(totalChars)
        scores[.bulgarian] = Double(Int(Double(cyrillicChars) * 0.1)) / Double(totalChars)
        scores[.macedonian] = Double(Int(Double(cyrillicChars) * 0.1)) / Double(totalChars)
        scores[.serbian] = Double(Int(Double(cyrillicChars) * 0.1)) / Double(totalChars)
        scores[.belarusian] = Double(Int(Double(cyrillicChars) * 0.1)) / Double(totalChars)
        
        scores[.greek] = Double(greekChars) / Double(totalChars)
        scores[.hebrew] = Double(hebrewChars) / Double(totalChars)
        scores[.armenian] = Double(armenianChars) / Double(totalChars)
        scores[.georgian] = Double(georgianChars) / Double(totalChars)
        scores[.mongolian] = Double(mongolianChars) / Double(totalChars)
        scores[.amharic] = Double(amharicChars) / Double(totalChars)
        scores[.yiddish] = Double(yiddishChars) / Double(totalChars)
        
        // ラテン文字系言語（簡易判定）
        let latinRatio = Double(latinChars) / Double(totalChars)
        if latinRatio > 0.7 {
            scores[.english] = latinRatio * 0.3
            scores[.spanish] = latinRatio * 0.2
            scores[.french] = latinRatio * 0.15
            scores[.german] = latinRatio * 0.1
            scores[.italian] = latinRatio * 0.1
            scores[.portuguese] = latinRatio * 0.1
            scores[.dutch] = latinRatio * 0.05
        }
        
        // 混合言語の判定
        let nonZeroScores = scores.filter { $0.value > 0.1 }
        if nonZeroScores.count > 1 {
            scores[.mixed] = 0.8
        }
        
        return scores
    }
    
    /// トークン数を推定（多言語対応版）
    private func estimateTokenCount(for text: String) -> Int {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            return 0
        }
        
        let totalCharacters = trimmedText.count
        let ratio = detectedLanguage.tokenRatio
        
        return Int(Double(totalCharacters) / ratio)
    }
    
    /// 推定コストを計算（音声文字起こし用）
    private func calculateEstimatedCost() -> Double {
        var totalCost: Double = 0.0
        
        // 音声の長さがある場合は音声ベースで計算
        if audioDuration > 0 {
            let durationInMinutes = audioDuration / 60.0
            let costPerMinute: Double
            
            // モデルに応じた料金を選択
            switch selectedModel {
            case "gpt-4o-mini-transcribe":
                costPerMinute = gpt4oMiniTranscribeCostPerMinute
            case "gpt-4o-transcribe":
                costPerMinute = gpt4oTranscribeCostPerMinute
            case "whisper-1":
                costPerMinute = whisperCostPerMinute
            default:
                costPerMinute = gpt4oTranscribeCostPerMinute
            }
            
            totalCost += durationInMinutes * costPerMinute
        }
        
        // 翻訳処理の場合は翻訳コストを追加
        if isTranslation {
            let tokensInThousands = Double(tokenCount) / 1000.0
            let inputCost = tokensInThousands * gpt4oMiniInputCostPer1KTokens
            let outputCost = tokensInThousands * gpt4oMiniOutputCostPer1KTokens
            translationCost = inputCost + outputCost
            totalCost += translationCost
        } else if audioDuration == 0 {
            // 音声情報がない場合はテキストトークンベースで概算
            // ※これは参考値であり、実際の料金とは異なる場合があります
            let tokensInThousands = Double(tokenCount) / 1000.0
            totalCost += tokensInThousands * textInputCostPer1KTokens
        }
        
        return totalCost
    }
    
    /// 音声の長さを設定
    func setAudioDuration(_ duration: Double, model: String = "gpt-4o-transcribe") {
        audioDuration = duration
        selectedModel = model
        estimatedCost = calculateEstimatedCost()
    }
    
    /// 翻訳処理の設定
    func setTranslationMode(_ enabled: Bool) {
        isTranslation = enabled
        estimatedCost = calculateEstimatedCost()
    }
    
    /// 詳細な統計情報を取得
    func getDetailedStats() -> TokenStats {
        return TokenStats(
            tokenCount: tokenCount,
            characterCount: characterCount,
            wordCount: wordCount,
            estimatedCost: estimatedCost,
            averageTokensPerWord: wordCount > 0 ? Double(tokenCount) / Double(wordCount) : 0,
            averageCharactersPerToken: tokenCount > 0 ? Double(characterCount) / Double(tokenCount) : 0,
            detectedLanguage: detectedLanguage,
            languageConfidence: languageConfidence,
            audioDuration: audioDuration,
            selectedModel: selectedModel,
            isTranslation: isTranslation,
            translationCost: translationCost
        )
    }
}


