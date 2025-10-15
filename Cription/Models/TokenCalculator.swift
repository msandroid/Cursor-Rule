//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

/// トークン計算器
class TokenCalculator {
    private var _inputText: String = ""
    private var _audioDuration: Double = 0.0
    private var _selectedModel: String = "gpt-4o-transcribe"
    private var _isTranslation: Bool = false
    
    var inputText: String {
        get { _inputText }
        set { _inputText = newValue }
    }
    
    var audioDuration: Double {
        get { _audioDuration }
    }
    
    var selectedModel: String {
        get { _selectedModel }
    }
    
    var detectedLanguage: LanguageType {
        return detectLanguage(_inputText)
    }
    
    var languageConfidence: Double {
        return calculateLanguageConfidence(_inputText)
    }
    
    var tokenCount: Int {
        return calculateTokenCount(_inputText)
    }
    
    var characterCount: Int {
        return _inputText.count
    }
    
    var wordCount: Int {
        return _inputText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var estimatedCost: Double {
        return calculateEstimatedCost()
    }
    
    var averageTokensPerWord: Double {
        guard wordCount > 0 else { return 0.0 }
        return Double(tokenCount) / Double(wordCount)
    }
    
    var averageCharactersPerToken: Double {
        guard tokenCount > 0 else { return 0.0 }
        return Double(characterCount) / Double(tokenCount)
    }
    
    func setText(_ text: String) {
        _inputText = text
    }
    
    func setAudioDuration(_ duration: Double, model: String) {
        _audioDuration = duration
        _selectedModel = model
    }
    
    func setTranslationMode(_ isTranslation: Bool) {
        _isTranslation = isTranslation
    }
    
    func updateCounts() {
        // 計算は computed properties で自動的に行われる
    }
    
    func clearText() {
        _inputText = ""
        _audioDuration = 0.0
        _isTranslation = false
    }
    
    func getDetailedStats() -> TokenStats {
        return TokenStats(
            tokenCount: tokenCount,
            characterCount: characterCount,
            wordCount: wordCount,
            estimatedCost: estimatedCost,
            averageTokensPerWord: averageTokensPerWord,
            averageCharactersPerToken: averageCharactersPerToken,
            detectedLanguage: detectedLanguage,
            languageConfidence: languageConfidence,
            audioDuration: _audioDuration,
            selectedModel: _selectedModel,
            isTranslation: _isTranslation,
            translationCost: _isTranslation ? estimatedCost * 0.5 : 0.0
        )
    }
    
    // MARK: - Private Methods
    
    private func detectLanguage(_ text: String) -> LanguageType {
        // 簡単な言語検出ロジック
        let text = text.lowercased()
        
        // 日本語の検出
        if text.contains(where: { $0.isJapanese }) {
            return .japanese
        }
        
        // 中国語の検出
        if text.contains(where: { $0.isChinese }) {
            return .chinese
        }
        
        // 韓国語の検出
        if text.contains(where: { $0.isKorean }) {
            return .korean
        }
        
        // アラビア語の検出
        if text.contains(where: { $0.isArabic }) {
            return .arabic
        }
        
        // ロシア語の検出
        if text.contains(where: { $0.isCyrillic }) {
            return .russian
        }
        
        // その他の言語は英語として扱う
        return .english
    }
    
    private func calculateLanguageConfidence(_ text: String) -> Double {
        let detectedLang = detectLanguage(text)
        
        // 簡単な信頼度計算
        switch detectedLang {
        case .japanese, .chinese, .korean:
            return 0.9
        case .arabic, .russian:
            return 0.8
        case .english:
            return 0.7
        default:
            return 0.6
        }
    }
    
    private func calculateTokenCount(_ text: String) -> Int {
        let detectedLang = detectLanguage(text)
        let ratio = detectedLang.tokenRatio
        
        // 文字数からトークン数を推定
        return Int(Double(text.count) / ratio)
    }
    
    private func calculateEstimatedCost() -> Double {
        if _audioDuration > 0 {
            // 音声文字起こしの料金計算
            let minutes = _audioDuration / 60.0
            let ratePerMinute: Double
            
            switch _selectedModel {
            case "whisper-1", "gpt-4o-transcribe":
                ratePerMinute = 0.006
            case "gpt-4o-mini-transcribe":
                ratePerMinute = 0.003
            default:
                ratePerMinute = 0.006
            }
            
            let baseCost = minutes * ratePerMinute
            
            if _isTranslation {
                return baseCost + (baseCost * 0.5) // 翻訳コストを追加
            }
            
            return baseCost
        } else {
            // テキストベースの料金計算（参考）
            let tokens = tokenCount
            let ratePer1KTokens: Double = 0.0025 // GPT-4o input rate
            return (Double(tokens) / 1000.0) * ratePer1KTokens
        }
    }
}

// MARK: - Character Extensions

extension Character {
    var isJapanese: Bool {
        return self.unicodeScalars.contains { scalar in
            (0x3040...0x309F).contains(scalar.value) || // Hiragana
            (0x30A0...0x30FF).contains(scalar.value) || // Katakana
            (0x4E00...0x9FAF).contains(scalar.value)    // Kanji
        }
    }
    
    var isChinese: Bool {
        return self.unicodeScalars.contains { scalar in
            (0x4E00...0x9FAF).contains(scalar.value) || // CJK Unified Ideographs
            (0x3400...0x4DBF).contains(scalar.value)    // CJK Extension A
        }
    }
    
    var isKorean: Bool {
        return self.unicodeScalars.contains { scalar in
            (0xAC00...0xD7AF).contains(scalar.value) || // Hangul Syllables
            (0x1100...0x11FF).contains(scalar.value) || // Hangul Jamo
            (0x3130...0x318F).contains(scalar.value)    // Hangul Compatibility Jamo
        }
    }
    
    var isArabic: Bool {
        return self.unicodeScalars.contains { scalar in
            (0x0600...0x06FF).contains(scalar.value) || // Arabic
            (0x0750...0x077F).contains(scalar.value)    // Arabic Supplement
        }
    }
    
    var isCyrillic: Bool {
        return self.unicodeScalars.contains { scalar in
            (0x0400...0x04FF).contains(scalar.value) || // Cyrillic
            (0x0500...0x052F).contains(scalar.value)    // Cyrillic Supplement
        }
    }
}

