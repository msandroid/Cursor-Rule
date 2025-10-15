//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation

class ModelNameMapper {
    static let shared = ModelNameMapper()
    
    private var modelNameMap: [String: String] = [:]
    
    private init() {
        loadModelNames()
    }
    
    private func loadModelNames() {
        // ハードコードされたモデル名マッピング
        modelNameMap = [
            "openai_whisper-tiny.en": "Cription Swift English",
            "openai_whisper-base.en": "Cription mini English", 
            "openai_whisper-small.en": "Cription Pro English",
            "openai_whisper-medium.en": "Cription Enterprise English",
            
            "openai_whisper-tiny": "Cription Swift",
            "openai_whisper-base": "Cription mini",
            "openai_whisper-small": "Cription Pro", 
            "openai_whisper-medium": "Cription Enterprise",
            "openai_whisper-large-v2": "Cription Ultra",
            "openai_whisper-large-v2_turbo": "Cription UltraTurbo",
            "openai_whisper-large-v3": "Cription Ultra",
            "openai_whisper-large-v3_turbo": "Cription UltraTurbo",
            
            "openai_whisper-small.en_217MB": "Quantum Cription English",
            
            "openai_whisper-small_216MB": "Quantum Cription mini",
            "openai_whisper-large-v2_949MB": "Quantum Cription UltraLite 1.0",
            "openai_whisper-large-v2_turbo_955MB": "Quantum Cription UltraTurboLite 2.0",
            "openai_whisper-large-v3_947MB": "Quantum Cription UltraLite 3.0",
            "openai_whisper-large-v3_turbo_954MB": "Quantum Cription UltraTurboLite 3.5",
            
            "openai_whisper-large-v3-v20240930": "Quantum Cription Ultra 3.6",
            "openai_whisper-large-v3-v20240930_turbo": "Quantum Cription UltraTurbo 3.6",
            "openai_whisper-large-v3-v20240930_547MB": "Quantum Cription UltraLite 3.6",
            "openai_whisper-large-v3-v20240930_626MB": "Quantum Cription UltraLite+ 3.6",
            "openai_whisper-large-v3-v20240930_turbo_632MB": "Quantum Cription UltraTurboLite 3.6",
            
            "distil-whisper_distil-large-v3": "Cription Dual 3.0",
            "distil-whisper_distil-large-v3_594MB": "Cription Dual 0.5",
            "distil-whisper_distil-large-v3_turbo": "Cription Dual 1.5",
            "distil-whisper_distil-large-v3_turbo_600MB": "Cription Dual 0.6"
        ]
        
        print("Loaded \(modelNameMap.count) model name mappings")
    }
    
    func getDisplayName(for modelId: String) -> String {
        // まずハードコードされたマッピングから検索
        if let displayName = modelNameMap[modelId] {
            return displayName
        }
        
        // WhisperModelsから検索
        if let model = WhisperModels.shared.getModel(by: modelId) {
            return model.displayName
        }
        
        // フォールバック: モデルIDから表示名を生成
        return modelId.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
    func getModelId(for displayName: String) -> String {
        // 表示名から元のモデルIDを逆引き
        for (modelId, name) in modelNameMap {
            if name == displayName {
                return modelId
            }
        }
        
        // WhisperModelsから検索
        if let model = WhisperModels.shared.allModels.first(where: { $0.displayName == displayName }) {
            return model.id
        }
        
        // フォールバック: 表示名をそのまま返す
        return displayName
    }
}
