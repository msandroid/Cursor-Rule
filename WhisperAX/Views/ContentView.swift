//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

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

// MARK: - Logging Manager
class LoggingManager {
    static let shared = LoggingManager()
    
    private let logger = Logger(subsystem: "com.scribe.whisperax", category: "main")
    private var currentLogLevel: LogLevel = .info
    private var isRealtimeProcessing: Bool = false
    private var logQueue = DispatchQueue(label: "com.scribe.logging", qos: .utility)
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
    private let updateQueue = DispatchQueue(label: "com.scribe.ui-updates", qos: .userInitiated)
    
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
    private let metricsQueue = DispatchQueue(label: "com.scribe.performance", qos: .utility)
    
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
    let logger = Logger(subsystem: "com.scribe.whisperax", category: "main")
    logger.log(level: .debug, "[\(category.rawValue)] \(message)")
}

func LogError(_ message: String, category: LogCategory = .stt) {
    let logger = Logger(subsystem: "com.scribe.whisperax", category: "main")
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
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @State private var selectedCategoryId: MenuItem.ID?

    // MARK: Menu items for navigation
    
    struct MenuItem: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var image: String
    }

    private var menu = [
        MenuItem(name: "Transcribe", image: "book.pages"),
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
    
    @State private var localModels: [String] = []
    @State private var localModelPath: String = ""
    @State private var availableModels: [String] = []
    @State private var availableLanguages: [String] = []
    @State private var disabledModels: [String] = WhisperKit.recommendedModels().disabled

    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = String(localized: LocalizedStringResource("No Audio Input", comment: "No audio input default"))
    @AppStorage("selectedModel") private var selectedModel: String = "openai_whisper-base"
    @AppStorage("selectedTask") private var selectedTask: String = "transcribe"
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "japanese"
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
    @State private var confirmedSegments: [TranscriptionSegment] = []
    @State private var unconfirmedSegments: [TranscriptionSegment] = []
    
    // Variables for STT time measurement
    @State private var sttStartTime: Date?
    @State private var sttEndTime: Date?
    @State private var sttProcessingTime: TimeInterval = 0

    // MARK: Eager mode properties

    @State private var eagerResults: [TranscriptionResult?] = []
    @State private var prevResult: TranscriptionResult?
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
    @State private var transcriptionTask: Task<Void, Never>?
    @State private var transcribeTask: Task<Void, Never>?
    @State private var isCopied: Bool = false
    @State private var audioLevels: [Float] = Array(repeating: 0.0, count: 20)
    @State private var waveformTimer: Timer?
    @State private var isWaveformPressed: Bool = false
    @State private var showAsciiArt: Bool = false
    @State private var asciiArtText: String = ""
    @State private var displayedAsciiArt: String = ""
    @State private var streamingTimer: Timer?
    @State private var asciiArtSpeed: Double = 75000.0 // Display speed multiplier
    @State private var isEditingText: Bool = false
    @State private var editedText: String = ""
    @State private var showIcon: Bool = false
    @State private var iconPosition: CGPoint = .zero
    @State private var sharedTexts: [String] = []
    @State private var showSharedTexts: Bool = false
    
    // Font size calculation for ASCII art
    private var asciiArtFont: Font {
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth < 400 {
            return .system(.caption2, design: .monospaced)
        } else if screenWidth < 600 {
            return .system(.caption, design: .monospaced)
        } else {
            return .system(.footnote, design: .monospaced)
        }
        #else
        return .system(.caption, design: .monospaced)
        #endif
    }
    
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
    
    func loadAsciiArt() {
        guard let path = Bundle.main.path(forResource: "art", ofType: "txt") else {
            print("art.txt file not found in Resources directory")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            if let text = String(data: data, encoding: .utf8) {
                asciiArtText = text
                startAsciiArtStreaming()
            }
        } catch {
            print("Error loading ASCII art: \(error)")
        }
    }
    
    func loadSharedTexts() {
        if let sharedDefaults = UserDefaults(suiteName: "group.scribe.ai") {
            sharedTexts = sharedDefaults.stringArray(forKey: "sharedTexts") ?? []
        }
    }
    
    func startAsciiArtStreaming() {
        displayedAsciiArt = ""
        let lines = asciiArtText.components(separatedBy: .newlines)
        var currentLineIndex = 0
        
        streamingTimer?.invalidate()
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.01 / asciiArtSpeed, repeats: true) { timer in
            if currentLineIndex < lines.count {
                // Display one line at a time
                if currentLineIndex > 0 {
                    displayedAsciiArt += "\n"
                }
                displayedAsciiArt += lines[currentLineIndex]
                currentLineIndex += 1
            } else {
                timer.invalidate()
                streamingTimer = nil
            }
        }
    }
    
    func stopAsciiArtStreaming() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        displayedAsciiArt = asciiArtText
    }
    
    func showAsciiArtInstantly() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        displayedAsciiArt = asciiArtText
    }
    
    func triggerAsciiArtDisplay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showAsciiArt = true
        }
        loadAsciiArt()
    }

    // MARK: Views
    
    var asciiArtFullScreenView: some View {
        // ASCII art display
        ZStack {
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(displayedAsciiArt)
                    .font(asciiArtFont)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: true, vertical: true)
                    .padding()
                    .onTapGesture { location in
                        iconPosition = location
                        showIcon.toggle()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Close with downward swipe
                        if value.translation.height > 100 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAsciiArt = false
                            }
                            stopAsciiArtStreaming()
                        }
                    }
            )
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAsciiArt = false
                        }
                        stopAsciiArtStreaming()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
            }
        }
    }
    
    var sourceLanguageHeader: some View {
        HStack {
            Button(action: {
                showLanguageSelection = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                      Text(languageManager.languageDisplayName(for: Constants.languages[selectedLanguage] ?? "ja"))
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
                // Transcribe ボタン
                Button(action: {
                    selectedTask = "transcribe"
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 14, weight: .medium))
                        Text("Transcribe")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedTask == "transcribe" ? .white : .primary)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedTask == "transcribe" ? Color.accentColor : Color.clear)
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

            // 音声波形表示ボタン
            waveformButton
            
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
    
    var waveformButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                // 設定に基づいてアクションを切り替え
                if waveformActionType == "ascii" {
                    triggerAsciiArtDisplay()
                } else {
                    // デフォルトはSTTテキストをクリア
                    clearSTTText()
                }
                
                // 視覚的フィードバック
                isWaveformPressed.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isWaveformPressed.toggle()
                    }
                }
            }
        }) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(isWaveformPressed ? Color(hex: "1CA485") : .white)
                .scaleEffect(isWaveformPressed ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isWaveformPressed)
        }
        .disabled(false) // Enabled
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
    }

    func resetState(preserveText: Bool = false) {
        transcribeTask?.cancel()
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
        NavigationView {
            VStack(spacing: 0) {
                // Source Language設定（上部中央）
                if showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing)) {
                    HStack {
                        Spacer()
                        sourceLanguageHeader
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                
                // ASCII art display時は全画面表示
                if showAsciiArt && !asciiArtText.isEmpty {
                    asciiArtFullScreenView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // メインのテキスト表示エリア
                    transcriptionView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 録音中の波形表示（タップで切り替え + STT中は非表示オプション）
                    if isRecording && showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing)) {
                        waveformView
                            .padding(.bottom, 20)
                    }
                    
                    // 下部の3つのアイコンボタン（タップで切り替え + STT中は非表示オプション）
                    if showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing)) {
                        bottomButtonRow
                    }
                    
                    // Transcribe/Translate切り替えボタン（画面下部）
                    if showUIElements && !(hideIconsDuringSTT && (isRecording || isTranscribing)) {
                        taskToggleView
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
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
            .toolbar {
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
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
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
        .sheet(isPresented: $showDashboardView) {
            DashboardView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showSharedTexts) {
            SharedTextsView(sharedTexts: $sharedTexts)
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage)
        }
        .sheet(isPresented: $showAdvancedOptions) {
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
                selectedTask: $selectedTask,
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
                waveformActionType: $waveformActionType,
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
        .sheet(isPresented: $showTokenCalculator) {
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
        .onAppear {
            fetchModels()
            
            // 確実に文字起こしモードに設定（翻訳モードを無効化）
            selectedTask = "transcribe"
            
            // 言語設定はユーザーの選択を保持（強制変更しない）
            // ただし、LanguageManagerとの同期は確保
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            languageManager.setLanguage(currentLanguageCode)
            
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
        .onReceive(NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)) { _ in
            // 端末の言語設定が変更された時の処理（ユーザーの選択を尊重）
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            languageManager.setLanguage(currentLanguageCode)
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // 言語変更の通知を受け取って画面を強制更新
            // LanguageManagerとの同期を確保（ユーザーの選択を変更しない）
            let currentLanguageCode = Constants.languages[selectedLanguage] ?? Constants.defaultLanguageCode
            if languageManager.currentLanguage != currentLanguageCode {
                languageManager.setLanguage(currentLanguageCode)
            }
        }
        .onDisappear {
            // タイマーをクリーンアップ
            streamingTimer?.invalidate()
            streamingTimer = nil
        }
        }
    }

    // MARK: - Transcription

    var transcriptionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // STT結果のテキスト表示部分
                if !getTranscriptionText().isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditingText {
                            // 編集モード
                            Text(editedText)
                                .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onAppear {
                                    editedText = getTranscriptionText()
                                }
                        } else {
                            // 表示モード
                            if enableEagerDecoding {
                                let startSeconds = eagerResults.first??.segments.first?.start ?? 0
                                let endSeconds = lastAgreedSeconds > 0 ? lastAgreedSeconds : eagerResults.last??.segments.last?.end ?? 0
                                let timestampText = (enableTimestamps && eagerResults.first != nil) ? "[\(String(format: "%.2f", startSeconds)) --> \(String(format: "%.2f", endSeconds))]" : ""
                                Text("\(timestampText) \(Text(confirmedText).fontWeight(.bold))\(Text(hypothesisText).fontWeight(.bold).foregroundColor(.gray))")
                                    .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                // 確定済みテキスト（固定表示）
                                if !confirmedSegments.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(Array(confirmedSegments.enumerated()), id: \.element) { _, segment in
                                            let timestampText = enableTimestamps ? "[\(String(format: "%.2f", segment.start)) --> \(String(format: "%.2f", segment.end))]" : ""
                                            Text(timestampText + segment.text)
                                                .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .id("confirmed-\(segment.start)-\(segment.end)") // 安定したID
                                        }
                                    }
                                }
                                
                                // 未確定テキスト（動的表示、グレーアウト）
                                if !unconfirmedSegments.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(Array(unconfirmedSegments.enumerated()), id: \.element) { _, segment in
                                            let timestampText = enableTimestamps ? "[\(String(format: "%.2f", segment.start)) --> \(String(format: "%.2f", segment.end))]" : ""
                                            Text(timestampText + segment.text)
                                                .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .id("unconfirmed-\(segment.start)-\(segment.end)") // 安定したID
                                        }
                                    }
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
                                        editedText = getTranscriptionText()
                                        isEditingText = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(getTranscriptionText().isEmpty)
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
                                    .disabled(getTranscriptionText().isEmpty)
                                }
                                
                                // コピーボタン（編集モード中は無効）
                                if !isEditingText {
                                    Button(action: {
                                        let textToCopy = getTranscriptionText()
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
                                    .disabled(getTranscriptionText().isEmpty)
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
               let task = transcribeTask,
               !task.isCancelled,
               whisperKit.progress.fractionCompleted < 1
            {
                VStack(spacing: 16) {
                    ProgressView(whisperKit.progress)
                        .progressViewStyle(.linear)
                        .labelsHidden()
                        .frame(width: 200)
                        .tint(Color(hex: "1CA485"))
                    
                    Text(String(localized: LocalizedStringResource("Sampling", comment: "Sampling indicator text")))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        transcribeTask?.cancel()
                        transcribeTask = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding()
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
            let newSegment = TranscriptionSegment(
                start: confirmedSegments.first?.start ?? 0.0,
                end: confirmedSegments.last?.end ?? 0.0,
                text: editedText,
                tokens: [],
                words: []
            )
            confirmedSegments = [newSegment]
            unconfirmedSegments = []
        }
    }
    
    func shareText() {
        let textToShare = getTranscriptionText()
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
    
    func getTranscriptionText() -> String {
        let rawText: String
        if enableEagerDecoding {
            rawText = confirmedText + hypothesisText
        } else {
            let confirmedText = confirmedSegments.map { $0.text }.joined(separator: " ")
            let unconfirmedText = unconfirmedSegments.map { $0.text }.joined(separator: " ")
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
        
        // Add line breaks after ? and !
        formattedText = formattedText.replacingOccurrences(of: "?", with: "?\n")
        formattedText = formattedText.replacingOccurrences(of: "!", with: "!\n")
        
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
            selectedModel = "openai_whisper-base"
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

        // First check what's already downloaded
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
                                transcribeFile(path: audioURL.path)
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
                            transcribeFile(path: selectedFileURL.path)
                        } catch {
                            print("File selection error: \(error.localizedDescription)")
                        }
                    }
                }
            case let .failure(error):
                print("File selection error: \(error.localizedDescription)")
        }
    }

    func transcribeFile(path: String) {
        resetState()
        whisperKit?.audioProcessor = AudioProcessor()
        transcribeTask = Task {
            isTranscribing = true
            do {
                try await transcribeCurrentFile(path: path)
            } catch {
                print("File selection error: \(error.localizedDescription)")
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
        if let audioProcessor = whisperKit?.audioProcessor {
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

                do {
                    try audioProcessor.startRecordingLive(inputDeviceID: deviceId) { _ in
                        DispatchQueue.main.async {
                            bufferSeconds = Double(whisperKit?.audioProcessor.audioSamples.count ?? 0) / Double(WhisperKit.sampleRate)
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
                    }
                    
                    if loop {
                        realtimeLoop()
                    }
                } catch {
                    await MainActor.run {
                        currentText = String(localized: LocalizedStringResource("Failed to start recording.", comment: "Error message when recording fails to start"))
                    }
                    print("Failed to start recording: \(error)")
                }
            }
        } else {
            currentText = String(localized: LocalizedStringResource("WhisperKit not initialized.", comment: "Error message when WhisperKit is not initialized"))
        }
    }

    func stopRecording(_ loop: Bool) {
        isRecording = false
        stopRealtimeTranscription()
        
        // 波形アニメーションを停止
        stopWaveformAnimation()
        
        if let audioProcessor = whisperKit?.audioProcessor {
            audioProcessor.stopRecording()
        }

        // 録音停止時のメッセージ（STTテキストがある場合は上書きしない）
        if currentText == String(localized: LocalizedStringResource("Recording started.", comment: "Status message when recording starts")) || currentText == "Waiting for speech..." {
            currentText = ""
        }

        // 最終的な転写処理を実行
        transcribeTask = Task {
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
                    let transcriptionText = getTranscriptionText()
                    if transcriptionText.isEmpty {
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
                    let transcriptionText = getTranscriptionText()
                    if transcriptionText.isEmpty {
                        currentText = String(localized: LocalizedStringResource("Error during final transcription.", comment: "Error message when final transcription fails"))
                    }
                    // STTテキストがある場合は、エラーメッセージを表示せずに既存テキストを保持
                }
                print("Error: \(error.localizedDescription)")
            }
            isTranscribing = false
        }
    }

    func finalizeText() {
        // Finalize unconfirmed text
        if hypothesisText != "" {
            confirmedText += hypothesisText
            hypothesisText = ""
        }

        if !unconfirmedSegments.isEmpty {
            confirmedSegments.append(contentsOf: unconfirmedSegments)
            unconfirmedSegments = []
        }
        
        // 前のセグメントの保護：確定済みセグメントのテキストを変更禁止
        protectConfirmedSegments()
        
        // 未確定セグメントの保護：現在のセグメント以外のテキスト変更を禁止
        protectUnconfirmedSegments()
        
        // 未確認のテキストも確定済みに追加
        if !currentText.isEmpty && !currentText.contains("Recording") && !currentText.contains("Waiting") {
            let finalText = getTranscriptionText()
            if !finalText.isEmpty {
                // テキストが正常に取得できた場合、コピー可能状態にする
                print("Final transcription text: \(finalText)")
                
                // アナリティクスを更新
                updateAnalyticsAfterTranscription(finalText: finalText)
            }
        }
    }
    
    // MARK: - Segment Protection
    
    /// 確定済みセグメントのテキスト変更を禁止する
    private func protectConfirmedSegments() {
        // 確定済みセグメントのテキストを固定化
        for i in 0..<confirmedSegments.count {
            confirmedSegments[i] = TranscriptionSegment(
                start: confirmedSegments[i].start,
                end: confirmedSegments[i].end,
                text: confirmedSegments[i].text, // テキストを固定
                tokens: confirmedSegments[i].tokens,
                words: confirmedSegments[i].words
            )
        }
        
        LogDebug("Protected \(confirmedSegments.count) confirmed segments from modification", category: .stt)
    }
    
    /// 未確定セグメントのうち、現在のテキストセグメント以外のテキスト変更を禁止する
    private func protectUnconfirmedSegments() {
        guard !unconfirmedSegments.isEmpty else { return }
        
        // 現在のテキストセグメント（最後のセグメント）を特定
        let currentSegmentIndex = unconfirmedSegments.count - 1
        
        // 現在のセグメント以外を保護
        for i in 0..<currentSegmentIndex {
            unconfirmedSegments[i] = TranscriptionSegment(
                start: unconfirmedSegments[i].start,
                end: unconfirmedSegments[i].end,
                text: unconfirmedSegments[i].text, // テキストを固定
                tokens: unconfirmedSegments[i].tokens,
                words: unconfirmedSegments[i].words
            )
        }
        
        LogDebug("Protected \(currentSegmentIndex) unconfirmed segments (excluding current) from modification", category: .stt)
    }
    
    // MARK: - Analytics Update
    
    private func updateAnalyticsAfterTranscription(finalText: String) {
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
        analyticsManager.recordTranscription(
            duration: duration,
            language: language,
            text: finalText,
            model: modelName
        )
        
        // バックグラウンドでトークン計算を実行
        Task {
            await TokenCalculationService.shared.calculateTokensForTranscription(finalText: finalText)
        }
        
        print("Analytics updated: duration=\(duration)s, language=\(language), model=\(modelName)")
    }
    

    // MARK: - Transcribe Logic

    func transcribeCurrentFile(path: String) async throws {
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

        let transcription: TranscriptionResult?
        do {
            transcription = try await transcribeAudioSamples(audioFileSamples)
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
            guard let segments = transcription?.segments else {
                return
            }

            // STT処理終了時間を記録
            sttEndTime = Date()
            if let startTime = sttStartTime {
                sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
            }

            tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
            effectiveRealTimeFactor = transcription?.timings.realTimeFactor ?? 0
            effectiveSpeedFactor = transcription?.timings.speedFactor ?? 0
            currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)
            firstTokenTime = transcription?.timings.firstTokenTime ?? 0
            modelLoadingTime = transcription?.timings.modelLoading ?? 0
            pipelineStart = transcription?.timings.pipelineStart ?? 0
            currentLag = transcription?.timings.decodingLoop ?? 0

            confirmedSegments = segments
            
            // ファイル転写完了時にアナリティクスを更新
            let finalText = segments.map { $0.text }.joined()
            if !finalText.isEmpty {
                updateAnalyticsAfterTranscription(finalText: finalText)
            }
        }
    }

    func transcribeAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }

        // サンプルコードと同じシンプルなアプローチ
        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = selectedTask == "transcribe" ? .transcribe : .translate
        let seekClip: [Float] = [lastConfirmedSegmentEndSeconds]
        
        // デバッグログ
        print("🔧 TRANSCRIBE DEBUG:")
        print("  selectedLanguage: '\(selectedLanguage)'")
        print("  languageCode: '\(languageCode)'")
        print("  task will be set to: .transcribe (forced)")
        print("  usePrefillPrompt: true (forced)")
        print("  usePrefillCache: true (forced)")

        let options = DecodingOptions(
            verbose: true,
            task: .transcribe, // 強制的にtranscribeに設定
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: true, // Prompt Prefillを有効にして確実にtranscribeモードを強制
            usePrefillCache: true, // Cache Prefillも有効にして最適化
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

            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = TextUtilities.compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    Logging.debug("Early stopping due to compression threshold")
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                Logging.debug("Early stopping due to logprob threshold")
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

        let transcriptionResults: [TranscriptionResult] = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )

        // Resampling progress completion
        await MainActor.run {
            resamplingProgress = 1.0
        }

        let mergedResults = TranscriptionUtilities.mergeTranscriptionResults(transcriptionResults)
        
        
        if let firstSegment = mergedResults.segments.first {
            LogDebug("First segment timing: \(firstSegment.start) -> \(firstSegment.end)", category: .stt)
        }
        

        return mergedResults
    }

    // MARK: Streaming Logic

    func realtimeLoop() {
        // リアルタイム処理開始時の最適化設定
        LoggingManager.shared.setRealtimeProcessing(true)
        UIOptimizer.shared.setRealtimeProcessing(true)
        // tokenCalculator.setRealtimeProcessing(true) // TODO: 実装後に有効化
        
        transcriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await transcribeCurrentBuffer(delayInterval: Float(realtimeDelayInterval))
                } catch {
                    LogError("Transcription error: \(error.localizedDescription)", category: .stt)
                    break
                }
            }
        }
    }

    func stopRealtimeTranscription() {
        isTranscribing = false
        transcriptionTask?.cancel()
        
        // リアルタイム処理終了時の最適化設定解除
        LoggingManager.shared.setRealtimeProcessing(false)
        UIOptimizer.shared.setRealtimeProcessing(false)
        // tokenCalculator.setRealtimeProcessing(false) // TODO: 実装後に有効化
    }

    func transcribeCurrentBuffer(delayInterval: Float = 1.0) async throws {
        guard let whisperKit = whisperKit else { return }
        
        // パフォーマンス測定開始
        PerformanceManager.shared.startMeasurement("buffer_processing")

        // Retrieve the current audio buffer from the audio processor
        let currentBuffer = whisperKit.audioProcessor.audioSamples

        // Calculate the size and duration of the next buffer segment
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)

        // Only run the transcribe if the next buffer has at least `delayInterval` seconds of audio
        guard nextBufferSeconds > delayInterval else {
            try await Task.sleep(nanoseconds: 50_000_000) // sleep for 50ms for next buffer
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
                // Implement silence buffer purging for better VAD performance
                if nextBufferSeconds > 3 {
                    // This is a completely silent segment of 3s, so we can purge the audio and confirm anything pending
                    lastConfirmedSegmentEndSeconds = 0
                    whisperKit.audioProcessor.purgeAudioSamples(keepingLast: 1 * WhisperKit.sampleRate) // keep last 1s to include VAD overlap
                    lastBufferSize = 0
                    confirmedSegments.append(contentsOf: unconfirmedSegments)
                    unconfirmedSegments = []
                }

                // Sleep for 50ms and check the next buffer
                try await Task.sleep(nanoseconds: 50_000_000)
                return
            }
        }

        // Store this for next iterations VAD
        lastBufferSize = currentBuffer.count

        if enableEagerDecoding && false {
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
            let transcription = try await transcribeAudioSamples(Array(currentBuffer))

            // パフォーマンス測定開始
            PerformanceManager.shared.startMeasurement("transcription_processing")
            
            // UI更新をバッチ化
            UIOptimizer.shared.scheduleUpdate {
                currentText = ""
                guard let segments = transcription?.segments else {
                    return
                }

                // リアルタイム処理の場合は累積時間を更新
                if sttStartTime == nil {
                    sttStartTime = Date()
                }
                sttEndTime = Date()
                if let startTime = sttStartTime {
                    sttProcessingTime = sttEndTime!.timeIntervalSince(startTime)
                }

                tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
                firstTokenTime = transcription?.timings.firstTokenTime ?? 0
                modelLoadingTime = transcription?.timings.modelLoading ?? 0
                pipelineStart = transcription?.timings.pipelineStart ?? 0
                currentLag = transcription?.timings.decodingLoop ?? 0
                currentEncodingLoops += Int(transcription?.timings.totalEncodingRuns ?? 0)

                let totalAudio = Double(currentBuffer.count) / Double(WhisperKit.sampleRate)
                totalInferenceTime += transcription?.timings.fullPipeline ?? 0
                effectiveRealTimeFactor = Double(totalInferenceTime) / totalAudio
                effectiveSpeedFactor = totalAudio / Double(totalInferenceTime)
                
                // リアルタイムファクターの更新
                PerformanceManager.shared.updateRealtimeFactor(effectiveRealTimeFactor)
            }

            // セグメント処理をバッチ化（安定化）
            UIOptimizer.shared.scheduleUpdate {
                guard let segments = transcription?.segments else { return }
                
                // より安定したセグメント確定処理
                if segments.count > requiredSegmentsForConfirmation {
                    // Calculate the number of segments to confirm
                    let numberOfSegmentsToConfirm = segments.count - requiredSegmentsForConfirmation

                    // Confirm the required number of segments
                    let confirmedSegmentsArray = Array(segments.prefix(numberOfSegmentsToConfirm))
                    let remainingSegments = Array(segments.suffix(requiredSegmentsForConfirmation))

                    // Update lastConfirmedSegmentEnd based on the last confirmed segment
                    if let lastConfirmedSegment = confirmedSegmentsArray.last, lastConfirmedSegment.end > lastConfirmedSegmentEndSeconds {
                        lastConfirmedSegmentEndSeconds = lastConfirmedSegment.end
                        LogDebug("Last confirmed segment end: \(lastConfirmedSegmentEndSeconds)", category: .stt)

                        // 確定済みセグメントを追加（重複チェック強化）
                        for segment in confirmedSegmentsArray {
                            let segmentExists = confirmedSegments.contains { existingSegment in
                                existingSegment.start == segment.start && 
                                existingSegment.end == segment.end && 
                                existingSegment.text == segment.text
                            }
                            if !segmentExists {
                                confirmedSegments.append(segment)
                            }
                        }
                        
                        // 前のセグメントの保護：確定済みセグメントのテキストを変更禁止
                        protectConfirmedSegments()
                    }

                    // 未確定セグメントを更新（アニメーション無効）
                    unconfirmedSegments = remainingSegments
                    
                    // 前のセグメントの保護：確定済みセグメントのテキストを変更禁止
                    protectConfirmedSegments()
                    
                    // 未確定セグメントの保護：現在のセグメント以外のテキスト変更を禁止
                    protectUnconfirmedSegments()
                } else {
                    // Handle the case where segments are fewer or equal to required
                    unconfirmedSegments = segments
                    
                    // 前のセグメントの保護：確定済みセグメントのテキストを変更禁止
                    protectConfirmedSegments()
                    
                    // 未確定セグメントの保護：現在のセグメント以外のテキスト変更を禁止
                    protectUnconfirmedSegments()
                }
            }
            
            // パフォーマンス測定終了
            PerformanceManager.shared.endMeasurement("buffer_processing")
        }
    }

    func transcribeEagerMode(_ samples: [Float]) async throws -> TranscriptionResult? {
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
            task: .transcribe, // 強制的にtranscribeに設定
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: true, // Prompt Prefillを有効にして確実にtranscribeモードを強制
            usePrefillCache: true, // Cache Prefillも有効にして最適化
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
            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = TextUtilities.compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    Logging.debug("Early stopping due to compression threshold")
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                Logging.debug("Early stopping due to logprob threshold")
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
        streamOptions.prefixTokens = lastAgreedTokens
        do {
            let transcription: TranscriptionResult? = try await whisperKit.transcribe(audioArray: streamingAudio, decodeOptions: streamOptions, callback: decodingCallback).first
            await MainActor.run {
                var skipAppend = false
                if let result = transcription {
                    hypothesisWords = result.allWords.filter { $0.start >= lastAgreedSeconds }

                    if let prevResult = prevResult {
                        prevWords = prevResult.allWords.filter { $0.start >= lastAgreedSeconds }
                        let commonPrefix = TranscriptionUtilities.findLongestCommonPrefix(prevWords, hypothesisWords)
                        Logging.info("[EagerMode] Prev \"\((prevWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Next \"\((hypothesisWords.map { $0.word }).joined())\"")
                        Logging.info("[EagerMode] Found common prefix \"\((commonPrefix.map { $0.word }).joined())\"")

                        if commonPrefix.count >= Int(tokenConfirmationsNeeded) {
                            lastAgreedWords = commonPrefix.suffix(Int(tokenConfirmationsNeeded))
                            lastAgreedSeconds = lastAgreedWords.first!.start
                            Logging.info("[EagerMode] Found new last agreed word \"\(lastAgreedWords.first!.word)\" at \(lastAgreedSeconds) seconds")

                            confirmedWords.append(contentsOf: commonPrefix.prefix(commonPrefix.count - Int(tokenConfirmationsNeeded)))
                            let currentWords = confirmedWords.map { $0.word }.joined()
                            Logging.info("[EagerMode] Current:  \(lastAgreedSeconds) -> \(Double(samples.count) / 16000.0) \(currentWords)")
                        } else {
                            Logging.info("[EagerMode] Using same last agreed time \(lastAgreedSeconds)")
                            skipAppend = true
                        }
                    }
                    prevResult = result
                }

                if !skipAppend {
                    eagerResults.append(transcription)
                }
            }

            await MainActor.run {
                let finalWords = confirmedWords.map { $0.word }.joined()
                confirmedText = finalWords

                // Accept the final hypothesis because it is the last of the available audio
                let lastHypothesis = lastAgreedWords + TranscriptionUtilities.findLongestDifferentSuffix(prevWords, hypothesisWords)
                hypothesisText = lastHypothesis.map { $0.word }.joined()
            }
        } catch {
            Logging.error("[EagerMode] Error: \(error)")
            finalizeText()
        }

        let mergedResult = TranscriptionUtilities.mergeTranscriptionResults(eagerResults, confirmedWords: confirmedWords)

        return mergedResult
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
}



#Preview {
    ContentView()
    #if os(macOS)
        .frame(width: 800, height: 500)
    #endif
}
