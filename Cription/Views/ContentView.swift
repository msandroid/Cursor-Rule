//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI
import WhisperKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Foundation
import os.log
import AVFoundation
import StoreKit
import UniformTypeIdentifiers

// MARK: - Liquid Glass Modifiers
struct LiquidGlassModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}

struct LiquidGlassButtonModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}

// MARK: - Shimmer Modifiers
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3)
                        ]),
                        startPoint: isAnimating ? .leading : .trailing,
                        endPoint: isAnimating ? .trailing : .leading
                    )
                )
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        isAnimating = true
                    }
                }
        }
    }
}

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                ShimmerView()
                    .mask(content)
            )
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    func liquidGlassButton() -> some View {
        self.modifier(LiquidGlassButtonModifier())
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}


// MARK: - Logging Manager
class LoggingManager {
    static let shared = LoggingManager()
    
    private let logger = Logger(subsystem: "com.Cription.whisperax", category: "main")
    private var currentLogLevel: LogLevel = .info
    private var isRealtimeProcessing: Bool = false
    private var logQueue = DispatchQueue(label: "com.Cription.logging", qos: .utility)
    private var bufferedLogs: [(level: LogLevel, category: LogCategory, message: String, timestamp: Date)] = []
    private var batchTimer: Timer?
    
    private init() {
        #if DEBUG
        currentLogLevel = .debug
        #else
        currentLogLevel = .warning
        #endif
    }
    
    func setRealtimeProcessing(_ enabled: Bool) {
        isRealtimeProcessing = enabled
        if enabled {
            startBatchLogging()
        } else {
            flushBufferedLogs()
            stopBatchLogging()
        }
    }
    
    private func startBatchLogging() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.flushBufferedLogs()
        }
    }
    
    private func stopBatchLogging() {
        batchTimer?.invalidate()
        batchTimer = nil
    }
    
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
    
    private func outputLog(level: LogLevel, message: String) {
        logger.log(level: level.osLogType, "\(message)")
    }
}

// MARK: - UI Optimizer
class UIOptimizer: ObservableObject {
    static let shared = UIOptimizer()
    
    private var pendingUpdates: [() -> Void] = []
    private var batchTimer: Timer?
    private var isRealtimeProcessing: Bool = false
    private let updateQueue = DispatchQueue(label: "com.Cription.ui-updates", qos: .userInitiated)
    
    private init() {}
    
    func setRealtimeProcessing(_ enabled: Bool) {
        isRealtimeProcessing = enabled
        if enabled {
            startBatchUpdates()
        } else {
            flushPendingUpdates()
            stopBatchUpdates()
        }
    }
    
    private func startBatchUpdates() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.flushPendingUpdates()
        }
    }
    
    private func stopBatchUpdates() {
        batchTimer?.invalidate()
        batchTimer = nil
    }
    
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
    
    func scheduleUpdate(_ update: @escaping () -> Void) {
        if isRealtimeProcessing {
            updateQueue.async { [weak self] in
                self?.pendingUpdates.append(update)
            }
        } else {
            Task { @MainActor in
                update()
            }
        }
    }
}

// MARK: - Performance Manager
class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    @Published var currentMetrics: [String: PerformanceMetrics] = [:]
    @Published var averageDurations: [String: TimeInterval] = [:]
    @Published var realtimeFactor: Double = 0.0
    
    private var measurementCounts: [String: Int] = [:]
    private let metricsQueue = DispatchQueue(label: "com.Cription.performance", qos: .utility)
    
    private init() {}
    
    func startMeasurement(_ operation: String) {
        metricsQueue.async { [weak self] in
            self?.currentMetrics[operation] = PerformanceMetrics()
        }
    }
    
    func endMeasurement(_ operation: String) {
        metricsQueue.async { [weak self] in
            guard var metrics = self?.currentMetrics[operation] else { return }
            metrics.finish()
            self?.currentMetrics[operation] = metrics
            
            let count = (self?.measurementCounts[operation] ?? 0) + 1
            self?.measurementCounts[operation] = count
            
            let currentAverage = self?.averageDurations[operation] ?? 0.0
            let newAverage = (currentAverage * Double(count - 1) + metrics.duration) / Double(count)
            self?.averageDurations[operation] = newAverage
        }
    }
    
    func updateRealtimeFactor(_ factor: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.realtimeFactor = factor
        }
    }
}

// MARK: - Supporting Types
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

enum LogCategory: String {
    case stt = "STT"
    case token = "Token"
    case ui = "UI"
    case performance = "Performance"
    case audio = "Audio"
    case model = "Model"
}

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

// MARK: - Convenience Functions
func LogDebug(_ message: String, category: LogCategory = .stt) {
    let logger = Logger(subsystem: "com.Cription.whisperax", category: "main")
    logger.log(level: .debug, "[\(category.rawValue)] \(message)")
}

func LogError(_ message: String, category: LogCategory = .stt) {
    let logger = Logger(subsystem: "com.Cription.whisperax", category: "main")
    logger.log(level: .error, "[\(category.rawValue)] \(message)")
}

// MARK: - Language Detection Configuration
struct LanguageDetectionConfig {
    let enableUnicodeAnalysis: Bool
    let enableStatisticalAnalysis: Bool
    let maxFallbacks: Int
    
    static let `default` = LanguageDetectionConfig(
        enableUnicodeAnalysis: true,
        enableStatisticalAnalysis: true,
        maxFallbacks: 3
    )
}

// MARK: - Language Detection Result
struct LanguageDetectionResult {
    let language: String
    let confidence: Double
    let fallbackLanguages: [String]
}

// MARK: - Language Detection Manager
class LanguageDetectionManager {
    private let config: LanguageDetectionConfig
    
    init(config: LanguageDetectionConfig = .default) {
        self.config = config
    }
    
    /// Get system preferred language (Apple SpeechAnalyzer approach)
    private func getSystemPreferredLanguage() -> String {
        // Get system preferred languages
        let preferredLanguages = Locale.preferredLanguages
        let currentLocale = Locale.current
        
        // Get system language
        if let systemLanguage = currentLocale.language.languageCode?.identifier {
            return systemLanguage
        }
        
        // Fallback: first preferred language
        if let firstLanguage = preferredLanguages.first {
            let locale = Locale(identifier: firstLanguage)
            return locale.language.languageCode?.identifier ?? "en"
        }
        
        return "en" // Final fallback
    }

    
    /// Generate fallback languages (100 language support)
    private func generateFallbacks(for language: String) -> [String] {
        let fallbackMap: [String: [String]] = [
            // East Asian languages
            "zh": ["ja", "ko", "yue", "en"],
            "ja": ["zh", "ko", "en"],
            "ko": ["ja", "zh", "en"],
            "yue": ["zh", "en"],
            
            // Arabic language family
            "ar": ["he", "fa", "ur", "ps", "en"],
            "he": ["ar", "en"],
            "fa": ["ar", "ur", "ps", "en"],
            "ur": ["ar", "fa", "hi", "en"],
            "ps": ["ar", "fa", "en"],
            
            // Slavic language family
            "ru": ["uk", "bg", "be", "kk", "uz", "tg", "tk", "mn", "en"],
            "uk": ["ru", "be", "en"],
            "bg": ["ru", "mk", "sr", "en"],
            "mk": ["bg", "sr", "en"],
            "sr": ["hr", "bs", "bg", "mk", "en"],
            "hr": ["sr", "bs", "sl", "en"],
            "bs": ["sr", "hr", "en"],
            "sl": ["hr", "sk", "cs", "en"],
            "sk": ["cs", "sl", "en"],
            "cs": ["sk", "sl", "en"],
            "pl": ["cs", "sk", "en"],
            "be": ["ru", "uk", "en"],
            
            // Central Asian and Turkish language family
            "tr": ["az", "uz", "kk", "tk", "en"],
            "az": ["tr", "uz", "kk", "en"],
            "uz": ["tr", "az", "kk", "tg", "en"],
            "kk": ["uz", "az", "tr", "en"],
            "tg": ["uz", "fa", "en"],
            "tk": ["tr", "uz", "en"],
            
            // Mongolian language family
            "mn": ["ru", "kk", "en"],
            
            // Indo-Iranian language family
            "hi": ["ur", "bn", "gu", "pa", "mr", "ne", "en"],
            "bn": ["hi", "as", "en"],
            "as": ["bn", "hi", "en"],
            "gu": ["hi", "pa", "mr", "en"],
            "pa": ["hi", "gu", "ur", "en"],
            "mr": ["hi", "gu", "en"],
            "ne": ["hi", "en"],
            "ta": ["te", "kn", "ml", "en"],
            "te": ["ta", "kn", "ml", "en"],
            "kn": ["ta", "te", "ml", "en"],
            "ml": ["ta", "te", "kn", "en"],
            "si": ["ta", "en"],
            
            // Southeast Asian languages
            "th": ["lo", "km", "en"],
            "lo": ["th", "km", "en"],
            "km": ["th", "lo", "vi", "en"],
            "vi": ["km", "en"],
            "my": ["th", "en"],
            "id": ["ms", "en"],
            "ms": ["id", "en"],
            "tl": ["en"],
            
            // European languages
            "en": ["es", "fr", "de", "it", "pt", "nl", "sv", "da", "no", "fi"],
            "es": ["pt", "it", "fr", "en"],
            "pt": ["es", "it", "fr", "en"],
            "fr": ["es", "it", "pt", "en"],
            "it": ["es", "fr", "pt", "en"],
            "de": ["nl", "sv", "da", "no", "en"],
            "nl": ["de", "af", "en"],
            "af": ["nl", "en"],
            "sv": ["da", "no", "de", "en"],
            "da": ["sv", "no", "de", "en"],
            "no": ["sv", "da", "de", "nn", "en"],
            "nn": ["no", "sv", "da", "en"],
            "fi": ["et", "sv", "en"],
            "et": ["fi", "lv", "lt", "en"],
            "lv": ["et", "lt", "en"],
            "lt": ["lv", "et", "en"],
            "is": ["da", "no", "sv", "en"],
            "fo": ["da", "no", "is", "en"],
            
            // Baltic-Slavic language family
            "hu": ["ro", "sk", "en"],
            "ro": ["hu", "bg", "en"],
            
            // Celtic language family
            "cy": ["en"],
            "ga": ["en"],
            "gd": ["en"],
            "br": ["fr", "en"],
            
            // Other European languages
            "el": ["en"],
            "mt": ["it", "en"],
            "sq": ["en"],
            "eu": ["es", "fr", "en"],
            "oc": ["fr", "es", "en"],
            "lb": ["de", "fr", "en"],
            
            // African languages
            "sw": ["en"],
            "ha": ["en"],
            "yo": ["en"],
            "sn": ["en"],
            "ln": ["en"],
            "mg": ["en"],
            "so": ["en"],
            
            // Pacific languages
            "mi": ["en"],
            "haw": ["en"],
            
            // Others
            "bo": ["en"],
            "sa": ["hi", "en"],
            "yi": ["he", "de", "en"],
            "la": ["it", "es", "fr", "en"]
        ]
        
        return Array(fallbackMap[language]?.prefix(config.maxFallbacks) ?? ["en"])
    }
}

// MARK: - Shimmer Text Effect
struct ShimmerText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .overlay(
                Text(text)
                    .font(font)
                    .foregroundColor(.clear)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .scaleEffect(x: 3, y: 1)
                        .offset(x: isAnimating ? 200 : -200)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    )
                    .mask(
                        Text(text)
                            .font(font)
                    )
            )
            .onAppear {
                isAnimating = true
            }
    }
}


import AVFoundation
import CoreML

struct ContentView: View {
    // WhisperKit instance is obtained from WhisperModelManager
    private var whisperKit: WhisperKit? {
        modelManager.whisperKit
    }
    #if os(macOS)
    @State private var audioDevices: [AudioDevice]?
    #endif
    @State private var isRecording: Bool = false
    @State private var isTranscribing: Bool = false
    @State private var currentText: String = ""
    @State private var stableDecoderText: String = ""
    @State private var decoderUpdateTimer: Timer?
    @State private var currentChunks: [Int: (chunkText: [String], fallbacks: Int)] = [:]
    // TODO: Make this configurable in the UI
    @State private var modelStorage: String = "huggingface/models/argmaxinc/whisperkit-coreml"
    @State private var appStartTime = Date()
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var modelManager: WhisperModelManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tranCriptionServiceManager: TranCriptionServiceManager
    @StateObject private var analyticsManager = AnalyticsManager.shared
    // @StateObject private var usageManager = UsageTrackingManager.shared
    @State private var selectedCategoryId: MenuItem.ID?
    @State private var isRefreshing: Bool = false
    
    // MARK: Audio waveform display
    @State private var audioSamples: [Float] = []
    @State private var waveformUpdateTimer: Timer?

    // MARK: Menu items for navigation
    
    struct MenuItem: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var image: String
    }

    private var menu = [
        MenuItem(name: "TranCription", image: "book.pages"),
        MenuItem(name: "Stream", image: "waveform.badge.mic"),
    ]

    // MARK: Model management

    // modelState is obtained from WhisperModelManager
    private var modelState: ModelState {
        modelManager.modelState
    }
    
    // Get display name of selected model
    private var selectedModelDisplayName: String {
        if let model = WhisperModels.shared.getModel(by: selectedModel) {
            return model.displayName
        }
        return selectedModel.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
    // Check if selected model is OpenAI model
    private func isOpenAIModel(_ modelId: String) -> Bool {
        return modelId == "whisper-1" || modelId == "gpt-4o-transcribe" || modelId == "gpt-4o-mini-transcribe"
    }
    
    @State private var localModels: [String] = []
    @State private var localModelPath: String = ""
    @State private var availableModels: [String] = []
    @State private var availableLanguages: [String] = []
    @State private var disabledModels: [String] = WhisperKit.recommendedModels().disabled

    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = String(localized: LocalizedStringResource("No Audio Input", comment: "No audio input default"))
    @AppStorage("selectedModel") private var selectedModel: String = "openai_whisper-small_216MB"
    @AppStorage("selectedTask") private var selectedTask: String = "transcribe"
    @State private var selectedDecodingTask: DecodingTask = .transcribe
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "auto"
    @AppStorage("translateTargetLanguage") private var translateTargetLanguage: String = "ja"
    @AppStorage("repoName") private var repoName: String = "argmaxinc/whisperkit-coreml"
    @AppStorage("enableTimestamps") private var enableTimestamps: Bool = true
    @AppStorage("enablePromptPrefill") private var enablePromptPrefill: Bool = true
    @AppStorage("enableCachePrefill") private var enableCachePrefill: Bool = true
    @AppStorage("enableSpecialCharacters") private var enableSpecialCharacters: Bool = false
    @AppStorage("enableEagerDecoding") private var enableEagerDecoding: Bool = false
    @AppStorage("enableDecoderPreview") private var enableDecoderPreview: Bool = true
    @AppStorage("preserveTextOnRecording") private var preserveTextOnRecording: Bool = true
    @AppStorage("hideIconsDuringSTT") private var hideIconsDuringSTT: Bool = false
    @AppStorage("temperatureStart") private var temperatureStart: Double = 0.0
    @AppStorage("enableFixedTemperature") private var enableFixedTemperature: Bool = true
    @AppStorage("fixedTemperatureValue") private var fixedTemperatureValue: Double = 0.0
    @AppStorage("fallbackCount") private var fallbackCount: Double = 1
    @AppStorage("compressionCheckWindow") private var compressionCheckWindow: Double = 30
    @AppStorage("sampleLength") private var sampleLength: Double = 100
    @AppStorage("silenceThreshold") private var silenceThreshold: Double = 0.2
    @AppStorage("realtimeDelayInterval") private var realtimeDelayInterval: Double = 0.3
    @AppStorage("useVAD") private var useVAD: Bool = true
    @AppStorage("tokenConfirmationsNeeded") private var tokenConfirmationsNeeded: Double = 2
    @AppStorage("concurrentWorkerCount") private var concurrentWorkerCount: Double = 4
    @AppStorage("chunkingStrategy") private var chunkingStrategy: ChunkingStrategy = .vad
    @AppStorage("encoderComputeUnits") private var encoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    @AppStorage("decoderComputeUnits") private var decoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    @AppStorage("showComputeUnits") private var showComputeUnits: Bool = true
    @AppStorage("sttFontSize") private var sttFontSize: Double = 16.0
    @AppStorage("sttFontFamily") private var sttFontFamily: String = String(localized: LocalizedStringResource("System", comment: "System font option"))
    @AppStorage("enableLineBreaks") private var enableLineBreaks: Bool = true
    @AppStorage("lineSpacing") private var lineSpacing: Double = 1.0
    @AppStorage("waveformActionType") private var waveformActionType: String = "clear" // "clear" or "ascii"

    // MARK: Standard properties

    @State private var loadingProgressValue: Float = 0.0
    @State private var specializationProgressRatio: Float = 0.7
    @State private var isFilePickerPresented = false
    @State private var isFileLoading = false
    @State private var fileLoadingProgress: Float = 0.0
    @State private var isResampling = false
    @State private var resamplingProgress: Float = 0.0
    @State private var modelLoadingTime: TimeInterval = 0
    @State private var firstTokenTime: TimeInterval = 0
    @State private var pipelineStart: TimeInterval = 0
    @State private var effectiveRealTimeFactor: TimeInterval = 0
    @State private var effectiveSpeedFactor: TimeInterval = 0
    @State private var totalInferenceTime: TimeInterval = 0
    @State private var tokensPerSecond: TimeInterval = 0
    @State private var currentLag: TimeInterval = 0
    @State private var currentFallbacks: Int = 0
    @State private var currentEncodingLoops: Int = 0
    @State private var currentDecodingLoops: Int = 0
    @State private var lastBufferSize: Int = 0
    @State private var lastConfirmedSegmentEndSeconds: Float = 0
    @State private var requiredSegmentsForConfirmation: Int = 3
    @State private var bufferSeconds: Double = 0
    @State private var confirmedSegments: [TranCriptionSegment] = []
    @State private var unconfirmedSegments: [TranCriptionSegment] = []
    @State private var processedSegmentTimestamps: Set<String> = []
    
    // Variables for STT time measurement
    @State private var sttStartTime: Date?
    @State private var sttEndTime: Date?
    @State private var sttProcessingTime: TimeInterval = 0

    // MARK: Eager mode properties

    @State private var eagerResults: [CriptionTranCriptionResult?] = []
    @State private var prevResult: CriptionTranCriptionResult?
    @State private var lastAgreedSeconds: Float = 0.0
    @State private var prevWords: [WordTiming] = []
    @State private var lastAgreedWords: [WordTiming] = []
    @State private var confirmedWords: [WordTiming] = []
    @State private var confirmedText: String = ""
    @State private var hypothesisWords: [WordTiming] = []
    @State private var hypothesisText: String = ""

    // MARK: UI properties

    @State private var showAdvancedOptions: Bool = false
    @State private var showDashboardView: Bool = false
    @State private var showTokenCalculator: Bool = false
    @State private var showUIElements: Bool = true
    @State private var showLanguageSelection: Bool = false
    @State private var showCriptionPlus: Bool = false
    @State private var tranCriptionTask: Task<Void, Never>?
    @State private var isCopied: Bool = false
    @State private var audioLevels: [Float] = Array(repeating: 0.0, count: 20)
    @State private var waveformTimer: Timer?
    @State private var streamingTimer: Timer?
    @State private var isEditingText: Bool = false
    @State private var editedText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @State private var showIcon: Bool = false
    @State private var iconPosition: CGPoint = .zero
    @State private var sharedTexts: [String] = []
    @State private var showSharedTexts: Bool = false
    @State private var customPrompt: String = ""
    @State private var showPromptInput: Bool = false
    
    
    private var isStreamMode: Bool {
        selectedCategoryId == menu.first(where: { $0.name == "Stream" })?.id
    }
    
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemBackground)
        #endif
    }
    
    private var strokeColor: Color {
        #if os(macOS)
        return Color(NSColor.separatorColor)
        #else
        return Color(.systemGray4)
        #endif
    }

    func getComputeOptions() -> ModelComputeOptions {
        return ModelComputeOptions(audioEncoderCompute: encoderComputeUnits, textDecoderCompute: decoderComputeUnits)
    }
    
    /// 言語コードから言語名を取得するヘルパー関数
    private func getLanguageName(for languageCode: String) -> String {
        for (name, code) in Constants.languages {
            if code == languageCode {
                return name
            }
        }
        return "japanese" // デフォルト
    }
    
    
    func loadSharedTexts() {
        if let sharedDefaults = UserDefaults(suiteName: "group.Cription.ai") {
            sharedTexts = sharedDefaults.stringArray(forKey: "sharedTexts") ?? []
        }
    }
    

    // MARK: Views
    
    
    var sourceLanguageHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Source Language選択
                Button(action: {
                    showLanguageSelection = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        // selectedLanguage（言語名）を言語コードに変換してから表示名を取得
                        Text(languageManager.languageDisplayName(for: Constants.languages[selectedLanguage] ?? selectedLanguage))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // TranCription/Translate切り替え
                HStack(spacing: 0) {
                    // TranCription ボタン
                    Button(action: {
                        selectedTask = "tranCription"
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 14, weight: .medium))
                            Text("Transcribe")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedTask == "tranCription" ? .white : .primary)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTask == "tranCription" ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .liquidGlass()
                    
                    // Translate ボタン
                    Button(action: {
                        selectedTask = "translate"
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.arrow.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Translate")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(selectedTask == "translate" ? .white : .primary)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedTask == "translate" ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .liquidGlass()
                }
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.quaternary, lineWidth: 1)
                )
            }
            
            // Translation Target Language選択（translateモードの時のみ表示）
            if selectedTask == "translate" {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(Array(Constants.languages.keys).sorted(), id: \.self) { languageName in
                            if let languageCode = Constants.languages[languageName], languageCode != "auto" {
                                Button(action: {
                                    translateTargetLanguage = languageCode
                                }) {
                                    HStack {
                                        Text(languageManager.languageDisplayName(for: languageCode))
                                        if translateTargetLanguage == languageCode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Target:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(languageManager.languageDisplayName(for: translateTargetLanguage))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                    }
                }
                .transition(.opacity)
            }
        }
    }
    
    var waveformView: some View {
        HStack(spacing: 2) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 3, height: max(2, CGFloat(audioLevels[index]) * 30))
                    .animation(.easeInOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .frame(height: 40)
    }
    
    var taskToggleView: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 0) {
                // TranCription ボタン
                Button(action: {
                    selectedTask = "tranCription"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 14, weight: .medium))
                        Text("TranCription")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedTask == "tranCription" ? .white : .primary)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTask == "tranCription" ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                
                // Translate ボタン
                Button(action: {
                    selectedTask = "translate"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.arrow.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Translate")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedTask == "translate" ? .white : .primary)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTask == "translate" ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 25))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.quaternary, lineWidth: 1)
            )
            
            Spacer()
        }
    }
    
    var bottomButtonRow: some View {
        HStack(spacing: 40) {
            // File selection button
            fileSelectButton
            
            // 録音ボタン
            recordButton
        }
        .padding(.bottom, 0)
    }
    
    var fileSelectButton: some View {
        Button(action: {
            selectFile()
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.primary)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.2), value: modelState)
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.audio, .movie],
            allowsMultipleSelection: false,
            onCompletion: handleFilePicker
        )
        .buttonStyle(PlainButtonStyle())
        .liquidGlassButton()
    }
    
    var sharedTextsButton: some View {
        Button(action: {
            showSharedTexts = true
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.primary)
                .scaleEffect(1.0)
                .overlay(
                    // 共有テキストがある場合のバッジ
                    Group {
                        if !sharedTexts.isEmpty {
                            Text("\(sharedTexts.count)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 15, y: -15)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
    var recordButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                toggleRecording(shouldLoop: true)
            }
        }) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(isRecording ? .accentColor : .primary)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .buttonStyle(PlainButtonStyle())
        .liquidGlassButton()
    }

    func resetState(preserveText: Bool = false) {
        tranCriptionTask?.cancel()
        isRecording = false
        isTranscribing = false
        whisperKit?.audioProcessor.stopRecording()
        
        // 波形アニメーションを停止
        stopWaveformAnimation()
        
        // テキスト保持オプションが有効でない場合のみクリア
        if !preserveText {
            currentText = ""
            currentChunks = [:]
            confirmedSegments = []
            unconfirmedSegments = []
            processedSegmentTimestamps = []
            confirmedWords = []
            confirmedText = ""
            hypothesisWords = []
            hypothesisText = ""
        }

        pipelineStart = Double.greatestFiniteMagnitude
        firstTokenTime = Double.greatestFiniteMagnitude
        effectiveRealTimeFactor = 0
        effectiveSpeedFactor = 0
        totalInferenceTime = 0
        tokensPerSecond = 0
        currentLag = 0
        currentFallbacks = 0
        currentEncodingLoops = 0
        currentDecodingLoops = 0
        lastBufferSize = 0
        lastConfirmedSegmentEndSeconds = 0
        requiredSegmentsForConfirmation = 2
        bufferSeconds = 0

        eagerResults = []
        prevResult = nil
        lastAgreedSeconds = 0.0
        prevWords = []
        lastAgreedWords = []
        
        // STT時間計測をリセット
        sttStartTime = nil
        sttEndTime = nil
        sttProcessingTime = 0
    }

    var body: some View {
        mainContentView
            .sheet(isPresented: $showDashboardView) {
                dashboardSheet
            }
            .sheet(isPresented: $showSharedTexts) {
                sharedTextsSheet
            }
            .sheet(isPresented: $showLanguageSelection) {
                languageSelectionSheet
            }
            .sheet(isPresented: $showAdvancedOptions) {
                settingsSheet
            }
            .sheet(isPresented: $showTokenCalculator) {
                tokenCalculatorSheet
            }
            .sheet(isPresented: $showCriptionPlus) {
                CriptionPlusView()
                    .environmentObject(themeManager)
            }
            .fullScreenCover(isPresented: $tranCriptionServiceManager.showingCreditPurchaseSheet) {
                NavigationView {
                    CreditPurchaseView()
                        .environmentObject(themeManager)
                }
            }
            // .sheet(isPresented: $tranCriptionServiceManager.showingTokenLimitPrompt) {
            //     TokenLimitPromptView()
            //         .environmentObject(themeManager)
            // }
            .onAppear {
                onAppearAction()
            }
            .onChange(of: selectedDecodingTask) { newValue in
                selectedTask = newValue == .transcribe ? "tranCription" : "translate"
            }
            .onReceive(NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)) { _ in
                handleLocaleChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                handleLanguageChange()
            }
            .onDisappear {
                handleDisappear()
            }
    }
    
    private var mainContentView: some View {
        NavigationView {
            contentVStack
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTapGesture()
                }
                .toolbar {
                    toolbarContent
                }
        }
    }
    
    private var contentVStack: some View {
        VStack(spacing: 0) {
            // Source Language設定（上部中央）
            if shouldShowSourceLanguage {
                HStack {
                    Spacer()
                    sourceLanguageHeader
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            
            // メインのテキスト表示エリア
            tranCriptionView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 録音中の波形表示（タップで切り替え + STT中は非表示オプション）
            if shouldShowWaveform {
                waveformView
                    .padding(.bottom, 20)
            }
            
            // 統合されたチャット入力ボックス（タップで切り替え + STT中は非表示オプション）
            if shouldShowChatInput {
                chatInputBox
            }
        }
    }
    
    private var chatInputBox: some View {
        ChatInputBoxView(
            isRecording: $isRecording,
            isTranscribing: $isTranscribing,
            selectedTask: $selectedTask,
            showUIElements: $showUIElements,
            hideIconsDuringSTT: $hideIconsDuringSTT,
            isFilePickerPresented: $isFilePickerPresented,
            selectedModel: $selectedModel,
            customPrompt: $customPrompt,
            showPromptInput: $showPromptInput,
            onFileSelect: {
                selectFile()
            },
            onToggleRecording: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toggleRecording(shouldLoop: true)
                }
            },
            onTaskToggle: {
                // タスク切り替えのロジック（必要に応じて実装）
            },
            onFilePickerResult: handleFilePicker
        )
        .environmentObject(modelManager)
    }
    
    private func handleTapGesture() {
        // 画面をタップしてUI要素の表示/非表示を切り替え
        print("Tap detected - showUIElements: \(showUIElements), hideIconsDuringSTT: \(hideIconsDuringSTT)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // STT中でhideIconsDuringSTTがオンの場合、hideIconsDuringSTTをオフにする
            if (isRecording || isTranscribing) && hideIconsDuringSTT {
                hideIconsDuringSTT = false
                showUIElements = true
                print("STT中にタップ: hideIconsDuringSTTをオフにしました")
            } else {
                // 通常の表示/非表示切り替え
                showUIElements.toggle()
                print("通常のタップ: showUIElementsを切り替えました")
            }
        }
        print("After toggle - showUIElements: \(showUIElements), hideIconsDuringSTT: \(hideIconsDuringSTT)")
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // STT中はツールバーアイコンも非表示オプション + タップで切り替え
        if showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing)) {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    showDashboardView = true
                }) {
                    Image(systemName: "equal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .opacity(0.5)
                }
            }
            
            // Upgradeを中央寄せで配置
            ToolbarItem(placement: .principal) {
                Button(action: {
                    showCriptionPlus = true
                }) {
                    Text("Upgrade")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor)
                        )
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showAdvancedOptions = true
                }) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .opacity(0.5)
                }
            }
        }
    }
}

// MARK: - View Extensions for Modifiers
extension ContentView {
    // MARK: - Sheet Views
    var dashboardSheet: some View {
        DashboardView()
            .environmentObject(themeManager)
    }
    
    var sharedTextsSheet: some View {
        SharedTextsView(sharedTexts: $sharedTexts)
    }
    
    var languageSelectionSheet: some View {
        LanguageSelectionView(selectedLanguage: $selectedLanguage)
    }
    
    var settingsSheet: some View {
        SettingsView(
            whisperKit: .constant(modelManager.whisperKit),
            modelState: .constant(modelManager.modelState),
            selectedModel: $selectedModel,
            availableModels: $availableModels,
            localModels: $localModels,
            localModelPath: $localModelPath,
            loadingProgressValue: $loadingProgressValue,
            showComputeUnits: $showComputeUnits,
            encoderComputeUnits: $encoderComputeUnits,
            decoderComputeUnits: $decoderComputeUnits,
            selectedTask: $selectedDecodingTask,
            selectedLanguage: $selectedLanguage,
            availableLanguages: $availableLanguages,
            enableTimestamps: $enableTimestamps,
            enablePromptPrefill: $enablePromptPrefill,
            enableCachePrefill: $enableCachePrefill,
            enableSpecialCharacters: $enableSpecialCharacters,
            enableEagerDecoding: $enableEagerDecoding,
            enableDecoderPreview: $enableDecoderPreview,
            preserveTextOnRecording: $preserveTextOnRecording,
            hideIconsDuringSTT: $hideIconsDuringSTT,
            temperatureStart: $temperatureStart,
            enableFixedTemperature: $enableFixedTemperature,
            fixedTemperatureValue: $fixedTemperatureValue,
            fallbackCount: $fallbackCount,
            compressionCheckWindow: $compressionCheckWindow,
            sampleLength: $sampleLength,
            silenceThreshold: $silenceThreshold,
            realtimeDelayInterval: $realtimeDelayInterval,
            useVAD: $useVAD,
            tokenConfirmationsNeeded: $tokenConfirmationsNeeded,
            concurrentWorkerCount: $concurrentWorkerCount,
            chunkingStrategy: $chunkingStrategy,
            selectedAudioInput: $selectedAudioInput,
            audioDevices: .constant([]),
            repoName: $repoName,
            sttFontSize: $sttFontSize,
            sttFontFamily: $sttFontFamily,
            enableLineBreaks: $enableLineBreaks,
            lineSpacing: $lineSpacing,
            onLoadModel: { model in
                loadModel(model)
            },
            onDeleteModel: {
                deleteModel()
            },
            onFetchModels: {
                fetchModels()
            }
        )
        .environmentObject(modelManager)
        .environmentObject(themeManager)
    }
    
    private var tokenCalculatorSheet: some View {
        NavigationView {
            TokenCalculatorView()
                .navigationTitle(String(localized: LocalizedStringResource("Token Calculator", comment: "Token calculator title")))
                #if os(iOS)
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                            showTokenCalculator = false
                        }
                    }
                }
        }
    }
    
    // MARK: - Lifecycle Methods
    func onAppearAction() {
        fetchModels()
        
        // 確実に文字起こしモードに設定（翻訳モードを無効化）
        selectedTask = "transcribe"
        selectedDecodingTask = .transcribe
        
        // UserDefaultsも強制的に更新（古い値が残っている場合の対策）
        UserDefaults.standard.set("transcribe", forKey: "selectedTask")
        
        // @AppStorageの値を強制的に同期
        selectedTask = "transcribe"
        
        // デバッグログ
        print("🔧 TASK SETTING DEBUG:")
        print("  selectedTask set to: 'transcribe'")
        print("  UserDefaults selectedTask: '\(UserDefaults.standard.string(forKey: "selectedTask") ?? "nil")'")
        print("  @AppStorage selectedTask: '\(selectedTask)'")
        print("  selectedDecodingTask: \(selectedDecodingTask)")
        
        // 既存ユーザーのために、古いデフォルト値をリセット（初回のみ）
        if selectedLanguage == "japanese" && UserDefaults.standard.object(forKey: "hasResetLanguageToAuto") == nil {
            selectedLanguage = "auto"
            UserDefaults.standard.set(true, forKey: "hasResetLanguageToAuto")
        }
        
        // "auto"の場合はLanguageManagerに保存せず、sourceLanguageCodeもクリア
        if selectedLanguage == "auto" {
            UserDefaults.standard.removeObject(forKey: "sourceLanguageCode")
        } else {
            // 言語設定はユーザーの選択を保持（強制変更しない）
            // ただし、LanguageManagerとの同期は確保
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            languageManager.setLanguage(currentLanguageCode)
        }
        
        // 言語設定のデバッグ情報を出力
        print("🔍 ON_APPEAR LANGUAGE DEBUG:")
        print("LanguageManager currentLanguage: \(languageManager.currentLanguage)")
        print("selectedLanguage: \(selectedLanguage)")
        print("UserDefaults selectedLanguage: \(UserDefaults.standard.string(forKey: "selectedLanguage") ?? "nil")")
        print("Constants.languages mapping: \(Constants.languages[selectedLanguage] ?? "NOT_FOUND")")
        print("Constants.defaultLanguageCode: \(Constants.defaultLanguageCode)")
        print("Language Code from selectedLanguage: \(Constants.languages[selectedLanguage] ?? "NOT_FOUND")")
        
        // WhisperModelManagerのselectedModelとAppStorageを同期
        if !modelManager.selectedModel.isEmpty {
            selectedModel = modelManager.selectedModel
        }
        
        // 共有されたテキストを読み込み
        loadSharedTexts()
    }
    
    func handleLocaleChange() {
        // 端末の言語設定が変更された時の処理（ユーザーの選択を尊重）
        if selectedLanguage != "auto" {
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            languageManager.setLanguage(currentLanguageCode)
        }
    }
    
    func handleLanguageChange() {
        // 言語変更の通知を受け取って画面を強制更新
        // LanguageManagerとの同期を確保（ユーザーの選択を変更しない）
        if selectedLanguage != "auto" {
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            if languageManager.currentLanguage != currentLanguageCode {
                languageManager.setLanguage(currentLanguageCode)
            }
        }
    }
    
    func handleDisappear() {
        // タイマーをクリーンアップ
        streamingTimer?.invalidate()
        streamingTimer = nil
    }
    
    
    // MARK: - Computed Properties
    private var shouldShowSourceLanguage: Bool {
        showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing))
    }
    
    private var shouldShowWaveform: Bool {
        isRecording && showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing))
    }
    
    private var shouldShowChatInput: Bool {
        showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing))
    }
    
    // MARK: - TranCription

    var tranCriptionView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // STT結果のテキスト表示部分
                if !getTranCriptionText().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditingText {
                            // 編集モード（インライン編集）
                            TextField("", text: $editedText, axis: .vertical)
                                .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                .lineLimit(1...10)
                                .focused($isTextEditorFocused)
                                .onAppear {
                                    editedText = getTranCriptionText()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isTextEditorFocused = true
                                    }
                                }
                        } else {
                            // 表示モード
                            if enableEagerDecoding {
                                let startSeconds = eagerResults.first??.segments.first?.start ?? 0
                                let endSeconds = lastAgreedSeconds > 0 ? Double(lastAgreedSeconds) : eagerResults.last??.segments.last?.end ?? 0
                                let timestampText = (enableTimestamps && eagerResults.first != nil) ? "[\(String(format: "%.2f", startSeconds)) --> \(String(format: "%.2f", endSeconds))] " : ""
                                let displayText = timestampText + confirmedText + (hypothesisText.isEmpty ? "" : " " + hypothesisText)
                                Text(displayText)
                                    .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                // 確定済みテキスト（固定表示）
                                ForEach(Array(confirmedSegments.enumerated()), id: \.offset) { _, segment in
                                    let timestampText = enableTimestamps ? "[\(String(format: "%.2f", segment.start)) --> \(String(format: "%.2f", segment.end))] " : ""
                                    Text(timestampText + segment.text)
                                        .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                // 未確定テキスト（動的表示、グレーアウト）
                                ForEach(Array(unconfirmedSegments.enumerated()), id: \.offset) { _, segment in
                                    let timestampText = enableTimestamps ? "[\(String(format: "%.2f", segment.start)) --> \(String(format: "%.2f", segment.end))] " : ""
                                    Text(timestampText + segment.text)
                                        .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        
                        // コピーボタンとSTT時間表示（録音中は非表示）
                        if !isRecording {
                            HStack {
                                Spacer()
                                
                                // 編集ボタン
                                if isEditingText {
                                    // 保存ボタン
                                    Button(action: {
                                        saveEditedText()
                                        isEditingText = false
                                        isTextEditorFocused = false
                                    }) {
                                        Text(String(localized: LocalizedStringResource("Done", comment: "Done button text")))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // キャンセルボタン
                                    Button(action: {
                                        isEditingText = false
                                        isTextEditorFocused = false
                                    }) {
                                        Text(String(localized: LocalizedStringResource("Cancel", comment: "Cancel button text")))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // 編集ボタン
                                    Button(action: {
                                        editedText = getTranCriptionText()
                                        isEditingText = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isTextEditorFocused = true
                                        }
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(getTranCriptionText().isEmpty)
                                }
                                
                                // 共有ボタン（編集モード中は無効）
                                if !isEditingText {
                                    Button(action: {
                                        shareText()
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(getTranCriptionText().isEmpty)
                                }
                                
                                // コピーボタン（編集モード中は無効）
                                if !isEditingText {
                                    Button(action: {
                                        let textToCopy = getTranCriptionText()
                                        if !textToCopy.isEmpty {
                                            copyToClipboard(textToCopy)
                                        }
                                    }) {
                                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(isCopied ? .green : .secondary)
                                            .padding(4)
                                            .animation(.easeInOut(duration: 0.2), value: isCopied)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(getTranCriptionText().isEmpty)
                                }
                            }
                        }
                    }
                }
                
                if enableDecoderPreview && !stableDecoderText.isEmpty {
                    Text("\(stableDecoderText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                }
                
                if modelState != .loaded {
                    VStack(spacing: 20) {
                        // モデル最適化プロセスの表示
                        if modelManager.isOptimizing {
                            VStack(spacing: 16) {
                                ProgressView(value: modelManager.optimizationProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                    .tint(Color(hex: "1CA485"))
                                
                                ShimmerText(
                                    text: modelManager.optimizationStatus,
                                    font: .headline,
                                    color: .secondary
                                )
                                .multilineTextAlignment(.center)
                                
                            }
                        } else if modelState == .downloading || modelState == .prewarming || modelState == .loading {
                            VStack(spacing: 16) {
                                ProgressView(value: modelManager.optimizationProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                    .tint(Color(hex: "1CA485"))
                                
                                Text(modelManager.optimizationStatus)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .refreshable {
            await refreshContent()
        }
        .textSelection(.enabled)
        .overlay(alignment: .center) {
            if isFileLoading {
                VStack(spacing: 16) {
                    ProgressView(value: fileLoadingProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .labelsHidden()
                        .frame(width: 200)
                        .tint(Color(hex: "1CA485"))
                    
                    Text(String(localized: LocalizedStringResource("Loading...", comment: "Loading indicator text")))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding()
            } else if isResampling {
                VStack(spacing: 16) {
                    ProgressView(value: resamplingProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .labelsHidden()
                        .frame(width: 200)
                        .tint(Color(hex: "1CA485"))
                    
                    Text(String(localized: LocalizedStringResource("Scribing", comment: "Processing indicator text")))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding()
            } else if let whisperKit,
               isTranscribing,
               isRecording, // リアルタイム録音中のみ音声波形を表示
               let task = tranCriptionTask,
               !task.isCancelled,
               whisperKit.progress.fractionCompleted < 1
            {
                // 音声波形表示（画面下側に固定）
                VStack {
                    Spacer()
                    AudioWaveformView(audioSamples: $audioSamples)
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 0)
                }
            }
        }
    }


    
    // MARK: - Logic
    
    func saveEditedText() {
        if enableEagerDecoding {
            confirmedText = editedText
            hypothesisText = ""
        } else {
            // セグメントベースの場合は、編集されたテキストを単一のセグメントとして扱う
            let newSegment = TranCriptionSegment(
                start: confirmedSegments.first?.start ?? 0.0,
                end: confirmedSegments.last?.end ?? 0.0,
                text: editedText
            )
            confirmedSegments = [newSegment]
            unconfirmedSegments = []
        }
    }
    
    func shareText() {
        let textToShare = getTranCriptionText()
        guard !textToShare.isEmpty else { return }
        
        #if os(macOS)
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [textToShare])
        #else
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        
        // iPad用の設定
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            window.rootViewController?.present(activityViewController, animated: true)
        }
        #endif
    }
    
    func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
        
        // コピー完了状態を表示
        isCopied = true
        
        // 1.5秒後に元のアイコンに戻す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCopied = false
        }
    }
    
    func getTranCriptionText() -> String {
        let rawText: String
        if enableEagerDecoding {
            rawText = confirmedText + hypothesisText
        } else {
            // セグメントをタイムスタンプ順にソートしてから結合
            let sortedConfirmedSegments = confirmedSegments.sorted { $0.start < $1.start }
            let sortedUnconfirmedSegments = unconfirmedSegments.sorted { $0.start < $1.start }
            
            let confirmedText = sortedConfirmedSegments.map { $0.text }.joined(separator: " ")
            let unconfirmedText = sortedUnconfirmedSegments.map { $0.text }.joined(separator: " ")
            rawText = confirmedText + (unconfirmedText.isEmpty ? "" : " " + unconfirmedText)
        }
        return formatTextWithLineBreaks(rawText)
    }
    
    func formatTextWithLineBreaks(_ text: String) -> String {
        var formattedText = text
        
        // Remove all text within square brackets using regex
        let regex = try! NSRegularExpression(pattern: "\\[[^\\]]*\\]")
        let range = NSRange(location: 0, length: formattedText.utf16.count)
        formattedText = regex.stringByReplacingMatches(in: formattedText, options: [], range: range, withTemplate: "")
        
        // Remove incomplete brackets and specific unwanted patterns
        formattedText = formattedText.replacingOccurrences(of: "[", with: "")
        formattedText = formattedText.replacingOccurrences(of: "]", with: "")
        formattedText = formattedText.replacingOccurrences(of: "（", with: "")
        formattedText = formattedText.replacingOccurrences(of: "）", with: "")
        
        // Remove specific unwanted patterns
        formattedText = formattedText.replacingOccurrences(of: "MUSIC", with: "")
        formattedText = formattedText.replacingOccurrences(of: "BLANK_AUDIO", with: "")
        formattedText = formattedText.replacingOccurrences(of: "NO_SPEECH", with: "")
        formattedText = formattedText.replacingOccurrences(of: "SILENCE", with: "")
        formattedText = formattedText.replacingOccurrences(of: "Inaudible", with: "")
        formattedText = formattedText.replacingOccurrences(of: "inaudible", with: "")
        formattedText = formattedText.replacingOccurrences(of: "INAUDIBLE", with: "")
        formattedText = formattedText.replacingOccurrences(of: "Unintelligible", with: "")
        formattedText = formattedText.replacingOccurrences(of: "unintelligible", with: "")
        formattedText = formattedText.replacingOccurrences(of: "UNINTELLIGIBLE", with: "")
        formattedText = formattedText.replacingOccurrences(of: "Background", with: "")
        formattedText = formattedText.replacingOccurrences(of: "background", with: "")
        formattedText = formattedText.replacingOccurrences(of: "BACKGROUND", with: "")
        formattedText = formattedText.replacingOccurrences(of: "Noise", with: "")
        formattedText = formattedText.replacingOccurrences(of: "noise", with: "")
        formattedText = formattedText.replacingOccurrences(of: "NOISE", with: "")
        
        // Remove standalone brackets and parentheses
        formattedText = formattedText.replacingOccurrences(of: "()", with: "")
        formattedText = formattedText.replacingOccurrences(of: "（）", with: "")
        
        // Clean up extra spaces and empty segments
        formattedText = formattedText.replacingOccurrences(of: "  ", with: " ")
        formattedText = formattedText.replacingOccurrences(of: "   ", with: " ")
        formattedText = formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove empty lines
        let lines = formattedText.components(separatedBy: .newlines)
        let filteredLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        formattedText = filteredLines.joined(separator: "\n")
        
        // Add line breaks after punctuation marks (excluding comma)
        if enableLineBreaks {
            formattedText = formattedText.replacingOccurrences(of: "?", with: "?\n")
            formattedText = formattedText.replacingOccurrences(of: "!", with: "!\n")
            formattedText = formattedText.replacingOccurrences(of: "。", with: "。\n")
            formattedText = formattedText.replacingOccurrences(of: ".", with: ".\n")
            // Note: Comma (,) is intentionally excluded from line breaks
        }
        
        return formattedText
    }
    
    func updateStableDecoderText() {
        decoderUpdateTimer?.invalidate()
        decoderUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async {
                stableDecoderText = currentText
            }
        }
    }
    
    /// Get system preferred language (Apple SpeechAnalyzer approach)
    private func getSystemPreferredLanguage() -> String {
        // Get system preferred languages
        let preferredLanguages = Locale.preferredLanguages
        let currentLocale = Locale.current
        
        // Get system language
        if let systemLanguage = currentLocale.language.languageCode?.identifier {
            return systemLanguage
        }
        
        // Fallback: first preferred language
        if let firstLanguage = preferredLanguages.first {
            let locale = Locale(identifier: firstLanguage)
            return locale.language.languageCode?.identifier ?? "en"
        }
        
        return "en" // Final fallback
    }
    
    /// 言語コードから言語名を取得（100言語対応）
    func getLanguageDisplayName(for code: String) -> String {
        let languageMap: [String: String] = [
            "auto": "Auto",
            "en": "English",
            "zh": "Chinese",
            "de": "German",
            "es": "Spanish",
            "ru": "Russian",
            "ko": "Korean",
            "fr": "French",
            "ja": "Japanese",
            "pt": "Portuguese",
            "tr": "Turkish",
            "pl": "Polish",
            "ca": "Catalan",
            "nl": "Dutch",
            "ar": "Arabic",
            "sv": "Swedish",
            "it": "Italian",
            "id": "Indonesian",
            "hi": "Hindi",
            "fi": "Finnish",
            "vi": "Vietnamese",
            "he": "Hebrew",
            "uk": "Ukrainian",
            "el": "Greek",
            "ms": "Malay",
            "cs": "Czech",
            "ro": "Romanian",
            "da": "Danish",
            "hu": "Hungarian",
            "ta": "Tamil",
            "no": "Norwegian",
            "th": "Thai",
            "ur": "Urdu",
            "hr": "Croatian",
            "bg": "Bulgarian",
            "lt": "Lithuanian",
            "la": "Latin",
            "mi": "Maori",
            "ml": "Malayalam",
            "cy": "Welsh",
            "sk": "Slovak",
            "te": "Telugu",
            "fa": "Persian",
            "lv": "Latvian",
            "bn": "Bengali",
            "sr": "Serbian",
            "az": "Azerbaijani",
            "sl": "Slovenian",
            "kn": "Kannada",
            "et": "Estonian",
            "mk": "Macedonian",
            "br": "Breton",
            "eu": "Basque",
            "is": "Icelandic",
            "hy": "Armenian",
            "ne": "Nepali",
            "mn": "Mongolian",
            "bs": "Bosnian",
            "kk": "Kazakh",
            "sq": "Albanian",
            "sw": "Swahili",
            "gl": "Galician",
            "mr": "Marathi",
            "pa": "Punjabi",
            "si": "Sinhala",
            "km": "Khmer",
            "sn": "Shona",
            "yo": "Yoruba",
            "so": "Somali",
            "af": "Afrikaans",
            "oc": "Occitan",
            "ka": "Georgian",
            "be": "Belarusian",
            "tg": "Tajik",
            "sd": "Sindhi",
            "gu": "Gujarati",
            "am": "Amharic",
            "yi": "Yiddish",
            "lo": "Lao",
            "uz": "Uzbek",
            "fo": "Faroese",
            "ht": "Haitian Creole",
            "ps": "Pashto",
            "tk": "Turkmen",
            "nn": "Nynorsk",
            "mt": "Maltese",
            "sa": "Sanskrit",
            "lb": "Luxembourgish",
            "my": "Myanmar",
            "bo": "Tibetan",
            "tl": "Tagalog",
            "mg": "Malagasy",
            "as": "Assamese",
            "tt": "Tatar",
            "haw": "Hawaiian",
            "ln": "Lingala",
            "ha": "Hausa",
            "ba": "Bashkir",
            "jw": "Javanese",
            "su": "Sundanese",
            "yue": "Cantonese"
        ]
        
        return languageMap[code] ?? code.uppercased()
    }
    
    func startWaveformAnimation() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateAudioLevels()
        }
    }
    
    func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        // 波形をリセット
        audioLevels = Array(repeating: 0.0, count: 20)
    }
    
    func updateAudioLevels() {
        guard let whisperKit = whisperKit else { return }
        
        // 音声レベルを取得（relativeEnergyから）
        let relativeEnergyArray = whisperKit.audioProcessor.relativeEnergy
        let currentLevel = relativeEnergyArray.last ?? 0.0
        
        // 音声レベルを0-1の範囲に正規化
        let normalizedLevel = min(Float(1.0), max(Float(0.0), currentLevel))
        
        // ランダムな要素を追加して自然な波形を作成
        for i in 0..<audioLevels.count {
            let randomFactor = Float.random(in: 0.3...1.0)
            let baseLevel = normalizedLevel * randomFactor
            
            // 前の値との間でスムーズに変化
            audioLevels[i] = audioLevels[i] * Float(0.7) + baseLevel * Float(0.3)
        }
    }
    
    func autoLoadWhisperBase() async {
        await MainActor.run {
            selectedModel = "Quantum Cription mini"
        }
        
        // WhisperModelManagerが自動でロードを実行するため、
        // この関数は不要になった
        print("Auto-load is handled by WhisperModelManager")
    }

    func fetchModels() {
        // Initialize with all available models from WhisperModels
        availableModels = WhisperModels.shared.getModelIds()
        
        // WhisperModelManagerのlocalModelsをベースに開始
        localModels = modelManager.localModels

        // Check for bundled models first
        if let resourceURL = Bundle.main.resourceURL {
            let fileManager = FileManager.default
            do {
                let resourceContents = try fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                for item in resourceContents {
                    let modelName = item.lastPathComponent
                    if modelName.hasPrefix("whisper-") {
                        // Check if this model has the required files
                        let audioEncoderPath = item.appendingPathComponent("AudioEncoder.mlmodelc/model.mil")
                        let textDecoderPath = item.appendingPathComponent("TextDecoder.mlmodelc/model.mil")
                        let melSpectrogramPath = item.appendingPathComponent("MelSpectrogram.mlmodelc/model.mil")
                        
                        if fileManager.fileExists(atPath: audioEncoderPath.path) &&
                           fileManager.fileExists(atPath: textDecoderPath.path) &&
                           fileManager.fileExists(atPath: melSpectrogramPath.path) {
                            if !localModels.contains(modelName) {
                                localModels.append(modelName)
                                modelManager.addLocalModel(modelName)
                                print("Found bundled model: \(modelName)")
                            }
                        }
                    }
                }
            } catch {
                print("Error scanning bundle for models: \(error.localizedDescription)")
            }
        }

        // Then check what's already downloaded
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelPath = documents.appendingPathComponent(modelStorage).path

            // Check if the directory exists
            if FileManager.default.fileExists(atPath: modelPath) {
                localModelPath = modelPath
                do {
                    let downloadedModels = try FileManager.default.contentsOfDirectory(atPath: modelPath)
                    for model in downloadedModels where !localModels.contains(model) {
                        localModels.append(model)
                        modelManager.addLocalModel(model)
                    }
                } catch {
                    print("Error enumerating files at \(modelPath): \(error.localizedDescription)")
                }
            }
        }

        localModels = ModelUtilities.formatModelFiles(localModels)
        modelManager.localModels = localModels

        print("Found locally: \(localModels)")
        print("Previously selected model: \(selectedModel) (\(selectedModelDisplayName))")
        print("ModelManager selectedModel: \(modelManager.selectedModel) (\(modelManager.selectedModelDisplayName))")

        Task {
            let remoteModelSupport = await WhisperKit.recommendedRemoteModels()
            await MainActor.run {
                for model in remoteModelSupport.disabled {
                    if !disabledModels.contains(model) {
                        disabledModels.append(model)
                    }
                }
            }
        }
    }

    func loadModel(_ model: String, redownload: Bool = false) {
        let modelDisplayName = WhisperModels.shared.getModel(by: model)?.displayName ?? model
        print("Selected Model: \(model) (\(modelDisplayName))")
        print("""
            Computing Options:
            - Mel Spectrogram:  \(getComputeOptions().melCompute.description)
            - Audio Encoder:    \(getComputeOptions().audioEncoderCompute.description)
            - Text Decoder:     \(getComputeOptions().textDecoderCompute.description)
            - Prefill Data:     \(getComputeOptions().prefillCompute.description)
        """)

        // WhisperModelManagerを使用してモデルをロード
        Task {
            await modelManager.loadModel(model, redownload: redownload)
        }
        
        // AppStorageとWhisperModelManagerのselectedModelを同期
        selectedModel = model
        modelManager.selectedModel = model
    }

    func deleteModel() {
        if localModels.contains(selectedModel) {
            let modelFolder = URL(fileURLWithPath: localModelPath).appendingPathComponent(selectedModel)

            do {
                try FileManager.default.removeItem(at: modelFolder)

                if let index = localModels.firstIndex(of: selectedModel) {
                    localModels.remove(at: index)
                    modelManager.removeLocalModel(selectedModel)
                }

                // WhisperModelManagerを通じて状態を更新
                Task {
                    await modelManager.deleteModel(selectedModel)
                }
            } catch {
                print("Error deleting model: \(error)")
            }
        }
    }

    // Progress bar updates are now handled by WhisperModelManager
    // This function is kept for compatibility but no longer needed
    func updateProgressBar(targetProgress: Float, maxTime: TimeInterval) async {
        // Progress is now managed by WhisperModelManager.optimizationProgress
        // No action needed here
    }

    func selectFile() {
        isFilePickerPresented = true
    }

    func handleFilePicker(result: Result<[URL], Error>) {
        switch result {
            case let .success(urls):
                guard let selectedFileURL = urls.first else { return }
                if selectedFileURL.startAccessingSecurityScopedResource() {
                    isFileLoading = true
                    fileLoadingProgress = 0.0
                    defer {
                        isFileLoading = false
                        fileLoadingProgress = 0.0
                    }
                    
                    // Check if the selected file is a video
                    if VideoAudioConverter.isVideoFile(url: selectedFileURL) {
                        // Convert video to audio
                        fileLoadingProgress = 0.2
                        VideoAudioConverter.convertVideoToAudio(videoURL: selectedFileURL) { result in
                            switch result {
                            case .success(let audioURL):
                                fileLoadingProgress = 1.0
                                tranCriptionFile(path: audioURL.path)
                            case .failure(let error):
                                print("Video conversion error: \(error.localizedDescription)")
                                currentText = "Failed to convert video to audio: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        // Handle audio files as before
                        do {
                            // Access the document data from the file URL
                            fileLoadingProgress = 0.3
                            let audioFileData = try Data(contentsOf: selectedFileURL)

                            // Create a unique file name to avoid overwriting any existing files
                            fileLoadingProgress = 0.6
                            let uniqueFileName = UUID().uuidString + "." + selectedFileURL.pathExtension

                            // Construct the temporary file URL in the app's temp directory
                            let tempDirectoryURL = FileManager.default.temporaryDirectory
                            let localFileURL = tempDirectoryURL.appendingPathComponent(uniqueFileName)

                            // Write the data to the temp directory
                            fileLoadingProgress = 0.8
                            try audioFileData.write(to: localFileURL)

                            print("File saved to temporary directory: \(localFileURL)")

                            fileLoadingProgress = 1.0
                            tranCriptionFile(path: selectedFileURL.path)
                        } catch {
                            print("File selection error: \(error.localizedDescription)")
                        }
                    }
                }
            case let .failure(error):
                print("File selection error: \(error.localizedDescription)")
        }
    }

    func tranCriptionFile(path: String) {
        resetState()
        whisperKit?.audioProcessor = AudioProcessor()
        tranCriptionTask = Task {
            isTranscribing = true
            do {
                try await tranCriptionCurrentFile(path: path)
            } catch {
                print("❌ File transcription error: \(error)")
                if let tranCriptionError = error as? TranCriptionError {
                    print("❌ TranCriptionError details: \(tranCriptionError)")
                    await MainActor.run {
                        switch tranCriptionError {
                        case .subscriptionLimitExceeded:
                            self.currentText = "Monthly usage limit exceeded. Please upgrade your subscription or wait for the next billing cycle."
                        case .insufficientCredits:
                            self.currentText = "Insufficient credits. Please purchase more credits to continue using API services."
                        case .modelAccessDenied:
                            self.currentText = "This model is not available in your current subscription plan. Please upgrade to access cloud models."
                        case .openAIServiceNotAvailable:
                            self.currentText = "OpenAI service is not available. Please check your API key in settings."
                        case .openAIAPIKeyNotSet:
                            self.currentText = "OpenAI API key is not set. Please configure your API key in settings."
                        case .fileTooLarge:
                            self.currentText = "Audio file is too large. Please use a file smaller than 25MB."
                        case .invalidAudioData:
                            self.currentText = "Invalid audio data format. Please check your audio file."
                        default:
                            self.currentText = "Transcription failed: \(tranCriptionError.localizedDescription)"
                        }
                    }
                } else {
                    print("❌ Unexpected error type: \(type(of: error))")
                    await MainActor.run {
                        self.currentText = "Transcription failed: \(error.localizedDescription)"
                    }
                }
            }
            isTranscribing = false
        }
    }

    func toggleRecording(shouldLoop: Bool) {
        isRecording.toggle()

        if isRecording {
            // 録音開始時はテキスト保持設定に従う
            resetState(preserveText: preserveTextOnRecording)
            startRecording(shouldLoop)
        } else {
            stopRecording(shouldLoop)
        }
    }

    func startRecording(_ loop: Bool) {
        guard let whisperKit = whisperKit else {
            currentText = String(localized: LocalizedStringResource("WhisperKit not initialized.", comment: "Error message when WhisperKit is not initialized"))
            return
        }
        
        guard modelState == .loaded else {
            currentText = String(localized: LocalizedStringResource("Model not loaded. Please wait for model to finish loading.", comment: "Error message when model is not loaded"))
            return
        }
        
        Task(priority: .userInitiated) {
            guard await AudioProcessor.requestRecordPermission() else {
                await MainActor.run {
                    currentText = String(localized: LocalizedStringResource("Microphone access denied.", comment: "Error message when microphone access is denied"))
                }
                print("Microphone access was not granted.")
                return
            }

            var deviceId: DeviceID?
            #if os(macOS)
            if selectedAudioInput != "No Audio Input",
               let devices = audioDevices,
               let device = devices.first(where: { $0.name == selectedAudioInput })
            {
                deviceId = device.id
            }

            // There is no built-in microphone
            if deviceId == nil {
                await MainActor.run {
                    currentText = String(localized: LocalizedStringResource("No audio input device selected.", comment: "Error message when no audio input device is selected"))
                }
                print("No audio input device available")
                return
            }
            #endif

            // OpenAI Realtimeモデルかどうかを判定
            let isRealtimeModel = selectedModel == "whisper-1" || 
                                 selectedModel == "gpt-4o-transcribe" || 
                                 selectedModel == "gpt-4o-mini-transcribe"
            
            do {
                // WhisperKitモデルの場合のみ録音を開始
                if !isRealtimeModel {
                    try whisperKit.audioProcessor.startRecordingLive(inputDeviceID: deviceId) { _ in
                        DispatchQueue.main.async {
                            bufferSeconds = Double(whisperKit.audioProcessor.audioSamples.count) / Double(WhisperKit.sampleRate)
                        }
                    }
                }

                // Delay the timer start by 1 second
                await MainActor.run {
                    isRecording = true
                    isTranscribing = true
                    currentText = String(localized: LocalizedStringResource("Recording started.", comment: "Status message when recording starts"))
                    
                    // STT中にアイコン非表示設定が有効な場合、UI要素を非表示にする
                    if hideIconsDuringSTT {
                        showUIElements = false
                    }
                    
                    // 波形アニメーションを開始
                    startWaveformAnimation()
                    
                    // 音声波形更新を開始
                    startWaveformUpdates()
                }
                
                if loop {
                    if isRealtimeModel {
                        do {
                            let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
                            let finalLanguage: String? = (languageCode == "auto") ? nil : languageCode
                            
                            print("🎤 Starting realtime transcription")
                            print("   - Model: \(selectedModel)")
                            print("   - Language: \(finalLanguage ?? "auto")")
                            print("   - Using OpenAI Realtime Transcription (Official API)")
                            
                            try await tranCriptionServiceManager.startRealtimeRecording(
                                language: finalLanguage,
                                delayInterval: Float(realtimeDelayInterval)
                            )
                            
                            // TranscriptionServiceManagerのrealtimeTextを監視
                            tranCriptionTask = Task {
                                let startTime = Date()
                                var lastText = ""
                                
                                while isRecording && isTranscribing {
                                    await MainActor.run {
                                        // TranscriptionServiceManagerからテキストを取得
                                        let realtimeText = tranCriptionServiceManager.realtimeText
                                        
                                        // テキストが変更された場合のみ更新
                                        if realtimeText != lastText {
                                            lastText = realtimeText
                                            print("🔄 Realtime text update: '\(realtimeText)'")
                                            
                                            if !realtimeText.isEmpty && !realtimeText.contains("Recording") && !realtimeText.contains("Listening") && !realtimeText.contains("Connecting") && !realtimeText.contains("Ready") {
                                                // セグメントとして追加（経過時間を使用）
                                                let elapsedTime = Date().timeIntervalSince(startTime)
                                                let segment = TranCriptionSegment(
                                                    start: 0,
                                                    end: elapsedTime,
                                                    text: realtimeText
                                                )
                                                
                                                // 既存のセグメントをクリアして新しいテキストを設定
                                                unconfirmedSegments = [segment]
                                                
                                                print("✅ Updated unconfirmed segments with: '\(realtimeText)'")
                                            } else if realtimeText.contains("Listening") || realtimeText.contains("Ready") {
                                                // "Listening..."または"Ready..."状態の場合は既存のテキストを保持
                                                print("👂 Waiting state - keeping existing text")
                                            }
                                        }
                                        
                                        // エラーがあれば表示
                                        if let error = tranCriptionServiceManager.error {
                                            currentText = "Error: \(error)"
                                            print("❌ Error from service manager: \(error)")
                                            // エラーが発生したら録音を停止
                                            isRecording = false
                                            isTranscribing = false
                                        }
                                    }
                                    
                                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
                                }
                            }
                        } catch {
                            await MainActor.run {
                                currentText = "Failed to start realtime transcription: \(error.localizedDescription)"
                                print("❌ Failed to start realtime: \(error)")
                            }
                        }
                    } else {
                        // WhisperKitモデルの場合は従来のrealtimeLoopを使用
                        realtimeLoop()
                    }
                }
            } catch {
                await MainActor.run {
                    currentText = String(localized: LocalizedStringResource("Failed to start recording.", comment: "Error message when recording fails to start"))
                }
                print("Failed to start recording: \(error)")
            }
        }
    }

    func stopRecording(_ loop: Bool) {
        isRecording = false
        
        // OpenAI Realtimeモデルの場合はTranscriptionServiceManagerを停止
        let isRealtimeModel = selectedModel == "whisper-1" || 
                             selectedModel == "gpt-4o-transcribe" || 
                             selectedModel == "gpt-4o-mini-transcribe"
        
        if isRealtimeModel {
            tranCriptionServiceManager.stopRealtimeRecording()
        } else {
            stopRealtimeTranCription()
            // WhisperKitの場合のみaudioProcessorを停止
            whisperKit?.audioProcessor.stopRecording()
        }
        
        // 波形アニメーションを停止
        stopWaveformAnimation()
        
        // 音声波形更新を停止
        stopWaveformUpdates()

        // 録音停止時のメッセージ（STTテキストがある場合は上書きしない）
        if currentText == String(localized: LocalizedStringResource("Recording started.", comment: "Status message when recording starts")) || currentText == "Waiting for speech..." {
            currentText = ""
        }

        // OpenAI Realtimeモデルの場合は最終処理をスキップ
        if !isRealtimeModel {
            // WhisperKitモデルの場合のみ最終的な転写処理を実行
            tranCriptionTask = Task {
                isTranscribing = true
                do {
                    // 残りのバッファを転写
                    try await transcribeCurrentBuffer()
                    
                    // テキストを最終化
                    await MainActor.run {
                        finalizeText()
                        
                        // 最終的なSTT処理時間を記録
                        if sttStartTime != nil && sttEndTime == nil {
                            sttEndTime = Date()
                            if let startTime = sttStartTime {
                                sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
                            }
                        }
                        
                        // 録音停止後のメッセージを更新（STTテキストがある場合は上書きしない）
                        let tranCriptionText = getTranCriptionText()
                        if tranCriptionText.isEmpty {
                            // STTテキストがない場合は何も表示しない
                            if currentText == "Recording stopped." || currentText == String(localized: LocalizedStringResource("Recording started.", comment: "Status message when recording starts")) || currentText == "Waiting for speech..." {
                                currentText = ""
                            }
                        } else {
                            // STTテキストがある場合は、メッセージを追加するか、既存テキストを保持
                            if currentText == "Recording stopped." || currentText == String(localized: LocalizedStringResource("Recording started.", comment: "Status message when recording starts")) || currentText == "Waiting for speech..." {
                                currentText = String(localized: LocalizedStringResource("Recording completed.", comment: "Status message when recording is completed"))
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        // エラー時もSTTテキストがある場合は保持
                        let tranCriptionText = getTranCriptionText()
                        if tranCriptionText.isEmpty {
                            currentText = String(localized: LocalizedStringResource("Error during final tranCription.", comment: "Error message when final tranCription fails"))
                        }
                        // STTテキストがある場合は、エラーメッセージを表示せずに既存テキストを保持
                    }
                    print("Error: \(error.localizedDescription)")
                }
                isTranscribing = false
            }
        } else {
            // OpenAI Realtimeモデルの場合は即座に終了
            isTranscribing = false
            
            // テキストを最終化
            finalizeText()
            
            // 最終的なSTT処理時間を記録
            if sttStartTime != nil && sttEndTime == nil {
                sttEndTime = Date()
                if let startTime = sttStartTime {
                    sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
                }
            }
        }
    }

    func finalizeText() {
        // Finalize unconfirmed text
        Task {
            await MainActor.run {
                if hypothesisText != "" {
                    confirmedText += hypothesisText
                    hypothesisText = ""
                }

                if !unconfirmedSegments.isEmpty {
                    confirmedSegments.append(contentsOf: unconfirmedSegments)
                    unconfirmedSegments = []
                }
                
                // 未確認のテキストも確定済みに追加
                if !currentText.isEmpty && !currentText.contains("Recording") && !currentText.contains("Waiting") {
                    let finalText = getTranCriptionText()
                    if !finalText.isEmpty {
                        // テキストが正常に取得できた場合、コピー可能状態にする
                        print("Final tranCription text: \(finalText)")
                        
                        // アナリティクスを更新
                        updateAnalyticsAfterTranCription(finalText: finalText)
                    }
                }
            }
        }
    }
    
    
    // MARK: - Analytics Update
    
    private func updateAnalyticsAfterTranCription(finalText: String) {
        // 転写時間を計算
        let duration: TimeInterval
        if let startTime = sttStartTime, let endTime = sttEndTime {
            duration = endTime.timeIntervalSince(startTime)
        } else {
            // フォールバック: テキストの長さから推定
            duration = Double(finalText.count) * 0.1 // 1文字あたり0.1秒と仮定
        }
        
        // 言語を取得（LanguageManagerのcurrentLanguageプロパティを使用）
        let language = languageManager.currentLanguage
        
        // モデル名を取得（WhisperModelManagerのselectedModelDisplayNameプロパティを使用）
        let modelName = modelManager.selectedModelDisplayName
        
        // アナリティクスを更新
        analyticsManager.recordTranCription(
            duration: duration,
            language: language,
            text: finalText,
            model: modelName
        )
        
        // バックグラウンドでトークン計算を実行（音声の長さとモデル情報を含む）
        Task {
            await TokenCalculationService.shared.calculateTokensForTranCription(
                finalText: finalText,
                duration: duration,
                model: modelName
            )
        }
        
        print("Analytics updated: duration=\(duration)s, language=\(language), model=\(modelName)")
    }
    

    // MARK: - TranCription Logic
    

    func tranCriptionCurrentFile(path: String) async throws {
        
        // OpenAIモデルの場合は元のファイルから直接データを読み込む
        if isOpenAIModel(selectedModel) {
            Logging.debug("Loading audio file for OpenAI: \(path)")
            let loadingStart = Date()
            
            let audioData: Data
            do {
                await MainActor.run {
                    fileLoadingProgress = 0.2
                }
                
                let fileURL = URL(fileURLWithPath: path)
                audioData = try Data(contentsOf: fileURL)
                
                await MainActor.run {
                    fileLoadingProgress = 0.5
                }
                Logging.debug("Loaded audio file in \(Date().timeIntervalSince(loadingStart)) seconds")
            } catch {
                Logging.error("Failed to load audio file: \(error.localizedDescription)")
                await MainActor.run {
                    currentText = String(localized: LocalizedStringResource("Failed to load audio file.", comment: "Error message when audio file loading fails"))
                }
                return
            }
            
            // STT処理開始時間を記録
            await MainActor.run {
                sttStartTime = Date()
            }
            
            let tranCription: TranCriptionResult?
            do {
                tranCription = try await tranCriptionAudioFile(audioData: audioData)
            } catch {
                throw error
            }
            
            await MainActor.run {
                currentText = ""
                
                guard let result = tranCription else {
                    return
                }

                // STT処理終了時間を記録
                sttEndTime = Date()
                if let startTime = sttStartTime {
                    sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
                }

                tokensPerSecond = 0
                effectiveRealTimeFactor = 0
                effectiveSpeedFactor = 0
                currentEncodingLoops = 0
                firstTokenTime = 0
                modelLoadingTime = 0
                pipelineStart = 0
                currentLag = 0

                // セグメントがある場合はセグメントから、ない場合はテキスト全体を使用
                if !result.segments.isEmpty {
                    confirmedSegments = result.segments.sorted { $0.start < $1.start }
                } else if !result.text.isEmpty {
                    // セグメントがない場合（gpt-4o-mini-transcribeなど）はテキスト全体を1つのセグメントとして扱う
                    confirmedSegments = [TranCriptionSegment(start: 0, end: result.duration, text: result.text)]
                }
                
                let finalText = confirmedSegments.map { $0.text }.joined(separator: " ")
                if !finalText.isEmpty {
                    updateAnalyticsAfterTranCription(finalText: finalText)
                }
            }
            return
        }
        
        // WhisperKitモデルの場合は従来の処理
        // Load audio file
        Logging.debug("Loading audio file: \(path)")
        let loadingStart = Date()
        
        let audioFileSamples: [Float]
        do {
            await MainActor.run {
                fileLoadingProgress = 0.2
            }
            audioFileSamples = try await Task {
                try autoreleasepool {
                    try AudioProcessor.loadAudioAsFloatArray(fromPath: path)
                }
            }.value
            await MainActor.run {
                fileLoadingProgress = 0.5
            }
            Logging.debug("Loaded audio file in \(Date().timeIntervalSince(loadingStart)) seconds")
        } catch {
            Logging.error("Failed to load audio file: \(error.localizedDescription)")
            await MainActor.run {
                currentText = String(localized: LocalizedStringResource("Failed to load audio file.", comment: "Error message when audio file loading fails"))
            }
            return
        }

        // STT処理開始時間を記録
        await MainActor.run {
            sttStartTime = Date()
        }

        // Resampling開始
        await MainActor.run {
            isResampling = true
            resamplingProgress = 0.0
        }

        let tranCription: TranCriptionResult?
        do {
            tranCription = try await tranCriptionAudioSamples(audioFileSamples)
        } catch {
            // Resampling終了（エラー時）
            await MainActor.run {
                isResampling = false
                resamplingProgress = 0.0
            }
            throw error
        }

        // Resampling終了
        await MainActor.run {
            isResampling = false
            resamplingProgress = 0.0
        }

        await MainActor.run {
            currentText = ""
            
            guard let result = tranCription else {
                return
            }

            // STT処理終了時間を記録
            sttEndTime = Date()
            if let startTime = sttStartTime {
                sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
            }

            // WhisperKit TranCriptionResult may not have timings property
            tokensPerSecond = 0
            effectiveRealTimeFactor = 0
            effectiveSpeedFactor = 0
            currentEncodingLoops = 0
            firstTokenTime = 0
            modelLoadingTime = 0
            pipelineStart = 0
            currentLag = 0

            // セグメントがある場合はセグメントから、ない場合はテキスト全体を使用
            if !result.segments.isEmpty {
                // セグメントをタイムスタンプ順にソートしてから設定
                confirmedSegments = result.segments.sorted { $0.start < $1.start }
            } else if !result.text.isEmpty {
                // セグメントがない場合（gpt-4o-mini-transcribeなど）はテキスト全体を1つのセグメントとして扱う
                confirmedSegments = [TranCriptionSegment(start: 0, end: result.duration, text: result.text)]
            }
            
            // ファイル転写完了時にアナリティクスを更新
            let finalText = confirmedSegments.map { $0.text }.joined(separator: " ")
            if !finalText.isEmpty {
                updateAnalyticsAfterTranCription(finalText: finalText)
            }
        }
    }

    func tranCriptionAudioFile(audioData: Data) async throws -> TranCriptionResult? {
        print("🔵 ContentView: tranCriptionAudioFile called")
        print("   - Model: \(selectedModel)")
        print("   - Task: \(selectedTask)")
        print("   - Is OpenAI Model: \(isOpenAIModel(selectedModel))")
        
        // selectedLanguageから言語コードを取得
        // selectedLanguageは言語名（"japanese"）または言語コード（"ja", "auto"）の可能性がある
        var languageCode: String? = nil
        
        // "auto"の場合はnilにして自動検出を有効化
        if selectedLanguage == "auto" {
            languageCode = nil
            print("🔵 ContentView: Language settings - AUTO MODE")
            print("   - selectedLanguage: 'auto'")
            print("   - languageCode: nil (will use OpenAI auto-detect)")
        } else {
            // Constants.languagesで変換を試みる
            if let mappedCode = Constants.languages[selectedLanguage] {
                languageCode = mappedCode
                print("🔵 ContentView: Language settings - EXPLICIT MODE")
                print("   - selectedLanguage: '\(selectedLanguage)'")
                print("   - languageCode: '\(mappedCode)'")
            } else {
                // マッピングが見つからない場合は、selectedLanguage自体が言語コードの可能性がある
                languageCode = selectedLanguage
                print("⚠️ ContentView: Language settings - FALLBACK MODE")
                print("   - selectedLanguage: '\(selectedLanguage)' (not found in mapping)")
                print("   - languageCode: '\(selectedLanguage)' (using as-is)")
            }
        }
        
        // selectedTaskに応じてtranscriptionAudioまたはtranslateAudioを呼び出す
        if selectedTask == "translate" {
            print("✅ TRANSLATE MODE: Will call translateAudio with target language: \(translateTargetLanguage)")
            return try await tranCriptionServiceManager.translateAudio(audioData: audioData, targetLanguage: translateTargetLanguage)
        } else {
            print("✅ TRANSCRIBE MODE: Will call transcriptionAudio with language: \(languageCode ?? "nil")")
            if !customPrompt.isEmpty {
                print("   - Custom prompt: '\(customPrompt)'")
            }
            return try await tranCriptionServiceManager.transcriptionAudio(
                audioData: audioData,
                language: languageCode,
                customPrompt: customPrompt.isEmpty ? nil : customPrompt
            )
        }
    }

    func tranCriptionAudioSamples(_ samples: [Float], isStreaming: Bool = false) async throws -> TranCriptionResult? {
        // OpenAIモデルの場合は使用しない（エラーログ追加）
        if isOpenAIModel(selectedModel) {
            print("❌ Error: tranCriptionAudioSamples should not be called for OpenAI models")
            throw TranCriptionError.invalidModel
        }
        
        // WhisperKitモデルの場合は従来の処理
        guard let whisperKit = whisperKit else { return nil }

        // Reference-ContentView.swiftと同じシンプルなアプローチ
        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        
        // selectedTaskが古い値の場合は強制的に修正
        var currentTask = selectedTask
        if currentTask == "tranCription" {
            currentTask = "transcribe"
            selectedTask = "transcribe"
            UserDefaults.standard.set("transcribe", forKey: "selectedTask")
            print("⚠️ FIXED: selectedTask was 'tranCription', changed to 'transcribe'")
        }
        
        let task: DecodingTask = currentTask == "transcribe" ? .transcribe : .translate
        
        // デバッグログ
        print("🔧 WHISPERKIT DEBUG:")
        print("  selectedLanguage: '\(selectedLanguage)'")
        print("  languageCode: '\(languageCode)'")
        print("  currentTask: '\(currentTask)'")
        print("  selectedTask: '\(selectedTask)'")
        print("  UserDefaults selectedTask: '\(UserDefaults.standard.string(forKey: "selectedTask") ?? "nil")'")
        print("  task: \(task)")
        print("  isStreaming: \(isStreaming)")
        print("  task == .transcribe: \(task == .transcribe)")
        print("  task == .translate: \(task == .translate)")
        
        // ストリーミング時はlastConfirmedSegmentEndSecondsを使用、ファイル転写時は0からスタート
        let seekClip: [Float] = isStreaming ? [lastConfirmedSegmentEndSeconds] : [0]
        
        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: enablePromptPrefill,
            usePrefillCache: enableCachePrefill,
            skipSpecialTokens: !enableSpecialCharacters,
            withoutTimestamps: !enableTimestamps,
            wordTimestamps: true,
            clipTimestamps: seekClip,
            concurrentWorkerCount: Int(concurrentWorkerCount),
            chunkingStrategy: chunkingStrategy
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { (progress: TranscriptionProgress) in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                let chunkId = isStreamMode ? 0 : progress.windowId

                // First check if this is a new window for the same chunk, append if so
                var updatedChunk = (chunkText: [progress.text], fallbacks: fallbacks)
                if var currentChunk = currentChunks[chunkId], let previousChunkText = currentChunk.chunkText.last {
                    if progress.text.count >= previousChunkText.count {
                        // This is the same window of an existing chunk, so we just update the last value
                        currentChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                        updatedChunk = currentChunk
                    } else {
                        // This is either a new window or a fallback (only in streaming mode)
                        if fallbacks == currentChunk.fallbacks && isStreamMode {
                            // New window (since fallbacks havent changed)
                            updatedChunk.chunkText = [updatedChunk.chunkText.first ?? "" + progress.text]
                        } else {
                            // Fallback, overwrite the previous bad text
                            updatedChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                            updatedChunk.fallbacks = fallbacks
                            print("Fallback occured: \(fallbacks)")
                        }
                    }
                }

                // Set the new text for the chunk
                currentChunks[chunkId] = updatedChunk
                let joinedChunks = currentChunks.sorted { $0.key < $1.key }.flatMap { $0.value.chunkText }.joined(separator: "\n")

                currentText = joinedChunks
                currentFallbacks = fallbacks
                currentDecodingLoops += 1
            }

            // Check early stopping - より緩い設定で完全な転写を確保
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = TextUtilities.compressionRatio(of: checkTokens)
                // より緩い閾値で早期停止を防ぐ（デフォルト: 2.4 → 3.0）
                if compressionRatio > 3.0 {
                    Logging.debug("Early stopping due to compression threshold: \(compressionRatio)")
                    return false
                }
            }
            // より緩いlogprob閾値で早期停止を防ぐ（デフォルト: -1.0 → -1.5）
            if progress.avgLogprob! < -1.5 {
                Logging.debug("Early stopping due to logprob threshold: \(progress.avgLogprob!)")
                return false
            }
            return nil
        }

        let segmentCallback: SegmentDiscoveryCallback = { segments in
            // Log segments as they are discovered from the segment discovery callback
            for segment in segments {
                Logging.debug("Discovered segment: \(segment.id) (\(segment.seek))): \(segment.start) -> \(segment.end) \(segment.text)")
            }
        }

        whisperKit.segmentDiscoveryCallback = segmentCallback

        // Resampling progress update
        await MainActor.run {
            resamplingProgress = 0.3
        }

        let whisperKitResults = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )

        // Resampling progress completion
        await MainActor.run {
            resamplingProgress = 1.0
        }

        // WhisperKitのmergeTranscriptionResultsを使用（Reference-ContentView.swiftと同じ方法）
        let mergedResults = TranscriptionUtilities.mergeTranscriptionResults(whisperKitResults)
        
        LogDebug("Merged \(whisperKitResults.count) results", category: .stt)
        if let firstSegment = mergedResults.segments.first {
            LogDebug("First segment timing: \(firstSegment.start) -> \(firstSegment.end)", category: .stt)
        }
        if let lastSegment = mergedResults.segments.last {
            LogDebug("Last segment timing: \(lastSegment.start) -> \(lastSegment.end)", category: .stt)
        }

        // Convert WhisperKit TranscriptionResult to local TranCriptionResult
        return TranCriptionResult(
            text: mergedResults.text,
            segments: mergedResults.segments.map { segment in
                TranCriptionSegment(
                    start: Double(segment.start),
                    end: Double(segment.end),
                    text: segment.text
                )
            },
            language: mergedResults.language,
            duration: Double(mergedResults.segments.last?.end ?? 0.0)
        )
    }

    // MARK: Streaming Logic

    func realtimeLoop() {
        tranCriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await transcribeCurrentBuffer(delayInterval: Float(realtimeDelayInterval))
                } catch {
                    print("Error: \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    func stopRealtimeTranCription() {
        isTranscribing = false
        tranCriptionTask?.cancel()
    }

    func transcribeCurrentBuffer(delayInterval: Float = 1.0) async throws {
        // OpenAIモデルの場合は使用しない
        if isOpenAIModel(selectedModel) {
            print("❌ Error: transcribeCurrentBuffer should not be called for OpenAI models")
            return
        }
        
        guard let whisperKit = whisperKit else { return }

        // Retrieve the current audio buffer from the audio processor
        let currentBuffer = whisperKit.audioProcessor.audioSamples

        // Calculate the size and duration of the next buffer segment
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)

        // Only run the transcribe if the next buffer has at least `delayInterval` seconds of audio
        guard nextBufferSeconds > delayInterval else {
            await MainActor.run {
                if currentText == "" {
                    currentText = "Waiting for speech..."
                }
            }
            try await Task.sleep(nanoseconds: 100_000_000) // sleep for 100ms for next buffer
            return
        }

        if useVAD {
            let voiceDetected = AudioProcessor.isVoiceDetected(
                in: whisperKit.audioProcessor.relativeEnergy,
                nextBufferInSeconds: nextBufferSeconds,
                silenceThreshold: Float(silenceThreshold)
            )
            // Only run the transcribe if the next buffer has voice
            guard voiceDetected else {
                await MainActor.run {
                    if currentText == "" {
                        currentText = "Waiting for speech..."
                    }
                }

                // TODO: Implement silence buffer purging
//                if nextBufferSeconds > 30 {
//                    // This is a completely silent segment of 30s, so we can purge the audio and confirm anything pending
//                    lastConfirmedSegmentEndSeconds = 0
//                    whisperKit.audioProcessor.purgeAudioSamples(keepingLast: 2 * WhisperKit.sampleRate) // keep last 2s to include VAD overlap
//                    currentBuffer = whisperKit.audioProcessor.audioSamples
//                    lastBufferSize = 0
//                    confirmedSegments.append(contentsOf: unconfirmedSegments)
//                    unconfirmedSegments = []
//                }

                // Sleep for 100ms and check the next buffer
                try await Task.sleep(nanoseconds: 100_000_000)
                return
            }
        }

        // Store this for next iterations VAD
        lastBufferSize = currentBuffer.count

        if enableEagerDecoding && isStreamMode {
            // Run realtime transcribe using word timestamps for segmentation
            let transcription = try await transcribeEagerMode(Array(currentBuffer))
            await MainActor.run {
                currentText = ""
                tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
                firstTokenTime = transcription?.timings.firstTokenTime ?? 0
                modelLoadingTime = transcription?.timings.modelLoading ?? 0
                pipelineStart = transcription?.timings.pipelineStart ?? 0
                currentLag = transcription?.timings.decodingLoop ?? 0
                currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)

                let totalAudio = Double(currentBuffer.count) / Double(WhisperKit.sampleRate)
                totalInferenceTime = transcription?.timings.fullPipeline ?? 0
                effectiveRealTimeFactor = Double(totalInferenceTime) / totalAudio
                effectiveSpeedFactor = totalAudio / Double(totalInferenceTime)
            }
        } else {
            // Run realtime transcribe using timestamp tokens directly
            let transcription = try await tranCriptionAudioSamples(Array(currentBuffer), isStreaming: true)

            // We need to run this next part on the main thread
            await MainActor.run {
                currentText = ""
                guard let segments = transcription?.segments else {
                    return
                }

                // TranCriptionResult may not have timings property
                tokensPerSecond = 0
                firstTokenTime = 0
                modelLoadingTime = 0
                pipelineStart = 0
                currentLag = 0
                currentEncodingLoops += 0

                let totalAudio = Double(currentBuffer.count) / Double(WhisperKit.sampleRate)
                totalInferenceTime += 0
                effectiveRealTimeFactor = Double(totalInferenceTime) / totalAudio
                effectiveSpeedFactor = totalAudio / Double(totalInferenceTime)

                // Logic for moving segments to confirmedSegments
                if segments.count > requiredSegmentsForConfirmation {
                    // Calculate the number of segments to confirm
                    let numberOfSegmentsToConfirm = segments.count - requiredSegmentsForConfirmation

                    // Confirm the required number of segments
                    let confirmedSegmentsArray = Array(segments.prefix(numberOfSegmentsToConfirm))
                    let remainingSegments = Array(segments.suffix(requiredSegmentsForConfirmation))

                    // Update lastConfirmedSegmentEnd based on the last confirmed segment
                    if let lastConfirmedSegment = confirmedSegmentsArray.last, lastConfirmedSegment.end > Double(lastConfirmedSegmentEndSeconds) {
                        lastConfirmedSegmentEndSeconds = Float(lastConfirmedSegment.end)
                        print("Last confirmed segment end: \(lastConfirmedSegmentEndSeconds)")

                        // Add confirmed segments to the confirmedSegments array
                        for segment in confirmedSegmentsArray {
                            if !confirmedSegments.contains(where: { $0.start == segment.start && $0.end == segment.end && $0.text == segment.text }) {
                                confirmedSegments.append(segment)
                            }
                        }
                    }

                    // Update transcriptions to reflect the remaining segments
                    unconfirmedSegments = remainingSegments
                } else {
                    // Handle the case where segments are fewer or equal to required
                    unconfirmedSegments = segments
                }
            }
        }
    }

    func transcribeEagerMode(_ samples: [Float]) async throws -> TranscriptionResult? {
        // OpenAIモデルの場合は使用しない
        if isOpenAIModel(selectedModel) {
            print("❌ Error: transcribeEagerMode should not be called for OpenAI models")
            return nil
        }
        
        guard let whisperKit = whisperKit else { return nil }

        guard whisperKit.textDecoder.supportsWordTimestamps else {
            confirmedText = "Eager mode requires word timestamps, which are not supported by the current model: \(selectedModel)."
            return nil
        }

        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = selectedTask == "transcribe" ? .transcribe : .translate
        print(selectedLanguage)
        print(languageCode)

        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: enablePromptPrefill,
            usePrefillCache: enableCachePrefill,
            skipSpecialTokens: !enableSpecialCharacters,
            withoutTimestamps: !enableTimestamps,
            wordTimestamps: true, // required for eager mode
            firstTokenLogProbThreshold: -1.5, // higher threshold to prevent fallbacks from running to often
            chunkingStrategy: ChunkingStrategy.none
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { progress in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                if progress.text.count < currentText.count {
                    if fallbacks == currentFallbacks {
                        //                        self.unconfirmedText.append(currentText)
                    } else {
                        print("Fallback occured: \(fallbacks)")
                    }
                }
                currentText = progress.text
                currentFallbacks = fallbacks
                currentDecodingLoops += 1
            }
            // Check early stopping - より緩い設定で完全な転写を確保
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = TextUtilities.compressionRatio(of: checkTokens)
                // より緩い閾値で早期停止を防ぐ（デフォルト: 2.4 → 3.0）
                if compressionRatio > 3.0 {
                    Logging.debug("Early stopping due to compression threshold: \(compressionRatio)")
                    return false
                }
            }
            // より緩いlogprob閾値で早期停止を防ぐ（デフォルト: -1.0 → -1.5）
            if progress.avgLogprob! < -1.5 {
                Logging.debug("Early stopping due to logprob threshold: \(progress.avgLogprob!)")
                return false
            }

            return nil
        }

        Logging.info("[EagerMode] \(lastAgreedSeconds)-\(Double(samples.count) / 16000.0) seconds")

        let segmentCallback: SegmentDiscoveryCallback = { segments in
            // Log segments as they are discovered from the segment discovery callback
            for segment in segments {
                Logging.debug("Discovered segment: \(segment.id) (\(segment.seek))): \(segment.start) -> \(segment.end)")
            }
        }

        whisperKit.segmentDiscoveryCallback = segmentCallback

        let streamingAudio = samples
        var streamOptions = options
        streamOptions.clipTimestamps = [lastAgreedSeconds]
        let lastAgreedTokens = lastAgreedWords.flatMap { $0.tokens }
        streamOptions.prefixTokens = []
        do {
            let transcription: TranscriptionResult? = try await whisperKit.transcribe(audioArray: streamingAudio, decodeOptions: streamOptions, callback: decodingCallback).first
            await MainActor.run {
                var skipAppend = false
                if let result = transcription {
                    hypothesisWords = result.allWords.filter { $0.start >= lastAgreedSeconds }.map { word in
                        WordTiming(
                            word: word.word,
                            start: Double(word.start),
                            end: Double(word.end),
                            tokens: word.tokens.map { String($0) }
                        )
                    }

                    if let prevResult = prevResult {
                        // prevResult may not have allWords property
                        prevWords = []
                        let commonPrefix = findCommonPrefix(prevWords, hypothesisWords)
                        Logging.info("[EagerMode] Prev \"\((prevWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Next \"\((hypothesisWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Found common prefix \"\((commonPrefix.map { $0.word }).joined())\"")

                        if commonPrefix.count >= Int(tokenConfirmationsNeeded) {
                            lastAgreedWords = commonPrefix.suffix(Int(tokenConfirmationsNeeded))
                            lastAgreedSeconds = Float(lastAgreedWords.first!.start)
                            Logging.info("[EagerMode] Found new last agreed word \"\(lastAgreedWords.first!.word)\" at \(lastAgreedSeconds) seconds")

                            confirmedWords.append(contentsOf: commonPrefix.prefix(commonPrefix.count - Int(tokenConfirmationsNeeded)))
                            let currentWords = confirmedWords.map { $0.word }.joined()
                            Logging.info("[EagerMode] Current:  \(lastAgreedSeconds) -> \(Double(samples.count) / 16000.0) \(currentWords)")
                        } else {
                            Logging.info("[EagerMode] Using same last agreed time \(lastAgreedSeconds)")
                            skipAppend = true
                        }
                    }
                    prevResult = CriptionTranCriptionResult(
                        text: result.text,
                        segments: result.segments.map { segment in
                            TranCriptionSegment(
                                start: Double(segment.start),
                                end: Double(segment.end),
                                text: segment.text
                            )
                        },
                        language: result.language,
                        duration: 0.0,
                        timings: TranCriptionTimings(),
                        allWords: []
                    )
                }

                if !skipAppend {
                    let criptionResult = transcription.map { result in
                        CriptionTranCriptionResult(
                            text: result.text,
                            segments: result.segments.map { segment in
                                TranCriptionSegment(
                                    start: Double(segment.start),
                                    end: Double(segment.end),
                                    text: segment.text
                                )
                            },
                            language: result.language,
                            duration: 0.0,
                            timings: TranCriptionTimings(),
                            allWords: []
                        )
                    }
                    eagerResults.append(criptionResult)
                }
            }

            await MainActor.run {
                let finalWords = confirmedWords.map { $0.word }.joined()
                confirmedText = finalWords

                // Accept the final hypothesis because it is the last of the available audio
                let lastHypothesis = lastAgreedWords + findDifferentSuffix(prevWords, hypothesisWords)
                hypothesisText = lastHypothesis.map { $0.word }.joined()
            }
        } catch {
            Logging.error("[EagerMode] Error: \(error)")
            finalizeText()
        }

        // TranscriptionUtilities.mergeTranscriptionResults may not be available
        // Return a simple result for now
        let mergedResult = TranscriptionResult(
            text: confirmedText + hypothesisText,
            segments: [],
            language: "unknown",
            timings: TranscriptionTimings()
        )

        return mergedResult
    }
    
    // MARK: - Helper Functions for Word Processing
    
    private func findCommonPrefix(_ words1: [WordTiming], _ words2: [WordTiming]) -> [WordTiming] {
        var commonPrefix: [WordTiming] = []
        let minCount = min(words1.count, words2.count)
        
        for i in 0..<minCount {
            if words1[i].word == words2[i].word {
                commonPrefix.append(words1[i])
            } else {
                break
            }
        }
        
        return commonPrefix
    }
    
    private func findDifferentSuffix(_ words1: [WordTiming], _ words2: [WordTiming]) -> [WordTiming] {
        let commonPrefix = findCommonPrefix(words1, words2)
        let remainingWords = Array(words2.dropFirst(commonPrefix.count))
        return remainingWords
    }
    
    /// STTテキストをクリア
    func clearSTTText() {
        currentText = ""
        stableDecoderText = ""
        decoderUpdateTimer?.invalidate()
        decoderUpdateTimer = nil
        currentChunks = [:]
        confirmedSegments = []
        unconfirmedSegments = []
        processedSegmentTimestamps = []
        confirmedWords = []
        confirmedText = ""
        hypothesisWords = []
        hypothesisText = ""
        eagerResults = []
        prevResult = nil
        lastAgreedSeconds = 0.0
        prevWords = []
        lastAgreedWords = []
        
        // 統計情報もリセット
        pipelineStart = Double.greatestFiniteMagnitude
        firstTokenTime = Double.greatestFiniteMagnitude
        effectiveRealTimeFactor = 0
        effectiveSpeedFactor = 0
        totalInferenceTime = 0
        tokensPerSecond = 0
        currentLag = 0
        currentFallbacks = 0
        currentEncodingLoops = 0
        currentDecodingLoops = 0
        lastBufferSize = 0
        lastConfirmedSegmentEndSeconds = 0
        requiredSegmentsForConfirmation = 2
        bufferSeconds = 0
        
        // STT時間計測をリセット
        sttStartTime = nil
        sttEndTime = nil
        sttProcessingTime = 0
    }
    
    /// プルトゥリフレッシュによるテキストクリア
    func refreshContent() async {
        clearSTTText()
    }
    
    // MARK: - Audio Waveform Functions
    
    private func startWaveformUpdates() {
        waveformUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateAudioSamples()
        }
    }
    
    private func stopWaveformUpdates() {
        waveformUpdateTimer?.invalidate()
        waveformUpdateTimer = nil
        audioSamples = []
    }
    
    private func updateAudioSamples() {
        // OpenAIモデルの場合は専用のサービスから音声サンプルを取得
        if isOpenAIModel(selectedModel) {
            // OpenAI Streaming Transcription Serviceから音声サンプルを取得
            if let streamingService = tranCriptionServiceManager.openAIStreamingService {
                audioSamples = streamingService.audioSamples
            }
            // OpenAI Realtime Transcription Serviceから音声サンプルを取得
            else if let realtimeService = tranCriptionServiceManager.openAIRealtimeService {
                audioSamples = realtimeService.audioSamples
            }
            return
        }
        
        guard let whisperKit = whisperKit else { return }
        
        let samples = whisperKit.audioProcessor.audioSamples
        // 最新のサンプルを取得（最大1000サンプル）
        let maxSamples = min(1000, samples.count)
        let recentSamples = Array(samples.suffix(maxSamples))
        
        DispatchQueue.main.async {
            self.audioSamples = recentSamples
        }
    }
}



// MARK: - ChatInputBoxView
struct ChatInputBoxView: View {
    @Binding var isRecording: Bool
    @Binding var isTranscribing: Bool
    @Binding var selectedTask: String
    @Binding var showUIElements: Bool
    @Binding var hideIconsDuringSTT: Bool
    @Binding var isFilePickerPresented: Bool
    @Binding var selectedModel: String
    @Binding var customPrompt: String
    @Binding var showPromptInput: Bool
    
    @EnvironmentObject var modelManager: WhisperModelManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var transcriptionServiceManager: TranCriptionServiceManager
    
    let onFileSelect: () -> Void
    let onToggleRecording: () -> Void
    let onTaskToggle: () -> Void
    let onFilePickerResult: (Result<[URL], Error>) -> Void
    
    @State private var showQuickResponseMenu = false
    
    // 利用可能なモデルのオプション（ローカル + API）
    private var availableModels: [String] {
        var models: [String] = []
        
        // ローカルモデル（バンドル済みまたはダウンロード済み）
        models.append(contentsOf: modelManager.localModels)
        
        // クラウドモデル（APIキーが設定されているもののみ）
        
        // OpenAIモデル（APIキーが設定されている場合）
        if transcriptionServiceManager.hasValidAPIKey() {
            models.append("whisper-1")
            models.append("gpt-4o-transcribe")
            models.append("gpt-4o-mini-transcribe")
        }
        
        // Fireworksモデル（APIキーが設定されている場合）
        if transcriptionServiceManager.hasValidFireworksAPIKey() {
            models.append("fireworks-asr-large")
            models.append("fireworks-asr-v2")
            models.append("whisper-v3")
            models.append("whisper-v3-turbo")
        }
        
        return models
    }
    
    // 選択されたモデルの表示名を取得
    private var selectedModelDisplayName: String {
        if let model = WhisperModels.shared.getModel(by: selectedModel) {
            return model.displayName
        }
        return selectedModel.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
    // OpenAIモデルかどうかを判定
    private var isOpenAIModel: Bool {
        selectedModel == "whisper-1" || selectedModel == "gpt-4o-transcribe" || selectedModel == "gpt-4o-mini-transcribe"
    }
    
    // Fireworksモデルかどうかを判定
    private var isFireworksModel: Bool {
        selectedModel == "fireworks-asr-large" ||
        selectedModel == "fireworks-asr-v2"
    }
    
    private var isWhisperV3Model: Bool {
        selectedModel == "whisper-v3-turbo"
    }
    
    private var isWhisperV3ServerlessModel: Bool {
        selectedModel == "whisper-v3-turbo"
    }
    
    var body: some View {
        mainInputAreaView
    }
    
    private var mainInputAreaView: some View {
        VStack(spacing: 0) {
            // プロンプト入力フィールド（OpenAIモデルの場合のみ表示）
            if isOpenAIModel && showPromptInput {
                PromptInputView(
                    customPrompt: $customPrompt,
                    showPromptInput: $showPromptInput
                )
            }
            
            // メインの入力エリア
            mainInputHStack
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var mainInputHStack: some View {
        HStack(spacing: 12) {
                // ファイル選択ボタン（プラスアイコン）
                Button(action: onFileSelect) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(.quaternary, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .liquidGlassButton()
                .fileImporter(
                    isPresented: $isFilePickerPresented,
                    allowedContentTypes: [.audio, .movie],
                    allowsMultipleSelection: false,
                    onCompletion: onFilePickerResult
                )
                
                // モデル選択ボタン
                Button(action: {
showQuickResponseMenu.toggle()
                }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            // モデルタイプのアイコン
                            if isOpenAIModel {
                                OpenAIIconView(isDarkMode: false)
                                    .frame(width: 18, height: 18)
                            } else {
                                Image("cription-icon-black")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(getModelTypeDisplayName())
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(getModelShortName())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isOpenAIModel ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showQuickResponseMenu) {
                    ModelSelectionSheetView(
                        selectedModel: $selectedModel,
                        availableModels: availableModels,
                        onModelSelected: { model in
                            selectModel(model)
                            showQuickResponseMenu = false
                        },
                        onDismiss: {
                            showQuickResponseMenu = false
                        }
                    )
                    .environmentObject(themeManager)
                }
                
                // プロンプト入力切り替えボタン（OpenAIモデルの場合のみ表示）
                if isOpenAIModel {
                    Button(action: {
                        withAnimation {
                            showPromptInput.toggle()
                        }
                    }) {
                        Image(systemName: showPromptInput ? "text.bubble.fill" : "text.bubble")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(.quaternary, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // 録音ボタン（マイクアイコン）
                Button(action: onToggleRecording) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isRecording ? .white : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isRecording ? Color.red : Color.gray.opacity(0.2))
                                .overlay(
                                    Circle()
                                        .stroke(isRecording ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .liquidGlassButton()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
    
    private func selectModel(_ model: String) {
        // モデル選択のロジック
        selectedModel = model
        modelManager.selectedModel = model
        
        // モデルをロード
        Task {
            await modelManager.loadModel(model, redownload: false)
        }
    }
    
    // MARK: - Model Display Helpers
    
    private func getModelTypeDisplayName() -> String {
        if isOpenAIModel {
            return "OpenAI"
        } else {
            return "Local"
        }
    }
    
    private func getModelShortName() -> String {
        if selectedModel.contains("gpt-4o-mini") {
            return "GPT-4o Mini"
        } else if selectedModel.contains("gpt-4o") {
            return "GPT-4o"
        } else if selectedModel.contains("whisper-1") {
            return "Whisper-1"
        } else {
            return selectedModelDisplayName
        }
    }
    
    private func getModelFeature() -> String {
        if selectedModel.contains("gpt-4o-mini") {
            return "Fast & Cost-effective"
        } else if selectedModel.contains("gpt-4o") {
            return "High Accuracy"
        } else if selectedModel.contains("whisper-1") {
            return "Standard Quality"
        } else {
            return "Local Processing"
        }
    }
    
    private func getModelIcon(for model: String) -> String {
        if model.contains("gpt-4o") {
            // OpenAIモデルの場合はテーマに応じてSVGアイコンを使用
            return "openai-icon"
        } else if model.contains("fireworks") {
            // Fireworksモデルの場合はFireworksアイコンを使用
            return "fireworks-icon"
        } else if model.contains("parakeet") {
            // Parakeetモデルの場合はCriptionアイコンを使用
            return "cription-icon-black"
        } else {
            // ローカルモデルの場合はCriptionアイコンを使用
            return "cription-icon-black"
        }
    }
    
    private func getModelColor(for model: String) -> Color {
        return .primary
    }
    
    private func getModelDisplayName(for model: String) -> String {
        if let whisperModel = WhisperModels.shared.getModel(by: model) {
            return whisperModel.displayName
        }
        
        // フォールバック: モデル名を整形
        let cleanName = model.replacingOccurrences(of: "whisper-", with: "")
        return cleanName.capitalized
    }
    
    private func getModelDeCription(for model: String) -> String {
        if model.contains("parakeet-tdt-0.6b-v3") {
            return "High-performance multilingual ASR - 25 European languages"
        } else if model.contains("parakeet-tdt-0.6b-v2") {
            return "High-performance English ASR - Optimized for speed"
        } else if model.contains("mini") {
            return "Fastest, smallest model"
        } else if model.contains("base") {
            return "Good balance of speed and accuracy"
        } else if model.contains("small") {
            return "Better accuracy, moderate speed"
        } else if model.contains("medium") {
            return "High accuracy, slower processing"
        } else if model.contains("large") {
            return "Highest accuracy, slowest processing"
        } else {
            return "Custom model"
        }
    }
    
    private func isModelRecommended(_ model: String) -> Bool {
        // 推奨モデルにタグを表示
        return model.contains("large") || model.contains("medium")
    }
}

// MARK: - ModelSelectionSheetView
struct ModelSelectionSheetView: View {
    @Binding var selectedModel: String
    let availableModels: [String]
    let onModelSelected: (String) -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("Select a Model")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGray))
                
                // モデルリスト
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(availableModels, id: \.self) { model in
                            Button(action: {
                                onModelSelected(model)
                            }) {
                                HStack(spacing: 16) {
                                    // モデルアイコン
                                    if model.contains("gpt-4o") || model == "whisper-1" || model.contains("whisper-v3") {
                                        OpenAIIconView(isDarkMode: themeManager.isDarkMode)
                                            .frame(width: 32, height: 32)
                                    } else if model.contains("fireworks") {
                                        Image("fireworks-icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                    } else if model.contains("parakeet") {
                                        Image("cription-icon-black")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                    } else {
                                        Image(getModelIcon(for: model))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(getModelDisplayName(for: model))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            if isModelRecommended(model) {
                                                Text("Recommended")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color(hex: "1CA485"))
                                                    .cornerRadius(10)
                                            }
                                            
                                            Spacer()
                                            
                                            if model == selectedModel {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        
                                        Text(getModelDeCription(for: model))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    model == selectedModel ? 
                                    Color.blue.opacity(0.1) : 
                                    Color.clear
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if model != availableModels.last {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
                #if os(iOS)
                .background(Color(.systemBackground))
                #elseif os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #endif
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Helper Functions
    
    private func getModelIcon(for model: String) -> String {
        if model.contains("gpt-4o") || model == "whisper-v3-turbo" {
            return "cloud"
        } else if model.contains("fireworks") {
            return "fireworks-icon"
        } else if model.contains("parakeet") {
            return "cription-icon-black"
        } else {
            // ローカルモデルの場合はCriptionアイコンを使用
            return "cription-icon-black"
        }
    }
    
    private func getModelDisplayName(for model: String) -> String {
        if let whisperModel = WhisperModels.shared.getModel(by: model) {
            return whisperModel.displayName
        }
        
        // フォールバック: モデル名を整形
        let cleanName = model.replacingOccurrences(of: "whisper-", with: "")
        return cleanName.capitalized
    }
    
    private func getModelDeCription(for model: String) -> String {
        if model == "whisper-1" {
            return "OpenAI Whisper API - Standard tranCription"
        } else if model.contains("gpt-4o-transcribe") {
            return "Advanced AI tranCription with GPT-4o"
        } else if model.contains("gpt-4o-mini-transcribe") {
            return "Fast AI tranCription with GPT-4o Mini"
        } else if model == "whisper-v3-turbo" {
            return "Fast High-Quality Speech Processing - Supports transcription, translation, and alignment"
        } else if model.contains("parakeet-tdt-0.6b-v3") {
            return "High-performance multilingual ASR - 25 European languages"
        } else if model.contains("parakeet-tdt-0.6b-v2") {
            return "High-performance English ASR - Optimized for speed"
        } else if model.contains("fireworks-asr-large") {
            return "High-Quality Streaming ASR"
        } else if model.contains("fireworks-asr-v2") {
            return "Latest Streaming ASR v2"
        } else if model.contains("mini") {
            return "Fastest, smallest model"
        } else if model.contains("base") {
            return "Good balance of speed and accuracy"
        } else if model.contains("small") {
            return "Better accuracy, moderate speed"
        } else if model.contains("medium") {
            return "High accuracy, slower processing"
        } else if model.contains("large") {
            return "Highest accuracy, slowest processing"
        } else {
            return "Custom model"
        }
    }
    
    private func isModelRecommended(_ model: String) -> Bool {
        // 推奨モデルにタグを表示（OpenAIモデルも含める）
        return model.contains("large") || model.contains("medium") || model.contains("gpt-4o")
    }
}


// MARK: - OpenAIIconView
struct OpenAIIconView: View {
    let isDarkMode: Bool
    
    var body: some View {
        Image(isDarkMode ? "OpenAI-white-monoblossom" : "OpenAI-black-monoblossom")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - PromptInputView
struct PromptInputView: View {
    @Binding var customPrompt: String
    @Binding var showPromptInput: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Custom Prompt")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showPromptInput = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            TextField(" ", text: $customPrompt)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}


#Preview {
    ContentView()
    #if os(macOS)
        .frame(width: 800, height: 500)
    #endif
}

