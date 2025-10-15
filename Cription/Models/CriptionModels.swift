//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import StoreKit
import WhisperKit

// MARK: - Whisper Model Data Structure

struct WhisperModel {
    let id: String
    let displayName: String
    let size: String
    let languages: String
    let deCription: String
    let category: ModelCategory
    let quantization: QuantizationType?
    let specialFeatures: [SpecialFeature]
    let inputPrice: Double  // Price per 1M tokens for input
    let outputPrice: Double // Price per 1M tokens for output
}

enum ModelCategory: String, CaseIterable {
    case basicEnglish = "Basic (English Only)"
    case basicMultilingual = "Basic (Multilingual)"
    case quantizedEnglish = "Quantized (English Only)"
    case quantizedMultilingual = "Quantized (Multilingual)"
    case special = "Special Features"
    case openaiTranCription = "OpenAI TranScription"
    case fireworksASR = "Fireworks ASR"
    case parakeetASR = "Parakeet ASR"
}

enum QuantizationType: String, CaseIterable {
    case q5_0 = "Q5_0"
    case q5_1 = "High Quality"
    case q8_0 = "Most High QUality"
    
    var deCription: String {
        switch self {
        case .q5_0:
            return "5-bit quantization (high compression)"
        case .q5_1:
            return "5-bit quantization (improved)"
        case .q8_0:
            return "8-bit quantization (high precision)"
        }
    }
}

enum SpecialFeature: String, CaseIterable {
    case speakerDiarization = "Speaker Diarization"
    case turbo = "Turbo"
    
    var deCription: String {
        switch self {
        case .speakerDiarization:
            return "Speaker separation (tinydiarize)"
        case .turbo:
            return "High-speed version"
        }
    }
}

// MARK: - Whisper Models Data

class WhisperModels {
    static let shared = WhisperModels()
    
    private init() {}
    
    let allModels: [WhisperModel] = [
        // Basic Models (English Only)
        WhisperModel(
            id: "openai_whisper-tiny.en",
            displayName: "Cription Swift English",
            size: "75 MiB",
            languages: "English Only",
            deCription: "Smallest & Fastest",
            category: .basicEnglish,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,  // Free for Whisper models
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-base.en",
            displayName: "Cription mini English",
            size: "142 MiB",
            languages: "English Only",
            deCription: "Balanced",
            category: .basicEnglish,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-small.en",
            displayName: "Cription Pro English",
            size: "466 MiB",
            languages: "English Only",
            deCription: "Medium Size",
            category: .basicEnglish,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-medium.en",
            displayName: "Cription Enterprise English",
            size: "1.5 GiB",
            languages: "English Only",
            deCription: "Large Size",
            category: .basicEnglish,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Basic Models (Multilingual)
        WhisperModel(
            id: "openai_whisper-tiny",
            displayName: "Cription Swift",
            size: "75 MiB",
            languages: "99 Languages",
            deCription: "Smallest & Fastest",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-base",
            displayName: "Cription mini",
            size: "142 MiB",
            languages: "99 Languages",
            deCription: "Balanced",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-small",
            displayName: "Cription Pro",
            size: "466 MiB",
            languages: "99 Languages",
            deCription: "Medium Size",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-medium",
            displayName: "Cription Enterprise",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "Large Size",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2",
            displayName: "Cription Ultra",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Improved Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_turbo",
            displayName: "Cription UltraTurbo",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "High-Speed Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3",
            displayName: "Cription Ultra",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Latest Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_turbo",
            displayName: "Cription UltraTurbo",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "High-Speed Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Compressed Models (English Only)
        WhisperModel(
            id: "whisper-small.en_217MB",
            displayName: "Quantum Cription English",
            size: "217 MiB",
            languages: "English Only",
            deCription: "Compressed Version",
            category: .quantizedEnglish,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        
        // Compressed Models (Multilingual)
        WhisperModel(
            id: "openai_whisper-small_216MB",
            displayName: "Quantum Cription mini",
            size: "216 MiB",
            languages: "99 Languages",
            deCription: "Bundled Model",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_949MB",
            displayName: "Quantum Cription UltraLite 1.0",
            size: "949 MiB",
            languages: "99 Languages",
            deCription: "Compressed Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_turbo_955MB",
            displayName: "Quantum Cription UltraTurboLite 2.0",
            size: "955 MiB",
            languages: "99 Languages",
            deCription: "Compressed Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_947MB",
            displayName: "Quantum Cription UltraLite 3.0",
            size: "947 MiB",
            languages: "99 Languages",
            deCription: "Compressed Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_turbo_954MB",
            displayName: "Quantum Cription UltraTurboLite 3.5",
            size: "954 MiB",
            languages: "99 Languages",
            deCription: "Compressed Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Large v3 v20240930 Models
        WhisperModel(
            id: "whisper-large-v3-v20240930",
            displayName: "Quantum Cription Ultra 3.6",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Updated Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_turbo",
            displayName: "Quantum Cription UltraTurbo 3.6",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "Updated Turbo Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Distil-Whisper Models
        WhisperModel(
            id: "distil-whisper_distil-large-v3",
            displayName: "Cription Dual 3.0",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Distilled Version",
            category: .special,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "distil-whisper_distil-large-v3_594MB",
            displayName: "Cription Dual 0.5",
            size: "594 MiB",
            languages: "99 Languages",
            deCription: "Compressed Distilled Version",
            category: .special,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "distil-whisper_distil-large-v3_turbo",
            displayName: "Cription Dual 1.5",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "Distilled Turbo Version",
            category: .special,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "distil-whisper_distil-large-v3_turbo_600MB",
            displayName: "Cription Dual 0.6",
            size: "600 MiB",
            languages: "99 Languages",
            deCription: "Compressed Distilled Turbo Version",
            category: .special,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Additional Large v3 v20240930 Models
        WhisperModel(
            id: "whisper-large-v3-v20240930_547MB",
            displayName: "Quantum Cription UltraLite 3.6",
            size: "547 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_626MB",
            displayName: "Quantum Cription UltraLite+ 3.6",
            size: "626 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_turbo_632MB",
            displayName: "Quantum Cription UltraTurboLite 3.6",
            size: "632 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // Additional bundled models
        WhisperModel(
            id: "whisper-large-v2",
            displayName: "Cription Ultra",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Improved Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_949MB",
            displayName: "Quantum Cription UltraLite 1.0",
            size: "949 MiB",
            languages: "99 Languages",
            deCription: "Compressed Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_turbo",
            displayName: "Cription UltraTurbo",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "High-Speed Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v2_turbo_955MB",
            displayName: "Quantum Cription UltraTurboLite 2.0",
            size: "955 MiB",
            languages: "99 Languages",
            deCription: "Compressed Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3",
            displayName: "Cription Ultra",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Latest Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_947MB",
            displayName: "Quantum Cription UltraLite 3.0",
            size: "947 MiB",
            languages: "99 Languages",
            deCription: "Compressed Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_turbo",
            displayName: "Cription UltraTurbo",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "High-Speed Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3_turbo_954MB",
            displayName: "Quantum Cription UltraTurboLite 3.5",
            size: "954 MiB",
            languages: "99 Languages",
            deCription: "Compressed Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930",
            displayName: "Quantum Cription Ultra 3.6",
            size: "2.9 GiB",
            languages: "99 Languages",
            deCription: "Updated Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_547MB",
            displayName: "Quantum Cription UltraLite 3.6",
            size: "547 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_626MB",
            displayName: "Quantum Cription UltraLite+ 3.6",
            size: "626 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_turbo",
            displayName: "Quantum Cription UltraTurbo 3.6",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "Updated Turbo Version",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-large-v3-v20240930_turbo_632MB",
            displayName: "Quantum Cription UltraTurboLite 3.6",
            size: "632 MiB",
            languages: "99 Languages",
            deCription: "Compressed Updated Turbo Version",
            category: .quantizedMultilingual,
            quantization: .q5_1,
            specialFeatures: [.turbo],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-medium",
            displayName: "Cription Enterprise",
            size: "1.5 GiB",
            languages: "99 Languages",
            deCription: "Large Size",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-medium.en",
            displayName: "Cription Enterprise English",
            size: "1.5 GiB",
            languages: "English Only",
            deCription: "Large Size",
            category: .basicEnglish,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-small",
            displayName: "Cription Pro",
            size: "466 MiB",
            languages: "99 Languages",
            deCription: "Medium Size",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "openai_whisper-small.en_217MB",
            displayName: "Quantum Cription English",
            size: "217 MiB",
            languages: "English Only",
            deCription: "Compressed Version",
            category: .quantizedEnglish,
            quantization: .q5_1,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "whisper-tiny",
            displayName: "Cription Swift",
            size: "75 MiB",
            languages: "99 Languages",
            deCription: "Smallest & Fastest",
            category: .basicMultilingual,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,
            outputPrice: 0.0
        ),
        
        // OpenAI TranCription Models
        WhisperModel(
            id: "whisper-1",
            displayName: "Whisper-1",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "OpenAI Whisper API TranCription",
            category: .openaiTranCription,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.006,  // $0.006 per minute
            outputPrice: 0.0    // No output pricing
        ),
        WhisperModel(
            id: "gpt-4o-transcribe",
            displayName: "GPT-4o Transcribe",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "Advanced AI TranCription",
            category: .openaiTranCription,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 2.50,  // $2.50 per 1M input tokens
            outputPrice: 10.00 // $10.00 per 1M output tokens
        ),
        WhisperModel(
            id: "gpt-4o-mini-transcribe",
            displayName: "GPT-4o Mini Transcribe",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "Fast AI TranCription",
            category: .openaiTranCription,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.15,  // $0.15 per 1M input tokens
            outputPrice: 0.60  // $0.60 per 1M output tokens
        ),
        
        // Fireworks ASR Models
        WhisperModel(
            id: "fireworks-asr-large",
            displayName: "Fireworks ASR Large",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "High-Quality Streaming ASR v1",
            category: .fireworksASR,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0032, // $0.0032 per unit
            outputPrice: 0.0    // No output pricing
        ),
        WhisperModel(
            id: "fireworks-asr-v2",
            displayName: "Fireworks ASR v2",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "Latest Streaming ASR v2 (Preview)",
            category: .fireworksASR,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0035, // $0.0035 per unit
            outputPrice: 0.0    // No output pricing
        ),
        WhisperModel(
            id: "whisper-v3",
            displayName: "Whisper V3",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "High-Quality Speech Processing - Supports transcription, translation, and alignment",
            category: .fireworksASR,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0018, // $0.0018 per unit
            outputPrice: 0.0    // No output pricing
        ),
        WhisperModel(
            id: "whisper-v3-turbo",
            displayName: "Whisper V3 Turbo",
            size: "Cloud",
            languages: "99 Languages",
            deCription: "Fast High-Quality Speech Processing - Supports transcription, translation, and alignment",
            category: .fireworksASR,
            quantization: nil,
            specialFeatures: [.turbo],
            inputPrice: 0.0009, // $0.0009 per unit
            outputPrice: 0.0    // No output pricing
        ),
        
        // Parakeet ASR Models
        WhisperModel(
            id: "parakeet-tdt-0.6b-v3",
            displayName: "Cription European 25",
            size: "Local",
            languages: "25 European Languages",
            deCription: "High-performance multilingual ASR with TDT architecture",
            category: .parakeetASR,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,  // Free for local models
            outputPrice: 0.0
        ),
        WhisperModel(
            id: "parakeet-tdt-0.6b-v2",
            displayName: "Cription Heron English",
            size: "Local",
            languages: "English Only",
            deCription: "High-performance English ASR with optimized vocabulary",
            category: .parakeetASR,
            quantization: nil,
            specialFeatures: [],
            inputPrice: 0.0,  // Free for local models
            outputPrice: 0.0
        ),
        
    ]
    
    // MARK: - Helper Methods
    
    func getModel(by id: String) -> WhisperModel? {
        return allModels.first { $0.id == id }
    }
    
    func getModels(by category: ModelCategory) -> [WhisperModel] {
        return allModels.filter { $0.category == category }
    }
    
    func getRecommendedModels() -> [WhisperModel] {
        return [
            getModel(by: "openai_whisper-tiny")!,
            getModel(by: "openai_whisper-base")!,
            getModel(by: "openai_whisper-large-v3")!,
            getModel(by: "openai_whisper-large-v3-v20240930")!,
            getModel(by: "openai_whisper-large-v3-v20240930_547MB")!,
            getModel(by: "distil-whisper_distil-large-v3")!
        ]
    }
    
    func getModelIds() -> [String] {
        return allModels.map { $0.id }
    }
    
    func getModelDisplayNames() -> [String: String] {
        var displayNames: [String: String] = [:]
        for model in allModels {
            displayNames[model.id] = model.displayName
        }
        return displayNames
    }
}


// MARK: - Supporting Types

struct CriptionWordTiming {
    let word: String
    let start: Double
    let end: Double
    let tokens: [String]
    
    init(word: String, start: Double, end: Double, tokens: [String] = []) {
        self.word = word
        self.start = start
        self.end = end
        self.tokens = tokens
    }
}


struct CriptionTranCriptionResult {
    let text: String
    let segments: [TranCriptionSegment]
    let language: String
    let duration: Double
    let timings: TranCriptionTimings
    let allWords: [String]
    
    init(text: String, segments: [TranCriptionSegment], language: String, duration: Double, timings: TranCriptionTimings = TranCriptionTimings(), allWords: [String] = []) {
        self.text = text
        self.segments = segments
        self.language = language
        self.duration = duration
        self.timings = timings
        self.allWords = allWords
    }
}



// MARK: - OpenAI API Response Models

private struct OpenAITranCriptionResponse: Codable {
    let text: String
    let language: String?
    let duration: Double?
    let segments: [OpenAISegment]?
}

private struct OpenAISegment: Codable {
    let start: Double
    let end: Double
    let text: String
}


// MARK: - TranCription Types

struct TranCriptionResult {
    let text: String
    let segments: [TranCriptionSegment]
    let language: String
    let duration: Double
}

struct TranCriptionSegment {
    let start: Double
    let end: Double
    let text: String
}

struct TranCriptionTimings {
    // Add any timing-related properties as needed
}

struct WordTiming {
    let word: String
    let start: Double
    let end: Double
    let tokens: [String]
}

enum TranCriptionError: LocalizedError {
    case alreadyProcessing
    case fileTooLarge
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case subCriptionRequired
    case subscriptionLimitExceeded
    case modelAccessDenied
    case insufficientCredits
    case openAIServiceNotAvailable
    case openAIAPIKeyNotSet
    case whisperKitNotAvailable
    case whisperModelManagerNotAvailable
    case invalidModel
    case invalidAudioData
    
    var errorDeCription: String? {
        switch self {
        case .alreadyProcessing:
            return "TranCription is already in progress"
        case .fileTooLarge:
            return "Audio file is too large (max 25MB)"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        case .subCriptionRequired:
            return "Premium subCription required for OpenAI tranCription"
        case .subscriptionLimitExceeded:
            return "Monthly usage limit exceeded. Please upgrade your subscription or wait for the next billing cycle."
        case .modelAccessDenied:
            return "This model is not available in your current subscription plan. Please upgrade to access cloud models."
        case .insufficientCredits:
            return "Insufficient credits. Please purchase more credits to continue using API services."
        case .openAIServiceNotAvailable:
            return "OpenAI service is not available"
        case .openAIAPIKeyNotSet:
            return "OpenAI API key is not set. Please configure your API key in settings."
        case .whisperKitNotAvailable:
            return "WhisperKit is not available"
        case .whisperModelManagerNotAvailable:
            return "WhisperModelManager is not available"
        case .invalidModel:
            return "Invalid model configuration"
        case .invalidAudioData:
            return "Invalid audio data format"
        }
    }
}

// MARK: - Type Conversion Utilities

extension CriptionTranCriptionResult {
    static func fromWhisperKit(_ whisperKitResult: TranCriptionResult) -> CriptionTranCriptionResult {
        let segments: [TranCriptionSegment] = whisperKitResult.segments.map { segment in
            let startTime = Double(segment.start)
            let endTime = Double(segment.end)
            let segmentText = segment.text
            // WhisperKit segments may not have tokens property, so we'll use empty array
            let segmentTokens: [String] = []
            // WhisperKit segments may not have words property, so we'll use empty array
            let segmentWords: [WordTiming] = []
            
            return TranCriptionSegment(
                start: startTime,
                end: endTime,
                text: segmentText
            )
        }
        
        // Use default TranCriptionTimings constructor since WhisperKit's timings structure may be different
        let timings = TranCriptionTimings()
        
        return CriptionTranCriptionResult(
            text: whisperKitResult.text,
            segments: segments,
            language: whisperKitResult.language,
            duration: (segments.last?.end ?? 0.0),
            timings: timings,
            allWords: [] // WhisperKit TranCriptionResult may not have allWords property
        )
    }
}

extension CriptionWordTiming {
    static func fromWhisperKit(_ whisperKitWord: WordTiming) -> CriptionWordTiming {
        return CriptionWordTiming(
            word: whisperKitWord.word,
            start: Double(whisperKitWord.start),
            end: Double(whisperKitWord.end),
            tokens: whisperKitWord.tokens.map { String($0) }
        )
    }
}

