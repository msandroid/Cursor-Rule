//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import WhisperKit
import Security
import AVFoundation

// MARK: - TranCription Service Manager

@MainActor
class TranCriptionServiceManager: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var status: String = ""
    @Published var error: String?
    @Published var showingCreditPurchaseSheet = false
    @Published var showingTokenLimitPrompt = false
    @Published var enableAudioOptimization = true  // 音声最適化を有効化（デフォルト: ON）
    
    // リアルタイムストリーミング用
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var realtimeText: String = ""
    @Published var bufferSeconds: Double = 0.0
    
    private var whisperModelManager: WhisperModelManager?
    private var openAIService: OpenAITranCriptionService?
    private var textTranslationService: OpenAITextTranslationService?
    var openAIRealtimeService: OpenAIRealtimeTranscriptionService?
    var openAIStreamingService: OpenAIStreamingTranscriptionService?
    var fireworksStreamingService: FireworksStreamingASRService?
    var fireworksServerlessService: FireworksServerlessASRService?
    var parakeetService: ParakeetTranscriptionService?
    private var tranCriptionTask: Task<Void, Never>?
    private var lastBufferSize: Int = 0
    
    init() {
        // Load API key from Keychain on initialization
        loadAPIKeyFromKeychain()
        
        // Initialize Parakeet service
        parakeetService = ParakeetTranscriptionService()
        
        // トークン制限の更新を監視
        Task {
            await SubCriptionManager.shared.updateTokenLimitForSubscription()
        }
    }
    
    func setWhisperModelManager(_ modelManager: WhisperModelManager) {
        self.whisperModelManager = modelManager
    }
    
    // MARK: - API Key Management
    
    func updateAPIKey(_ apiKey: String) {
        if !apiKey.isEmpty {
            // Save to Keychain using SecureKeychainManager
            if SecureKeychainManager.shared.saveAPIKey(apiKey) {
                openAIService = OpenAITranCriptionService(apiKey: apiKey)
                textTranslationService = OpenAITextTranslationService(apiKey: apiKey)
                openAIRealtimeService = OpenAIRealtimeTranscriptionService(apiKey: apiKey)
                openAIStreamingService = OpenAIStreamingTranscriptionService(apiKey: apiKey)
                print("✅ OpenAI API key updated and saved to Keychain")
            } else {
                print("❌ Failed to save OpenAI API key to Keychain")
                openAIService = nil
                textTranslationService = nil
                openAIRealtimeService = nil
                openAIStreamingService = nil
            }
        } else {
            openAIService = nil
            textTranslationService = nil
            openAIRealtimeService = nil
            openAIStreamingService = nil
            print("✅ OpenAI API key removed")
        }
    }
    
    func updateFireworksAPIKey(_ apiKey: String) {
        if !apiKey.isEmpty {
            // Save to Keychain using SecureKeychainManager
            if SecureKeychainManager.shared.saveFireworksAPIKey(apiKey) {
                fireworksStreamingService = FireworksStreamingASRService(apiKey: apiKey)
                fireworksServerlessService = FireworksServerlessASRService(apiKey: apiKey)
                print("✅ Fireworks API key updated and saved to Keychain")
            } else {
                print("❌ Failed to save Fireworks API key to Keychain")
                fireworksStreamingService = nil
                fireworksServerlessService = nil
            }
        } else {
            fireworksStreamingService = nil
            fireworksServerlessService = nil
            print("✅ Fireworks API key removed")
        }
    }
    
    func hasValidAPIKey() -> Bool {
        return openAIService != nil
    }
    
    func hasValidFireworksAPIKey() -> Bool {
        return fireworksStreamingService != nil || fireworksServerlessService != nil
    }
    
    func clearAPIKey() {
        SecureKeychainManager.shared.deleteAPIKey()
        openAIService = nil
        textTranslationService = nil
        openAIRealtimeService = nil
        openAIStreamingService = nil
        print("✅ OpenAI API key cleared from Keychain")
    }
    
    func clearFireworksAPIKey() {
        SecureKeychainManager.shared.deleteFireworksAPIKey()
        fireworksStreamingService = nil
        fireworksServerlessService = nil
        print("✅ Fireworks API key cleared from Keychain")
    }
    
    // MARK: - API Key Loading from Keychain
    
    func loadAPIKeyFromKeychain() {
        print("🔍 Attempting to load API keys from Keychain...")
        
        // Load OpenAI API key
        if let apiKey = SecureKeychainManager.shared.loadAPIKey(), !apiKey.isEmpty {
            print("✅ OpenAI API key loaded successfully from Keychain, updating TranCriptionServiceManager")
            openAIService = OpenAITranCriptionService(apiKey: apiKey)
            textTranslationService = OpenAITextTranslationService(apiKey: apiKey)
            openAIRealtimeService = OpenAIRealtimeTranscriptionService(apiKey: apiKey)
            openAIStreamingService = OpenAIStreamingTranscriptionService(apiKey: apiKey)
        } else {
            print("❌ No OpenAI API key found in Keychain - user needs to set one in settings")
            openAIService = nil
            textTranslationService = nil
            openAIRealtimeService = nil
            openAIStreamingService = nil
        }
        
        // Load Fireworks API key
        if let fireworksAPIKey = SecureKeychainManager.shared.loadFireworksAPIKey(), !fireworksAPIKey.isEmpty {
            print("✅ Fireworks API key loaded successfully from Keychain, updating TranCriptionServiceManager")
            fireworksStreamingService = FireworksStreamingASRService(apiKey: fireworksAPIKey)
            fireworksServerlessService = FireworksServerlessASRService(apiKey: fireworksAPIKey)
        } else {
            print("❌ No Fireworks API key found in Keychain - user needs to set one in settings")
            fireworksStreamingService = nil
            fireworksServerlessService = nil
        }
    }
    
    private func hasAPIKeyInKeychain() -> Bool {
        return SecureKeychainManager.shared.hasAPIKey()
    }
    
    private func hasFireworksAPIKeyInKeychain() -> Bool {
        return SecureKeychainManager.shared.hasFireworksAPIKey()
    }
    
    // MARK: - Public Methods
    
    func transcriptionAudio(audioData: Data, language: String? = nil, customPrompt: String? = nil) async throws -> TranCriptionResult {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        isProcessing = true
        progress = 0.0
        status = "Preparing tranCription..."
        error = nil
        
        defer {
            isProcessing = false
            progress = 0.0
            status = ""
        }
        
        do {
            // ファイルサイズチェック（25MB制限）
            let maxFileSize = 25 * 1024 * 1024 // 25MB
            guard audioData.count <= maxFileSize else {
                throw TranCriptionError.fileTooLarge
            }
            
            // 音声最適化を適用（有効化されている場合）
            var optimizedAudioData = audioData
            if enableAudioOptimization {
                status = "Optimizing audio..."
                progress = 0.05
                
                do {
                    // 無音削除を試みる
                    let silenceRemoved = try await AudioOptimizer.removeSilence(from: audioData)
                    optimizedAudioData = silenceRemoved
                    
                    print("✅ Audio optimization completed")
                } catch {
                    // 最適化が失敗しても元のデータで続行
                    print("⚠️ Audio optimization failed, using original data: \(error)")
                }
            }
            
            // 選択されたモデルに基づいて適切なサービスを選択
            guard let whisperModelManager = whisperModelManager else {
                throw TranCriptionError.whisperModelManagerNotAvailable
            }
            let selectedModel = whisperModelManager.selectedModel
            
            // コスト削減: ソース言語が英語でファイル入力の場合、OpenAIモデルが選択されていてもバンドルモデルを使用
            // ただし、autodetectが選択された場合は必ずOpenAIモデルを使用
            let shouldUseLocalModel = isOpenAIModel(selectedModel) && 
                                     (language == "en" || language == "english") &&
                                     language != "auto"
            
            if shouldUseLocalModel {
                // 英語のファイル入力の場合、バンドルモデルで処理
                print("🔵 Cost optimization: Using local model for English file input instead of OpenAI")
                
                guard let whisperKit = whisperModelManager.whisperKit else {
                    throw TranCriptionError.whisperKitNotAvailable
                }
                
                status = "Using local model for English tranCription..."
                progress = 0.2
                
                let result = try await performWhisperKitTranCription(
                    audioData: optimizedAudioData,
                    language: language,
                    whisperKit: whisperKit
                )
                
                status = "TranCription completed!"
                progress = 1.0
                
                return result
                
            } else if isParakeetModel(selectedModel) {
                // Parakeetモデルの場合
                guard let parakeetService = parakeetService else {
                    throw TranCriptionError.whisperKitNotAvailable
                }
                
                status = "Using Parakeet tranCription..."
                progress = 0.2
                
                // Parakeetサービスが初期化されていない場合は初期化
                if !parakeetService.isInitialized {
                    status = "Initializing Parakeet model..."
                    progress = 0.1
                    
                    let modelVersion: AsrModelVersion = selectedModel.contains("v2") ? .v2 : .v3
                    try await parakeetService.initialize(modelVersion: modelVersion)
                }
                
                // 音声データをサンプル配列に変換
                let samples = try await convertAudioDataToSamples(optimizedAudioData)
                
                // Parakeetでトランスクライブ
                let parakeetResult = try await parakeetService.transcribe(audioSamples: samples)
                
                // Cription形式に変換
                let result = parakeetResult.toCriptionTranscriptionResult()
                
                status = "TranCription completed!"
                progress = 1.0
                
                return TranCriptionResult(
                    text: result.text,
                    segments: result.segments,
                    language: result.language,
                    duration: result.duration
                )
                
            } else if isOpenAIModel(selectedModel) {
                // OpenAIモデルの場合
                if language == "auto" {
                    print("🔵 Auto-detect selected: Forcing OpenAI model usage for language detection")
                }
                guard let openAIService = openAIService else {
                    print("❌ OpenAI service not available - attempting to reload API key from Keychain")
                    loadAPIKeyFromKeychain()
                    
                    guard let retryOpenAIService = openAIService else {
                        print("❌ OpenAI service still not available after reload attempt")
                        // Check if API key exists in Keychain to provide better error message
                        if hasAPIKeyInKeychain() {
                            throw TranCriptionError.openAIServiceNotAvailable
                        } else {
                            throw TranCriptionError.openAIAPIKeyNotSet
                        }
                    }
                    
                    // Retry with the reloaded service
                    status = "Using OpenAI tranCription (retry)..."
                    progress = 0.2
                    
                    let finalLanguage = (language == "auto") ? nil : language
                    
                    let result = try await retryOpenAIService.transcriptionAudio(
                        audioData: optimizedAudioData,
                        language: finalLanguage,
                        model: selectedModel,
                        customPrompt: customPrompt
                    )
                    
                    status = "TranCription completed!"
                    progress = 1.0
                    
                    return result
                }
                
                status = "Using OpenAI tranCription..."
                progress = 0.2
                
                do {
                    // 言語が"auto"の場合はnilにして自動検出を有効化
                    let finalLanguage = (language == "auto") ? nil : language
                    
                    print("🔵 TranscriptionServiceManager: Calling OpenAI transcription")
                    if let lang = language {
                        print("   - Input language: '\(lang)'")
                    } else {
                        print("   - Input language: nil")
                    }
                    if let finalLang = finalLanguage {
                        print("   - Final language: '\(finalLang)' (will be sent to API)")
                    } else {
                        print("   - Final language: nil (auto-detect mode - no language param will be sent)")
                    }
                    if let prompt = customPrompt {
                        print("   - Custom prompt: '\(prompt)'")
                    }
                    print("   - Model: \(selectedModel)")
                    
                    let result = try await openAIService.transcriptionAudio(
                        audioData: optimizedAudioData,
                        language: finalLanguage,
                        model: selectedModel,
                        customPrompt: customPrompt
                    )
                    
                    status = "TranCription completed!"
                    progress = 1.0
                    
                    // コスト追跡とレポート記録
                    if enableAudioOptimization && optimizedAudioData.count < audioData.count {
                        let originalCost = CreditManager.shared.calculateAPICost(duration: result.duration, model: selectedModel, isTranslation: false)
                        let optimizedCost = CreditManager.shared.calculateAPICost(duration: result.duration, model: selectedModel, isTranslation: false) * (Double(optimizedAudioData.count) / Double(audioData.count))
                        let savings = originalCost - optimizedCost
                        
                        CostReportManager.shared.recordUsage(
                            duration: result.duration,
                            model: selectedModel,
                            cost: optimizedCost,
                            isTranslation: false,
                            optimizationSavings: savings
                        )
                    } else {
                        let cost = CreditManager.shared.calculateAPICost(duration: result.duration, model: selectedModel, isTranslation: false)
                        CostReportManager.shared.recordUsage(
                            duration: result.duration,
                            model: selectedModel,
                            cost: cost,
                            isTranslation: false
                        )
                    }
                    
                    // トークン計算と使用量追跡
                    await TokenCalculationService.shared.calculateTokensForTranCription(
                        finalText: result.text,
                        duration: result.duration,
                        model: selectedModel,
                        isTranslation: false
                    )
                    
                    if let tokenStats = TokenCalculationService.shared.getLastResult() {
                        SubCriptionManager.shared.addTokenUsage(tokenStats.tokenCount)
                        
                        // トークン制限チェック
                        if SubCriptionManager.shared.currentTokenUsage >= SubCriptionManager.shared.tokenLimit {
                            showingTokenLimitPrompt = true
                        }
                    }
                    
                    return result
                } catch {
                    // OpenAI API エラーの場合、エラーをそのまま投げる（フォールバックしない）
                    print("OpenAI API failed: \(error.localizedDescription)")
                    throw error
                }
                
            } else if isFireworksModel(selectedModel) && !isWhisperV3ServerlessModel(selectedModel) {
                // Fireworks Streamingモデル（fireworks-asr-large, fireworks-asr-v2）はStreaming専用のため、ファイル転写はサポートしていない
                status = "Fireworks streaming models are streaming-only..."
                progress = 0.1

                // WhisperKitにフォールバック
                guard let whisperKit = whisperModelManager.whisperKit else {
                    throw TranCriptionError.whisperKitNotAvailable
                }

                status = "Using local model for file transcription..."
                progress = 0.2

                let result = try await performWhisperKitTranCription(
                    audioData: optimizedAudioData,
                    language: language,
                    whisperKit: whisperKit
                )

                status = "TranCription completed!"
                progress = 1.0

                return result
                
            } else if isWhisperV3ServerlessModel(selectedModel) {
                // Whisper V3 と Whisper V3 TurboはServerless APIを使用
                guard let serverlessService = fireworksServerlessService else {
                    print("❌ Fireworks Serverless service not available - attempting to reload API key from Keychain")
                    loadAPIKeyFromKeychain()
                    
                    guard let retryServerlessService = fireworksServerlessService else {
                        print("❌ Fireworks Serverless service still not available after reload attempt")
                        if hasFireworksAPIKeyInKeychain() {
                            throw TranCriptionError.openAIServiceNotAvailable
                        } else {
                            throw TranCriptionError.openAIAPIKeyNotSet
                        }
                    }
                    
                    status = "Using Fireworks Whisper V3 Turbo..."
                    progress = 0.3
                    
                    let result = try await retryServerlessService.transcribeAudio(
                        audioData: optimizedAudioData,
                        model: selectedModel,
                        language: language,
                        task: "transcribe"
                    )
                    
                    status = "TranCription completed!"
                    progress = 1.0
                    
                    return result
                }
                
                status = "Using Fireworks Whisper V3 Turbo..."
                progress = 0.3
                
                let result = try await serverlessService.transcribeAudio(
                    audioData: optimizedAudioData,
                    model: selectedModel,
                    language: language,
                    task: "transcribe"
                )
                
                status = "TranCription completed!"
                progress = 1.0
                
                return result
                
            } else {
                // WhisperKitモデルの場合
                guard let whisperKit = whisperModelManager.whisperKit else {
                    throw TranCriptionError.whisperKitNotAvailable
                }
                
                status = "Using WhisperKit tranCription..."
                progress = 0.2
                
                let result = try await performWhisperKitTranCription(
                    audioData: optimizedAudioData,
                    language: language,
                    whisperKit: whisperKit
                )
                
                status = "TranCription completed!"
                progress = 1.0
                
                return result
            }
            
        } catch {
            print("❌ TranscriptionServiceManager: Transcription failed: \(error)")
            if let tranCriptionError = error as? TranCriptionError {
                print("❌ TranCriptionError details: \(tranCriptionError)")
                switch tranCriptionError {
                case .openAIServiceNotAvailable:
                    self.error = "OpenAI service is not available. Please check your API key in settings."
                case .openAIAPIKeyNotSet:
                    self.error = "OpenAI API key is not set. Please configure your API key in settings."
                case .whisperKitNotAvailable:
                    self.error = "Local model not loaded. Please load a model first."
                case .fileTooLarge:
                    self.error = "Audio file is too large. Please use a file smaller than 25MB."
                case .invalidAudioData:
                    self.error = "Invalid audio data format. Please check your audio file."
                case .subscriptionLimitExceeded:
                    self.error = "Monthly usage limit exceeded. Please upgrade your subscription or wait for the next billing cycle."
                case .insufficientCredits:
                    self.error = "Insufficient credits. Please purchase more credits to continue using API services."
                    // Free planでクレジット不足の場合はクレジット購入画面を表示
                    let subscriptionManager = SubCriptionManager.shared
                    if subscriptionManager.subCriptionTier == .free {
                        self.showingCreditPurchaseSheet = true
                    }
                case .modelAccessDenied:
                    self.error = "This model is not available in your current subscription plan. Please upgrade to access cloud models."
                case .apiError(let statusCode, let message):
                    if statusCode == 403 {
                        self.error = "Model access denied. Please check your OpenAI API key permissions and ensure you have access to the selected OpenAI model."
                    } else {
                        self.error = "API Error \(statusCode): \(message)"
                    }
                default:
                    self.error = tranCriptionError.localizedDescription
                }
            } else {
                print("❌ Unexpected error type: \(type(of: error))")
                self.error = "TranCription failed: \(error.localizedDescription)"
            }
            
            throw error
        }
    }
    
    func translateAudio(audioData: Data, targetLanguage: String? = nil) async throws -> TranCriptionResult {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        isProcessing = true
        progress = 0.0
        status = "Preparing translation..."
        error = nil
        
        defer {
            isProcessing = false
            progress = 0.0
            status = ""
        }
        
        do {
            // ファイルサイズチェック（25MB制限）
            let maxFileSize = 25 * 1024 * 1024 // 25MB
            guard audioData.count <= maxFileSize else {
                throw TranCriptionError.fileTooLarge
            }
            
            // 音声最適化を適用（有効化されている場合）
            var optimizedAudioData = audioData
            if enableAudioOptimization {
                status = "Optimizing audio..."
                progress = 0.1
                
                do {
                    // 無音削除を試みる
                    let silenceRemoved = try await AudioOptimizer.removeSilence(from: audioData)
                    optimizedAudioData = silenceRemoved
                    
                    print("✅ Audio optimization completed for translation")
                } catch {
                    // 最適化が失敗しても元のデータで続行
                    print("⚠️ Audio optimization failed, using original data: \(error)")
                }
            }
            
            // 選択されたモデルに基づいて適切なサービスを選択
            guard let whisperModelManager = whisperModelManager else {
                throw TranCriptionError.whisperModelManagerNotAvailable
            }
            let selectedModel = whisperModelManager.selectedModel
            
            if isOpenAIModel(selectedModel) {
                // OpenAIモデルの場合（translationsはwhisper-1のみサポート）
                let translationModel = "whisper-1"
                
                guard let openAIService = openAIService else {
                    print("❌ OpenAI service not available - attempting to reload API key from Keychain")
                    loadAPIKeyFromKeychain()
                    
                    guard let retryOpenAIService = openAIService else {
                        print("❌ OpenAI service still not available after reload attempt")
                        if hasAPIKeyInKeychain() {
                            throw TranCriptionError.openAIServiceNotAvailable
                        } else {
                            throw TranCriptionError.openAIAPIKeyNotSet
                        }
                    }
                    
                    status = "Using OpenAI translation (retry)..."
                    progress = 0.2
                    
                    let result = try await retryOpenAIService.translateAudio(
                        audioData: optimizedAudioData,
                        model: translationModel,
                        targetLanguage: targetLanguage
                    )
                    
                    status = "Translation completed!"
                    progress = 1.0
                    
                    return result
                }
                
                status = "Using OpenAI translation..."
                progress = 0.2
                
                do {
                    let result = try await openAIService.translateAudio(
                        audioData: optimizedAudioData,
                        model: translationModel,
                        targetLanguage: targetLanguage
                    )
                    
                    status = "Translation completed!"
                    progress = 1.0
                    
                    // コスト追跡とレポート記録
                    if enableAudioOptimization && optimizedAudioData.count < audioData.count {
                        let originalCost = CreditManager.shared.calculateAPICost(duration: result.duration, model: translationModel, isTranslation: true)
                        let optimizedCost = CreditManager.shared.calculateAPICost(duration: result.duration, model: translationModel, isTranslation: true) * (Double(optimizedAudioData.count) / Double(audioData.count))
                        let savings = originalCost - optimizedCost
                        
                        CostReportManager.shared.recordUsage(
                            duration: result.duration,
                            model: translationModel,
                            cost: optimizedCost,
                            isTranslation: true,
                            optimizationSavings: savings
                        )
                    } else {
                        let cost = CreditManager.shared.calculateAPICost(duration: result.duration, model: translationModel, isTranslation: true)
                        CostReportManager.shared.recordUsage(
                            duration: result.duration,
                            model: translationModel,
                            cost: cost,
                            isTranslation: true
                        )
                    }
                    
                    return result
                } catch {
                    print("OpenAI Translation API failed: \(error.localizedDescription)")
                    throw error
                }
                
            } else if isWhisperV3ServerlessModel(selectedModel) {
                // Whisper V3 と Whisper V3 TurboはServerless APIを使用
                guard let serverlessService = fireworksServerlessService else {
                    print("❌ Fireworks Serverless service not available - attempting to reload API key from Keychain")
                    loadAPIKeyFromKeychain()
                    
                    guard let retryServerlessService = fireworksServerlessService else {
                        print("❌ Fireworks Serverless service still not available after reload attempt")
                        if hasFireworksAPIKeyInKeychain() {
                            throw TranCriptionError.openAIServiceNotAvailable
                        } else {
                            throw TranCriptionError.openAIAPIKeyNotSet
                        }
                    }
                    
                    status = "Using Fireworks Whisper V3 Turbo for translation..."
                    progress = 0.3
                    
                    let result = try await retryServerlessService.transcribeAudio(
                        audioData: optimizedAudioData,
                        model: selectedModel,
                        language: nil, // 自動検出
                        task: "translate"
                    )
                    
                    status = "Translation completed!"
                    progress = 1.0
                    
                    return result
                }
                
                status = "Using Fireworks Whisper V3 Turbo for translation..."
                progress = 0.3
                
                let result = try await serverlessService.transcribeAudio(
                    audioData: optimizedAudioData,
                    model: selectedModel,
                    language: nil, // 自動検出
                    task: "translate"
                )
                
                status = "Translation completed!"
                progress = 1.0
                
                return result
                
            } else {
                // WhisperKitモデルの場合
                guard let whisperKit = whisperModelManager.whisperKit else {
                    throw TranCriptionError.whisperKitNotAvailable
                }
                
                status = "Using WhisperKit translation..."
                progress = 0.2
                
                // WhisperKitの翻訳タスクを使用
                let result = try await performWhisperKitTranslation(
                    audioData: optimizedAudioData,
                    whisperKit: whisperKit
                )
                
                // targetLanguageが指定されている場合、さらにGPT-4o-miniで翻訳
                if let targetLanguage = targetLanguage, targetLanguage != "en" {
                    guard let textTranslationService = textTranslationService else {
                        print("⚠️ Text translation service not available - returning English result")
                        return result
                    }
                    
                    status = "Translating to \(targetLanguage)..."
                    progress = 0.6
                    
                    let translatedText = try await textTranslationService.translateText(text: result.text, targetLanguage: targetLanguage)
                    
                    return TranCriptionResult(
                        text: translatedText,
                        segments: [],
                        language: targetLanguage,
                        duration: result.duration
                    )
                }
                
                status = "Translation completed!"
                progress = 1.0
                
                return result
            }
            
        } catch {
            self.error = error.localizedDescription
            print("Translation failed: \(error.localizedDescription)")
            
            if let tranCriptionError = error as? TranCriptionError {
                switch tranCriptionError {
                case .openAIServiceNotAvailable:
                    self.error = "OpenAI service is not available. Please check your API key in settings."
                case .openAIAPIKeyNotSet:
                    self.error = "OpenAI API key is not set. Please configure your API key in settings."
                case .whisperKitNotAvailable:
                    self.error = "Local model not loaded. Please load a model first."
                case .fileTooLarge:
                    self.error = "Audio file is too large. Please use a file smaller than 25MB."
                case .insufficientCredits:
                    self.error = "Insufficient credits. Please purchase more credits to continue using API services."
                    // Free planでクレジット不足の場合はクレジット購入画面を表示
                    let subscriptionManager = SubCriptionManager.shared
                    if subscriptionManager.subCriptionTier == .free {
                        self.showingCreditPurchaseSheet = true
                    }
                case .apiError(let statusCode, let message):
                    self.error = "API Error \(statusCode): \(message)"
                default:
                    self.error = tranCriptionError.localizedDescription
                }
            } else {
                self.error = "Translation failed: \(error.localizedDescription)"
            }
            
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func isOpenAIModel(_ modelId: String) -> Bool {
        return modelId == "whisper-1" || modelId == "gpt-4o-transcribe" || modelId == "gpt-4o-mini-transcribe"
    }
    
    private func isParakeetModel(_ modelId: String) -> Bool {
        return modelId == "parakeet-tdt-0.6b-v3" || modelId == "parakeet-tdt-0.6b-v2"
    }
    
    private func isFireworksModel(_ modelId: String) -> Bool {
        return modelId == "fireworks-asr-large" ||
               modelId == "fireworks-asr-v2" ||
               modelId == "whisper-v3" ||
               modelId == "whisper-v3-turbo"
    }
    
    private func isWhisperV3Model(_ modelId: String) -> Bool {
        return modelId == "whisper-v3" ||
               modelId == "whisper-v3-turbo"
    }
    
    private func isWhisperV3ServerlessModel(_ modelId: String) -> Bool {
        return modelId == "whisper-v3" ||
               modelId == "whisper-v3-turbo"
    }
    
    private func performWhisperKitTranCription(
        audioData: Data,
        language: String?,
        whisperKit: WhisperKit
    ) async throws -> TranCriptionResult {
        
        status = "Processing with WhisperKit..."
        progress = 0.5
        
        // Convert Data to audio samples
        let audioSamples = try await convertAudioDataToSamples(audioData)
        
        guard !audioSamples.isEmpty else {
            throw TranCriptionError.invalidAudioData
        }
        
        // 言語が"auto"の場合はnilにして自動検出を有効化
        let finalLanguage = (language == "auto") ? nil : language
        
        // WhisperKitを使用して音声を転写（完全な転写のためEarly Stoppingを無効化）
        let results = try await whisperKit.transcribe(
            audioArray: audioSamples,
            decodeOptions: DecodingOptions(
                task: .transcribe,
                language: finalLanguage,
                temperatureFallbackCount: 5,     // デフォルト値で完全な転写を確保
                sampleLength: 224,               // デフォルト値で完全な転写を確保
                compressionRatioThreshold: 2.4,  // より緩い閾値で完全な転写を確保
                logProbThreshold: -1.0           // より緩い閾値で完全な転写を確保
            )
        )
        
        status = "Parsing response..."
        progress = 0.8
        
        // WhisperKitの結果をTranCriptionResultに変換
        guard let result = results.first else {
            throw TranCriptionError.invalidResponse
        }
        
        let segments = result.segments.map { segment in
            TranCriptionSegment(
                start: Double(segment.start),
                end: Double(segment.end),
                text: filterMusicAndSoundEffects(segment.text)
            )
        }
        
        return TranCriptionResult(
            text: filterMusicAndSoundEffects(result.text),
            segments: segments,
            language: result.language,
            duration: segments.last?.end ?? 0.0
        )
    }
    
    // 音声データをサンプル配列に変換
    private func convertAudioDataToSamples(_ audioData: Data) async throws -> [Float] {
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
            throw TranCriptionError.invalidAudioData
        }
        
        try audioFile.read(into: audioBuffer)
        
        // PCMバッファをFloat配列に変換
        guard let channelData = audioBuffer.floatChannelData else {
            throw TranCriptionError.invalidAudioData
        }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(audioBuffer.frameLength), by: audioBuffer.stride).map { channelDataValue[$0] }
        
        // 必要に応じてリサンプリング (WhisperKitは16kHzを想定)
        let targetSampleRate = 16000.0
        if audioFormat.sampleRate != targetSampleRate {
            return try await resampleAudio(channelDataValueArray, from: audioFormat.sampleRate, to: targetSampleRate)
        }
        
        return channelDataValueArray
    }
    
    // 音声リサンプリング
    private func resampleAudio(_ samples: [Float], from sourceSampleRate: Double, to targetSampleRate: Double) async throws -> [Float] {
        let ratio = targetSampleRate / sourceSampleRate
        let outputLength = Int(Double(samples.count) * ratio)
        var resampled: [Float] = []
        resampled.reserveCapacity(outputLength)
        
        for i in 0..<outputLength {
            let sourceIndex = Double(i) / ratio
            let lowerIndex = Int(sourceIndex)
            let upperIndex = min(lowerIndex + 1, samples.count - 1)
            let fraction = Float(sourceIndex - Double(lowerIndex))
            
            let interpolated = samples[lowerIndex] * (1.0 - fraction) + samples[upperIndex] * fraction
            resampled.append(interpolated)
        }
        
        return resampled
    }
    
    // MARK: - リアルタイムストリーミング機能
    
    // リアルタイム録音開始
    func startRealtimeRecording(language: String? = nil, delayInterval: Float = 1.0) async throws {
        guard !isRecording else {
            throw TranCriptionError.alreadyProcessing
        }
        
        // 選択されたモデルに基づいて適切なサービスを選択
        guard let whisperModelManager = whisperModelManager else {
            throw TranCriptionError.whisperModelManagerNotAvailable
        }
        let selectedModel = whisperModelManager.selectedModel
        
        // ストリーミングモデルかどうかを判定
        let isStreamingModel = selectedModel == "whisper-1" || 
                               selectedModel == "gpt-4o-transcribe" || 
                               selectedModel == "gpt-4o-mini-transcribe"
        
            let isFireworksStreamingModel = isFireworksModel(selectedModel)
        
        if isStreamingModel {
            // OpenAI Streamingサービスを直接使用（Realtime APIのフォールバックを削除）
            guard let streamingService = openAIStreamingService else {
                print("❌ OpenAI Streaming service not available - attempting to reload API key from Keychain")
                loadAPIKeyFromKeychain()
                
                guard let retryStreamingService = openAIStreamingService else {
                    print("❌ OpenAI Streaming service still not available after reload attempt")
                    if hasAPIKeyInKeychain() {
                        throw TranCriptionError.openAIServiceNotAvailable
                    } else {
                        throw TranCriptionError.openAIAPIKeyNotSet
                    }
                }
                
                try await retryStreamingService.startStreamingTranscription(model: selectedModel, language: language)
                isRecording = true
                isTranscribing = true
                
                // OpenAI Streamingサービスのテキストを監視
                observeOpenAIStreamingText()
                return
            }
            
            try await streamingService.startStreamingTranscription(model: selectedModel, language: language)
            isRecording = true
            isTranscribing = true
            
            // OpenAI Streamingサービスのテキストを監視
            observeOpenAIStreamingText()
            
        } else if isFireworksStreamingModel {
            // Fireworks Streamingサービスを使用
            guard let fireworksService = fireworksStreamingService else {
                print("❌ Fireworks Streaming service not available - attempting to reload API key from Keychain")
                loadAPIKeyFromKeychain()
                
                guard let retryFireworksService = fireworksStreamingService else {
                    print("❌ Fireworks Streaming service still not available after reload attempt")
                    if hasFireworksAPIKeyInKeychain() {
                        throw TranCriptionError.openAIServiceNotAvailable
                    } else {
                        throw TranCriptionError.openAIAPIKeyNotSet
                    }
                }
                
                try await retryFireworksService.startStreamingTranscription(model: selectedModel, language: language)
                isRecording = true
                isTranscribing = true
                
                // Fireworks Streamingサービスのテキストを監視
                observeFireworksStreamingText()
                return
            }
            
            try await fireworksService.startStreamingTranscription(model: selectedModel, language: language)
            isRecording = true
            isTranscribing = true
            
            // Fireworks Streamingサービスのテキストを監視
            observeFireworksStreamingText()
            
        } else {
            // WhisperKitを使用
            guard let whisperKit = whisperModelManager.whisperKit else {
                throw TranCriptionError.whisperKitNotAvailable
            }
            
            do {
                try whisperKit.audioProcessor.startRecordingLive { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.bufferSeconds = Double(whisperKit.audioProcessor.audioSamples.count) / Double(WhisperKit.sampleRate)
                    }
                }
                
                isRecording = true
                isTranscribing = true
                realtimeText = "Recording started..."
                lastBufferSize = 0
                
                // リアルタイムループ開始
                startRealtimeLoop(language: language, delayInterval: delayInterval)
                
            } catch {
                isRecording = false
                isTranscribing = false
                throw error
            }
        }
    }
    
    // OpenAIRealtimeサービスのテキストを監視
    private func observeOpenAIRealtimeText() {
        tranCriptionTask = Task { @MainActor in
            while isRecording && isTranscribing {
                if let realtimeService = openAIRealtimeService {
                    self.realtimeText = realtimeService.realtimeText
                    if let error = realtimeService.error {
                        self.error = error
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
            }
        }
    }
    
    // OpenAI Streamingサービスのテキストを監視
    private func observeOpenAIStreamingText() {
        tranCriptionTask = Task { @MainActor in
            while isRecording && isTranscribing {
                if let streamingService = openAIStreamingService {
                    self.realtimeText = streamingService.streamingText
                    if let error = streamingService.error {
                        self.error = error
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
            }
        }
    }
    
    // Fireworks Streamingサービスのテキストを監視
    private func observeFireworksStreamingText() {
        tranCriptionTask = Task { @MainActor in
            while isRecording && isTranscribing {
                if let fireworksService = fireworksStreamingService {
                    self.realtimeText = fireworksService.streamingText
                    if let error = fireworksService.error {
                        self.error = error
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
            }
        }
    }
    
    // リアルタイム録音停止
    func stopRealtimeRecording() {
        isTranscribing = false
        tranCriptionTask?.cancel()
        
        // OpenAI Streamingサービスの停止（直接使用）
        if let streamingService = openAIStreamingService, streamingService.isRecording {
            Task {
                await streamingService.stopStreamingTranscription()
            }
        }
        
        // Fireworks Streamingサービスの停止
        if let fireworksService = fireworksStreamingService, fireworksService.isRecording {
            Task {
                await fireworksService.stopStreamingTranscription()
            }
        }
        
        // OpenAI Realtimeサービスの停止（レガシー、使用しない）
        if let realtimeService = openAIRealtimeService, realtimeService.isRecording {
            Task {
                await realtimeService.stopRealtimeTranscription()
            }
        }
        
        // WhisperKitの停止
        if let whisperKit = whisperModelManager?.whisperKit {
            whisperKit.audioProcessor.stopRecording()
        }
        
        isRecording = false
    }
    
    // リアルタイムループ
    private func startRealtimeLoop(language: String?, delayInterval: Float) {
        tranCriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await tranCriptionCurrentBuffer(language: language, delayInterval: delayInterval)
                } catch {
                    await MainActor.run {
                        self.error = error.localizedDescription
                    }
                    break
                }
            }
        }
    }
    
    // 現在のバッファをトランスクライブ
    private func tranCriptionCurrentBuffer(language: String?, delayInterval: Float) async throws {
        guard let whisperKit = whisperModelManager?.whisperKit else {
            throw TranCriptionError.whisperKitNotAvailable
        }
        
        // 現在のバッファを取得
        let currentBuffer = whisperKit.audioProcessor.audioSamples
        
        // 次のバッファセグメントのサイズと時間を計算
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)
        
        // delayInterval秒以上の音声がある場合のみトランスクライブ
        guard nextBufferSeconds > delayInterval else {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms待機
            return
        }
        
        // バッファサイズを更新
        lastBufferSize = currentBuffer.count
        
        // 言語が"auto"の場合はnilにして自動検出を有効化
        let finalLanguage = (language == "auto") ? nil : language
        
        // トランスクライブ実行（完全な転写のためEarly Stoppingを無効化）
        let results = try await whisperKit.transcribe(
            audioArray: Array(currentBuffer),
            decodeOptions: DecodingOptions(
                task: .transcribe,
                language: finalLanguage,
                temperatureFallbackCount: 3,     // リアルタイムでも適切なフォールバック回数
                sampleLength: 224,               // デフォルト値で完全な転写を確保
                skipSpecialTokens: true,
                compressionRatioThreshold: 2.4,  // より緩い閾値で完全な転写を確保
                logProbThreshold: -1.0           // より緩い閾値で完全な転写を確保
            )
        )
        
        // 結果を更新
        if let result = results.first {
            await MainActor.run {
                self.realtimeText = filterMusicAndSoundEffects(result.text)
            }
        }
    }
    
    private func performWhisperKitTranslation(
        audioData: Data,
        whisperKit: WhisperKit
    ) async throws -> TranCriptionResult {
        
        status = "Processing translation with WhisperKit..."
        progress = 0.5
        
        // Convert Data to audio samples
        let audioSamples = try await convertAudioDataToSamples(audioData)
        
        guard !audioSamples.isEmpty else {
            throw TranCriptionError.invalidAudioData
        }
        
        // WhisperKitを使用して音声を翻訳（常に英語に翻訳、完全な転写のためEarly Stoppingを無効化）
        let results = try await whisperKit.transcribe(
            audioArray: audioSamples,
            decodeOptions: DecodingOptions(
                task: .translate,
                language: nil,  // 自動検出
                temperatureFallbackCount: 5,     // デフォルト値で完全な転写を確保
                sampleLength: 224,               // デフォルト値で完全な転写を確保
                compressionRatioThreshold: 2.4,  // より緩い閾値で完全な転写を確保
                logProbThreshold: -1.0           // より緩い閾値で完全な転写を確保
            )
        )
        
        status = "Parsing response..."
        progress = 0.8
        
        // WhisperKitの結果をTranCriptionResultに変換
        guard let result = results.first else {
            throw TranCriptionError.invalidResponse
        }
        
        let segments = result.segments.map { segment in
            TranCriptionSegment(
                start: Double(segment.start),
                end: Double(segment.end),
                text: filterMusicAndSoundEffects(segment.text)
            )
        }
        
        return TranCriptionResult(
            text: filterMusicAndSoundEffects(result.text),
            segments: segments,
            language: "en",  // 翻訳は常に英語
            duration: segments.last?.end ?? 0.0
        )
    }
    
    
    // MARK: - Text Filtering
    
    /// 音楽や音響効果の表記を除去するフィルタリング関数
    private func filterMusicAndSoundEffects(_ text: String) -> String {
        var filteredText = text
        
        // []で囲まれた音楽表記を除去（大文字小文字を区別しない）
        filteredText = filteredText.replacingOccurrences(
            of: "\\[[^\\]]*\\]",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // ()で囲まれた音楽表記を除去（大文字小文字を区別しない）
        filteredText = filteredText.replacingOccurrences(
            of: "\\([^)]*\\)",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 特定の音楽関連キーワードと無音表記を除去（全て大文字のバージョンも追加）
        let musicKeywords = [
            "music playing", "electronic music", "upbeat music", "background music",
            "instrumental music", "classical music", "jazz music", "rock music",
            "pop music", "dance music", "ambient music", "soft music",
            "blank audio", "blank_audio", "BLANK_AUDIO", "silence", "quiet", "no sound",
            "MUSIC PLAYING", "ELECTRONIC MUSIC", "UPBEAT MUSIC", "BACKGROUND MUSIC",
            "INSTRUMENTAL MUSIC", "CLASSICAL MUSIC", "JAZZ MUSIC", "ROCK MUSIC",
            "POP MUSIC", "DANCE MUSIC", "AMBIENT MUSIC", "SOFT MUSIC",
            "BLANK AUDIO", "BLANK_AUDIO", "SILENCE", "QUIET", "NO SOUND"
        ]
        
        for keyword in musicKeywords {
            // 大文字小文字を区別せずに除去
            filteredText = filteredText.replacingOccurrences(
                of: keyword,
                with: "",
                options: .caseInsensitive
            )
        }
        
        // 複数のスペースを単一のスペースに正規化
        filteredText = filteredText.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // 先頭と末尾の空白を除去
        return filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
