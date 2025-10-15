//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI

/// STT完了後のトークン計算を管理するサービス
@MainActor
class TokenCalculationService: ObservableObject {
    static let shared = TokenCalculationService()
    
    @Published var isCalculating = false
    @Published var lastCalculationResult: TokenStats?
    
    private init() {}
    
    /// STT完了後のテキストでトークン計算を実行
    func calculateTokensForTranCription(finalText: String, duration: Double = 0.0, model: String = "gpt-4o-transcribe", isTranslation: Bool = false) async {
        guard !finalText.isEmpty else { return }
        
        isCalculating = true
        
        // TokenCalculatorのインスタンスを作成
        let tokenCalculator = TokenCalculator()
        tokenCalculator.setText(finalText)
        
        // 翻訳処理の設定
        tokenCalculator.setTranslationMode(isTranslation)
        
        // 音声の長さとモデル情報を設定
        if duration > 0 {
            tokenCalculator.setAudioDuration(duration, model: model)
        }
        
        // トークン計算を実行
        tokenCalculator.updateCounts()
        
        // 計算結果を保存
        let stats = tokenCalculator.getDetailedStats()
        lastCalculationResult = stats
        
        // 計算結果をログ出力
        if duration > 0 {
            if isTranslation {
                print("Token calculation completed: \(stats.tokenCount) tokens, \(String(format: "%.4f", stats.estimatedCost)) USD (transcription: \(String(format: "%.1f", duration))s audio with \(model) + translation)")
            } else {
                print("Token calculation completed: \(stats.tokenCount) tokens, \(String(format: "%.4f", stats.estimatedCost)) USD (based on \(String(format: "%.1f", duration))s audio with \(model))")
            }
        } else {
            if isTranslation {
                print("Token calculation completed: \(stats.tokenCount) tokens, \(String(format: "%.4f", stats.estimatedCost)) USD (translation only)")
            } else {
                print("Token calculation completed: \(stats.tokenCount) tokens, \(String(format: "%.4f", stats.estimatedCost)) USD (estimated)")
            }
        }
        
        isCalculating = false
    }
    
    /// 計算結果をクリア
    func clearResults() {
        lastCalculationResult = nil
        isCalculating = false
    }
    
    /// 計算結果を取得
    func getLastResult() -> TokenStats? {
        return lastCalculationResult
    }
}