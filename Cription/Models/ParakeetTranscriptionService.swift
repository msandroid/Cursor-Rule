//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import AVFoundation
import FluidAudio

// MARK: - Parakeet Transcription Service

@MainActor
class ParakeetTranscriptionService: ObservableObject {
    @Published var isInitialized = false
    @Published var isLoading = false
    @Published var error: String?
    
    private var asrManager: AsrManager?
    private var models: AsrModels?
    private var currentModelVersion: FluidAudio.AsrModelVersion = .v3
    
    init() {
        print("🦜 ParakeetTranscriptionService initialized")
    }
    
    // MARK: - Model Management
    
    func initialize(modelVersion: FluidAudio.AsrModelVersion = .v3) async throws {
        guard !isInitialized else {
            print("🦜 Parakeet already initialized")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("🦜 Initializing Parakeet with model version: \(modelVersion)")
            
            // Download and load ASR models
            models = try await AsrModels.downloadAndLoad(version: modelVersion)
            
            // Initialize ASR manager with default config
            asrManager = AsrManager(config: .default)
            try await asrManager?.initialize(models: models!)
            
            currentModelVersion = modelVersion
            isInitialized = true
            isLoading = false
            
            print("🦜 Parakeet initialization completed successfully")
            
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("🦜 Parakeet initialization failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func switchModel(version: AsrModelVersion) async throws {
        guard version != currentModelVersion else {
            print("🦜 Model version already active: \(version)")
            return
        }
        
        print("🦜 Switching to model version: \(version)")
        
        // Cleanup current models
        await cleanup()
        
        // Initialize with new version
        try await initialize(modelVersion: version)
    }
    
    func cleanup() async {
        print("🦜 Cleaning up Parakeet resources")
        
        asrManager?.cleanup()
        asrManager = nil
        models = nil
        isInitialized = false
        error = nil
    }
    
    // MARK: - Audio Processing
    
    func loadAudioFile(path: String) async throws -> [Float] {
        guard let url = URL(string: path) else {
            throw ParakeetError.invalidAudioPath
        }
        
        return try await loadAudioFile(url: url)
    }
    
    func loadAudioFile(url: URL) async throws -> [Float] {
        print("🦜 Loading audio file: \(url.lastPathComponent)")
        
        do {
            // Load audio file and convert to 16kHz mono samples
            let samples = try await AudioProcessor.loadAudioFile(path: url.path)
            print("🦜 Audio loaded successfully: \(samples.count) samples")
            return samples
        } catch {
            print("🦜 Failed to load audio file: \(error.localizedDescription)")
            throw ParakeetError.audioLoadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Transcription
    
    func transcribe(audioSamples: [Float], source: AudioSource = .system) async throws -> ParakeetTranscriptionResult {
        guard isInitialized, let asrManager = asrManager else {
            throw ParakeetError.notInitialized
        }
        
        print("🦜 Starting transcription with \(audioSamples.count) samples")
        
        do {
            let result = try await asrManager.transcribe(audioSamples, source: source)
            
            let transcriptionResult = ParakeetTranscriptionResult(
                text: result.text,
                confidence: result.confidence,
                language: result.language ?? "unknown",
                duration: Double(audioSamples.count) / 16000.0, // Assuming 16kHz sample rate
                segments: result.segments?.map { segment in
                    ParakeetSegment(
                        start: segment.start,
                        end: segment.end,
                        text: segment.text
                    )
                } ?? []
            )
            
            print("🦜 Transcription completed: \(transcriptionResult.text.prefix(100))...")
            return transcriptionResult
            
        } catch {
            print("🦜 Transcription failed: \(error.localizedDescription)")
            throw ParakeetError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    func transcribeFile(path: String, source: AudioSource = .system) async throws -> ParakeetTranscriptionResult {
        let samples = try await loadAudioFile(path: path)
        return try await transcribe(audioSamples: samples, source: source)
    }
    
    func transcribeFile(url: URL, source: AudioSource = .system) async throws -> ParakeetTranscriptionResult {
        let samples = try await loadAudioFile(url: url)
        return try await transcribe(audioSamples: samples, source: source)
    }
    
    // MARK: - Model Information
    
    var availableLanguages: [String] {
        switch currentModelVersion {
        case .v2:
            return ["en"] // English only
        case .v3:
            return [
                "en", "es", "fr", "de", "bg", "hr", "cs", "da", "nl", "et",
                "fi", "el", "hu", "it", "lv", "lt", "mt", "pl", "pt", "ro",
                "sk", "sl", "sv", "ru", "uk"
            ] // 25 European languages
        }
    }
    
    var modelInfo: String {
        switch currentModelVersion {
        case .v2:
            return "Parakeet TDT v2 (English-only, optimized vocabulary)"
        case .v3:
            return "Parakeet TDT v3 (25 European languages)"
        }
    }
}

// MARK: - Supporting Types

struct ParakeetTranscriptionResult {
    let text: String
    let confidence: Float
    let language: String
    let duration: Double
    let segments: [ParakeetSegment]
}

struct ParakeetSegment {
    let start: Double
    let end: Double
    let text: String
}

enum ParakeetError: LocalizedError {
    case notInitialized
    case invalidAudioPath
    case audioLoadFailed(String)
    case transcriptionFailed(String)
    case modelLoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Parakeet service is not initialized"
        case .invalidAudioPath:
            return "Invalid audio file path"
        case .audioLoadFailed(let message):
            return "Failed to load audio file: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .modelLoadFailed(let message):
            return "Model loading failed: \(message)"
        }
    }
}

// MARK: - Model Version Enum

enum AsrModelVersion {
    case v2  // English-only
    case v3  // Multilingual (25 languages)
    
    var displayName: String {
        switch self {
        case .v2:
            return "v2 (English)"
        case .v3:
            return "v3 (Multilingual)"
        }
    }
}

// MARK: - Audio Source Enum

enum AudioSource {
    case system
    case microphone
    case file
    
    var displayName: String {
        switch self {
        case .system:
            return "System Audio"
        case .microphone:
            return "Microphone"
        case .file:
            return "Audio File"
        }
    }
}

// MARK: - Type Conversion Extensions

extension ParakeetTranscriptionResult {
    func toCriptionTranscriptionResult() -> CriptionTranCriptionResult {
        let segments = self.segments.map { segment in
            TranCriptionSegment(
                start: segment.start,
                end: segment.end,
                text: segment.text
            )
        }
        
        return CriptionTranCriptionResult(
            text: self.text,
            segments: segments,
            language: self.language,
            duration: self.duration,
            timings: TranCriptionTimings(),
            allWords: self.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        )
    }
}
