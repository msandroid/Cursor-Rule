//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import AVFoundation
import Charts
import CoreML
import SwiftUI
import WhisperKit
import Foundation

struct CriptionWatchView: View {
    @State private var whisperKit: WhisperKit?
    @State private var currentText = "Tap below to start"
    @State private var isTranscribing = false
    @State private var isRecording = false
    @State private var energyToDisplayCount = 100
    // TODO: Make this configurable in the UI
    @State var modelStorage: String = "huggingface/models/argmaxinc/whisperkit-coreml"

    @AppStorage("selectedModel") private var selectedModel: String = WhisperKit.recommendedModels().default
    @AppStorage("selectedTab") private var selectedTab: String = "TranCription"
    @AppStorage("selectedTask") private var selectedTask: String = "tranCription"
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "auto"
    @AppStorage("repoName") private var repoName: String = "argmaxinc/whisperkit-coreml"
    @AppStorage("enableTimestamps") private var enableTimestamps: Bool = false
    @AppStorage("enablePromptPrefill") private var enablePromptPrefill: Bool = true
    @AppStorage("enableCachePrefill") private var enableCachePrefill: Bool = true
    @AppStorage("enableSpecialCharacters") private var enableSpecialCharacters: Bool = false
    @AppStorage("enableEagerDecoder") private var enableEagerDecoder: Bool = false
    @AppStorage("temperatureStart") private var temperatureStart: Double = 0
    @AppStorage("fallbackCount") private var fallbackCount: Double = 4
    @AppStorage("compressionCheckWindow") private var compressionCheckWindow: Double = 20
    @AppStorage("sampleLength") private var sampleLength: Double = 224
    @AppStorage("silenceThreshold") private var silenceThreshold: Double = 0.3
    @AppStorage("useVAD") private var useVAD: Bool = true

    @State private var modelState: ModelState = .unloaded
    @State private var localModels: [String] = []
    @State private var localModelPath: String = ""
    @State private var availableModels: [String] = []
    @State private var availableLanguages: [String] = []
    @State private var disabledModels: [String] = WhisperKit.recommendedModels().disabled
    
    // 言語データ
    private let languages: [(code: String, name: String)] = [
        ("en", "English (英語)"),
        ("zh", "Chinese (中国語)"),
        ("de", "German (ドイツ語)"),
        ("es", "Spanish (スペイン語)"),
        ("ru", "Russian (ロシア語)"),
        ("ko", "Korean (韓国語)"),
        ("fr", "French (フランス語)"),
        ("ja", "Japanese (日本語)"),
        ("pt", "Portuguese (ポルトガル語)"),
        ("tr", "Turkish (トルコ語)"),
        ("nl", "Dutch (オランダ語)"),
        ("pl", "Polish (ポーランド語)"),
        ("ca", "Catalan (カタルーニャ語)"),
        ("ar", "Arabic (アラビア語)"),
        ("sv", "Swedish (スウェーデン語)"),
        ("it", "Italian (イタリア語)"),
        ("id", "Indonesian (インドネシア語)"),
        ("hi", "Hindi (ヒンディー語)"),
        ("fi", "Finnish (フィンランド語)"),
        ("vi", "Vietnamese (ベトナム語)"),
        ("he", "Hebrew (ヘブライ語)"),
        ("uk", "Ukrainian (ウクライナ語)"),
        ("el", "Greek (ギリシャ語)"),
        ("ms", "Malay (マレー語)"),
        ("cs", "Czech (チェコ語)"),
        ("ro", "Romanian (ルーマニア語)"),
        ("da", "Danish (デンマーク語)"),
        ("hu", "Hungarian (ハンガリー語)"),
        ("ta", "Tamil (タミル語)"),
        ("no", "Norwegian (ノルウェー語)"),
        ("th", "Thai (タイ語)"),
        ("ur", "Urdu (ウルドゥー語)"),
        ("hr", "Croatian (クロアチア語)"),
        ("bg", "Bulgarian (ブルガリア語)"),
        ("lt", "Lithuanian (リトアニア語)"),
        ("la", "Latin (ラテン語)"),
        ("mi", "Maori (マオリ語)"),
        ("ml", "Malayalam (マラヤーラム語)"),
        ("cy", "Welsh (ウェールズ語)"),
        ("sk", "Slovak (スロバキア語)"),
        ("te", "Telugu (テルグ語)"),
        ("fa", "Persian (ペルシャ語)"),
        ("lv", "Latvian (ラトビア語)"),
        ("bn", "Bengali (ベンガル語)"),
        ("sr", "Serbian (セルビア語)"),
        ("az", "Azerbaijani (アゼルバイジャン語)"),
        ("sl", "Slovenian (スロベニア語)"),
        ("kn", "Kannada (カンナダ語)"),
        ("et", "Estonian (エストニア語)"),
        ("mk", "Macedonian (マケドニア語)"),
        ("br", "Breton (ブルトン語)"),
        ("eu", "Basque (バスク語)"),
        ("is", "Icelandic (アイスランド語)"),
        ("hy", "Armenian (アルメニア語)"),
        ("ne", "Nepali (ネパール語)"),
        ("mn", "Mongolian (モンゴル語)"),
        ("bs", "Bosnian (ボスニア語)"),
        ("kk", "Kazakh (カザフ語)"),
        ("sq", "Albanian (アルバニア語)"),
        ("sw", "Swahili (スワヒリ語)"),
        ("gl", "Galician (ガリシア語)"),
        ("mr", "Marathi (マラーティー語)"),
        ("pa", "Punjabi (パンジャブ語)"),
        ("si", "Sinhala (シンハラ語)"),
        ("km", "Khmer (クメール語)"),
        ("sn", "Shona (ショナ語)"),
        ("yo", "Yoruba (ヨルバ語)"),
        ("so", "Somali (ソマリ語)"),
        ("af", "Afrikaans (アフリカーンス語)"),
        ("oc", "Occitan (オック語)"),
        ("ka", "Georgian (グルジア語)"),
        ("be", "Belarusian (ベラルーシ語)"),
        ("tg", "Tajik (タジク語)"),
        ("sd", "Sindhi (シンド語)"),
        ("gu", "Gujarati (グジャラート語)"),
        ("am", "Amharic (アムハラ語)"),
        ("yi", "Yiddish (イディッシュ語)"),
        ("lo", "Lao (ラオ語)"),
        ("uz", "Uzbek (ウズベク語)"),
        ("fo", "Faroese (フェロー語)"),
        ("ht", "Haitian Creole (ハイチ・クレオール語)"),
        ("ps", "Pashto (パシュトー語)"),
        ("tk", "Turkmen (トルクメン語)"),
        ("nn", "Nynorsk (ニーノシュク)"),
        ("mt", "Maltese (マルタ語)"),
        ("sa", "Sanskrit (サンスクリット語)"),
        ("lb", "Luxembourgish (ルクセンブルク語)"),
        ("my", "Myanmar (ミャンマー語)"),
        ("bo", "Tibetan (チベット語)"),
        ("tl", "Tagalog (タガログ語)"),
        ("mg", "Malagasy (マラガシ語)"),
        ("as", "Assamese (アッサム語)"),
        ("tt", "Tatar (タタール語)"),
        ("haw", "Hawaiian (ハワイ語)"),
        ("ln", "Lingala (リンガラ語)"),
        ("ha", "Hausa (ハウサ語)"),
        ("ba", "Bashkir (バシキール語)"),
        ("jw", "Javanese (ジャワ語)"),
        ("su", "Sundanese (スンダ語)"),
        ("yue", "Cantonese (広東語)")
    ]
    
    // モデル表示名と実際のモデルIDのマッピング
    private let modelNameMapping: [String: String] = [
        "Cription Swift English": "whisper-tiny.en",
        "Quantum Cription mini English": "whisper-base.en", 
        "Cription Pro English": "whisper-small.en",
        "Cription Enterprise English": "whisper-medium.en",
        "Cription Swift": "whisper-tiny",
        "Cription mini": "whisper-base",
        "Cription Pro": "whisper-small",
        "Cription Enterprise": "whisper-medium",
        "Cription Ultra": "whisper-large-v3",
        "Cription UltraTurbo": "whisper-large-v3_turbo",
        "Quantum Cription English": "whisper-small.en_217MB",
        "Quantum Cription mini": "Quantum Cription mini",
        "Quantum Cription UltraLite 1.0": "whisper-large-v2_949MB",
        "Quantum Cription UltraTurboLite 2.0": "whisper-large-v2_turbo_955MB",
        "Quantum Cription UltraLite 3.0": "whisper-large-v3_947MB",
        "Quantum Cription UltraTurboLite 3.5": "whisper-large-v3_turbo_954MB",
        "Quantum Cription Ultra 3.6": "whisper-large-v3-v20240930",
        "Quantum Cription UltraTurbo 3.6": "whisper-large-v3-v20240930_turbo",
        "Quantum Cription UltraLite 3.6": "whisper-large-v3-v20240930_547MB",
        "Quantum Cription UltraLite+ 3.6": "whisper-large-v3-v20240930_626MB",
        "Quantum Cription UltraTurboLite 3.6": "whisper-large-v3-v20240930_turbo_632MB",
        "Cription Dual 3.0": "distil-whisper_distil-large-v3",
        "Cription Dual 0.5": "distil-whisper_distil-large-v3_594MB",
        "Cription Dual 1.5": "distil-whisper_distil-large-v3_turbo",
        "Cription Dual 0.6": "distil-whisper_distil-large-v3_turbo_600MB"
    ]

    @State private var loadingProgressValue: Float = 0.0
    @State private var specializationProgressRatio: Float = 0.7
    @State private var currentLag: TimeInterval = 0
    @State private var currentFallbacks: Int = 0
    @State private var lastBufferSize: Int = 0
    @State private var lastConfirmedSegmentEndSeconds: Float = 0
    @State private var requiredSegmentsForConfirmation: Int = 2
    @State private var bufferEnergy: [EnergyValue] = []
    @State private var confirmedSegments: [TranscriptionSegment] = []
    @State private var unconfirmedSegments: [TranscriptionSegment] = []
    @State private var unconfirmedText: [String] = []

    @State private var tranCriptionTask: Task<Void, Never>? = nil

    @State private var selectedCategoryId: MenuItem.ID?
    private var menu = [
        MenuItem(name: "Start Transcribing", image: "waveform.badge.mic"),
    ]

    struct MenuItem: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var image: String
    }

    struct EnergyValue: Identifiable {
        let id = UUID()
        var index: Int
        var value: Float
    }

    var body: some View {
        NavigationSplitView {
            if WhisperKit.deviceName().hasPrefix("Watch7") || WhisperKit.isRunningOnSimulator {
                modelSelectorView
                    .navigationBarTitleDisplayMode(.automatic)

                if modelState == .loaded {
                    VStack {
                        // 言語選択
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.code) { language in
                                Text(language.name)
                                    .tag(language.code)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 60)
                        
                        List(menu, selection: $selectedCategoryId) { item in
                            HStack {
                                Image(systemName: item.image)
                                Text(item.name)
                                    .scaledToFit()
                                    .minimumScaleFactor(0.5)
                                    .font(.system(.title3))
                                    .bold()
                                    .padding(.horizontal)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .navigationBarTitleDisplayMode(.automatic)
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.applewatch")
                        .foregroundColor(.red)
                        .font(.system(size: 80))
                        .padding()

                    Text("Sorry, this app\nrequires Apple Watch\nSeries 9 or Ultra 2")
                        .scaledToFill()
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .navigationBarTitleDisplayMode(.inline)
            }

        } detail: {
            streamingView
        }
        .onAppear {
            fetchModels()
            // アプリ起動時にCription Swiftを自動でダウンロード・ロード
            if selectedModel == WhisperKit.recommendedModels().default {
                selectedModel = "Cription Swift"
                loadModel("Cription Swift")
                modelState = .loading
            }
        }
    }

    var modelStatusView: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundStyle(modelState == .loaded ? .green : (modelState == .unloaded ? .red : .yellow))
                .symbolEffect(.variableColor, isActive: modelState != .loaded && modelState != .unloaded)
            Text(modelState.description)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var modelSelectorView: some View {
        Group {
            VStack {
                modelStatusView
                    .padding(.top)
                HStack {
                    if availableModels.count > 0 {
                        Picker("", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                HStack {
                                    let isLocal = localModels.contains { $0 == model.description }
                                    let modelIcon = isLocal ? "checkmark.circle" : "arrow.down.circle.dotted"
                                    let modelText = "\(Image(systemName: modelIcon)) \(model.description)"
                                    Text(modelText).tag(model.description)
                                        .scaledToFit()
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                        .frame(height: 80)
                        .pickerStyle(.wheel)
                        .onChange(of: selectedModel, initial: false) { _, _ in
                            resetState()
                            modelState = .unloaded
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.5)
                    }
                }

                if modelState == .unloaded {
                    Button {
                        resetState()
                        loadModel(selectedModel)
                        modelState = .loading
                    } label: {
                        Text("Load Model")
                    }
                    .buttonStyle(.bordered)
                } else if loadingProgressValue < 1.0 {
                    VStack {
                        HStack {
                            ProgressView(value: loadingProgressValue, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(maxWidth: .infinity)

                            Text(String(format: "%.1f%%", loadingProgressValue * 100))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if modelState == .prewarming {
                            Text("Specializing \(selectedModel)...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }

    var streamingView: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: Alignment.topLeading)
                HStack(alignment: .bottom) {
                    if isRecording {
                        Chart(bufferEnergy) {
                            BarMark(
                                x: .value("", $0.index),
                                y: .value("", $0.value),
                                width: 2,
                                stacking: .center
                            )
                            .cornerRadius(1)
                            .foregroundStyle($0.value > Float(silenceThreshold) ? .white : .green)
                        }
                        .chartXAxis(.hidden)
                        .chartXScale(domain: [0, energyToDisplayCount])
                        .chartYAxis(.hidden)
                        .chartYScale(domain: [-0.5, 0.5])
                        .frame(height: 30)
                        .padding(.bottom)
                    }
                }
            }
            .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    Spacer()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: Alignment.topLeading)
                    ForEach(Array(confirmedSegments.enumerated()), id: \.element) { _, segment in
                        Text(segment.text)
                            .font(.headline)
                            .fontWeight(.bold)
                            .tint(.green)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(Array(unconfirmedSegments.enumerated()), id: \.element) { _, segment in
                        Text(segment.text)
                            .font(.headline)
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                let currentTranCription = (confirmedSegments.map { $0.text } + unconfirmedSegments.map { $0.text }).joined(separator: " ")
                ShareLink(item: currentTranCription, label: {
                    Image(systemName: "square.and.arrow.up")
                })
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    withAnimation {
                        toggleRecording(shouldLoop: true)
                    }
                } label: {
                    Image(systemName: !isRecording ? "record.circle" : "stop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(modelState != .loaded ? .gray : .red)
                }
                .contentTransition(.symbolEffect(.replace))
                .buttonStyle(BorderlessButtonStyle())
                .disabled(modelState != .loaded)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
    }

    // MARK: Logic

    func resetState() {
        isRecording = false
        isTranscribing = false
        whisperKit?.audioProcessor.stopRecording()
        currentText = ""
        unconfirmedText = []

        currentLag = 0
        currentFallbacks = 0
        lastBufferSize = 0
        lastConfirmedSegmentEndSeconds = 0
        requiredSegmentsForConfirmation = 2
        bufferEnergy = []
        confirmedSegments = []
        unconfirmedSegments = []
    }

    func fetchModels() {
        availableModels = ["Quantum Cription mini", "Quantum Cription mini English", "Cription Swift", "Cription Swift English", "Cription Pro", "Cription Pro English", "Cription Enterprise", "Cription Enterprise English", "Cription Ultra", "Cription UltraTurbo", "Quantum Cription English", "Quantum Cription mini", "Quantum Cription UltraLite 1.0", "Quantum Cription UltraTurboLite 2.0", "Quantum Cription UltraLite 3.0", "Quantum Cription UltraTurboLite 3.5", "Quantum Cription Ultra 3.6", "Quantum Cription UltraTurbo 3.6", "Quantum Cription UltraLite 3.6", "Quantum Cription UltraLite+ 3.6", "Quantum Cription UltraTurboLite 3.6", "Cription Dual 3.0", "Cription Dual 0.5", "Cription Dual 1.5", "Cription Dual 0.6"]
        let devices = MLModel.availableComputeDevices
        print("Available devices: \(devices)")
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
                    }
                } catch {
                    print("Error enumerating files at \(modelPath): \(error.localizedDescription)")
                }
            }
        }

        localModels = WhisperKit.formatModelFiles(localModels)
        for model in localModels {
            // 実際のモデルIDから表示名を取得
            let displayName = modelNameMapping.first { $0.value == model }?.key ?? model
            if !availableModels.contains(displayName),
               !disabledModels.contains(model)
            {
                availableModels.append(displayName)
            }
        }

        print("Found locally: \(localModels)")
        print("Previously selected model: \(selectedModel)")

//        Task {
//            let remoteModels = try await WhisperKit.fetchAvailableModels(from: repoName)
//            for model in remoteModels {
//                if !availableModels.contains(model),
//                   !disabledModels.contains(model){
//                    availableModels.append(model)
//                }
//            }
//        }
    }

    func loadModel(_ model: String, redownload: Bool = false) {
        print("Selected Model: \(selectedModel)")
        
        // 表示名から実際のモデルIDを取得
        let actualModelId = modelNameMapping[model] ?? model
        print("Actual Model ID: \(actualModelId)")

        whisperKit = nil
        Task {
            let config = WhisperKitConfig(verbose: true,
                                          logLevel: .debug,
                                          prewarm: false,
                                          load: false,
                                          download: false)

            whisperKit = try await WhisperKit(config)
            guard let whisperKit = whisperKit else {
                return
            }

            var folder: URL?

            // Check if the model is available locally
            if localModels.contains(actualModelId) && !redownload {
                // Get local model folder URL from localModels
                // TODO: Make this configurable in the UI
                // TODO: Handle incomplete downloads
                folder = URL(fileURLWithPath: localModelPath).appendingPathComponent(actualModelId)
            } else {
                // Download the model using the actual model ID
                folder = try await WhisperKit.download(variant: actualModelId, from: repoName, progressCallback: { progress in
                    DispatchQueue.main.async {
                        loadingProgressValue = Float(progress.fractionCompleted) * specializationProgressRatio
                        modelState = .downloading
                    }
                })
            }

            if let modelFolder = folder {
                whisperKit.modelFolder = modelFolder

                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio
                    modelState = .prewarming
                }

                let progressBarTask = Task {
                    await updateProgressBar(targetProgress: 0.9, maxTime: 240)
                }

                // Prewarm models
                do {
                    try await whisperKit.prewarmModels()
                    progressBarTask.cancel()
                } catch {
                    print("Error prewarming models, retrying: \(error.localizedDescription)")
                    progressBarTask.cancel()
                    if !redownload {
                        loadModel(selectedModel, redownload: true)
                        return
                    } else {
                        // Redownloading failed, error out
                        modelState = .unloaded
                        return
                    }
                }

                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio + 0.9 * (1 - specializationProgressRatio)
                    modelState = .loading
                }

                try await whisperKit.loadModels()

                await MainActor.run {
                    availableLanguages = Constants.languages.map { $0.key }.sorted()
                    loadingProgressValue = 1.0
                    modelState = whisperKit.modelState
                }
            }
        }
    }

    func updateProgressBar(targetProgress: Float, maxTime: TimeInterval) async {
        let initialProgress = loadingProgressValue
        let decayConstant = -log(1 - targetProgress) / Float(maxTime)

        let startTime = Date()

        while true {
            let elapsedTime = Date().timeIntervalSince(startTime)

            // Break down the calculation
            let decayFactor = exp(-decayConstant * Float(elapsedTime))
            let progressIncrement = (1 - initialProgress) * (1 - decayFactor)
            let currentProgress = initialProgress + progressIncrement

            await MainActor.run {
                loadingProgressValue = currentProgress
            }

            if currentProgress >= targetProgress {
                break
            }

            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                break
            }
        }
    }

    func toggleRecording(shouldLoop: Bool) {
        isRecording.toggle()

        if isRecording {
            resetState()
            startRecording()
        } else {
            stopRecording()
        }
    }

    func startRecording() {
        guard let whisperKit = whisperKit else { return }
        Task(priority: .userInitiated) {
//                guard await requestMicrophoneIfNeeded() else {
//                    print("Microphone access was not granted.")
//                    return
//                }

            try? whisperKit.audioProcessor.startRecordingLive { _ in
                DispatchQueue.main.async {
                    var energyToDisplay: [EnergyValue] = []
                    for (idx, val) in whisperKit.audioProcessor.relativeEnergy.suffix(energyToDisplayCount).enumerated() {
                        energyToDisplay.append(EnergyValue(index: idx, value: val))
                    }
                    bufferEnergy = energyToDisplay
                }
            }

            // Delay the timer start by 1 second
            isRecording = true
            isTranscribing = true
            realtimeLoop()
        }
    }

    func stopRecording() {
        guard let whisperKit = whisperKit else { return }
        whisperKit.audioProcessor.stopRecording()
    }

    func tranCriptionAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }

        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = selectedTask == "tranCription" ? .transcribe : .translate
        let seekClip = [lastConfirmedSegmentEndSeconds]
        
        // "auto"の場合はnilにして自動検出を有効化
        let finalLanguage: String? = (languageCode == "auto") ? nil : languageCode

        let options = DecodingOptions(
            verbose: false,
            task: task,
            language: task == .translate ? nil : finalLanguage,  // translateの場合、またはautoの場合は言語を指定しない
            temperatureFallbackCount: 1, // limit fallbacks for realtime
            sampleLength: Int(sampleLength), // reduced sample length for realtime
            skipSpecialTokens: true,
            clipTimestamps: seekClip
        )

        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { progress in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                if progress.text.count < currentText.count {
                    if fallbacks == self.currentFallbacks {
                        self.unconfirmedText.append(currentText)
                    } else {
                        print("Fallback occured: \(fallbacks)")
                    }
                }
                self.currentText = progress.text
                self.currentFallbacks = fallbacks
            }
            // Check early stopping - より緩い設定で完全な転写を確保
            let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                // より緩い閾値で早期停止を防ぐ（デフォルト: 2.4 → 3.0）
                if compressionRatio > 3.0 {
                    return false
                }
            }
            // より緩いlogprob閾値で早期停止を防ぐ（デフォルト: -1.0 → -1.5）
            if progress.avgLogprob! < -1.5 {
                return false
            }

            return nil
        }

        let tranCription: [TranscriptionResult] = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )
        return tranCription.first
    }

    // MARK: Streaming Logic

    func realtimeLoop() {
        tranCriptionTask = Task {
            while isRecording && isTranscribing {
                do {
                    try await tranCriptionCurrentBuffer()
                } catch {
                    print("Error: \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    func tranCriptionCurrentBuffer() async throws {
        guard let whisperKit = whisperKit else { return }

        // Retrieve the current audio buffer from the audio processor
        let currentBuffer = whisperKit.audioProcessor.audioSamples

        // Calculate the size and duration of the next buffer segment
        let nextBufferSize = currentBuffer.count - lastBufferSize
        let nextBufferSeconds = Float(nextBufferSize) / Float(WhisperKit.sampleRate)

        // Only run the tranCription if the next buffer has at least 1 second of audio
        guard nextBufferSeconds > 1 else {
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
            // Only run the tranCription if the next buffer has voice
            guard voiceDetected else {
                await MainActor.run {
                    if currentText == "" {
                        currentText = "Waiting for speech..."
                    }
                }

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

        // Run tranCription
        lastBufferSize = currentBuffer.count

        let tranCription = try await tranCriptionAudioSamples(Array(currentBuffer))

        // We need to run this next part on the main thread
        await MainActor.run {
            currentText = ""
            unconfirmedText = []
            guard let segments = tranCription?.segments else {
                return
            }

//            self.tokensPerSecond = tranCription?.timings?.tokensPerSecond ?? 0
//            self.realTimeFactor = tranCription?.timings?.realTimeFactor ?? 0
//            self.firstTokenTime = tranCription?.timings?.firstTokenTime ?? 0
//            self.pipelineStart = tranCription?.timings?.pipelineStart ?? 0
//            self.currentLag = tranCription?.timings?.decodingLoop ?? 0

            // Logic for moving segments to confirmedSegments
            if segments.count > requiredSegmentsForConfirmation {
                // Calculate the number of segments to confirm
                let numberOfSegmentsToConfirm = segments.count - requiredSegmentsForConfirmation

                // Confirm the required number of segments
                let confirmedSegmentsArray = Array(segments.prefix(numberOfSegmentsToConfirm))
                let remainingSegments = Array(segments.suffix(requiredSegmentsForConfirmation))

                // Update lastConfirmedSegmentEnd based on the last confirmed segment
                if let lastConfirmedSegment = confirmedSegmentsArray.last, lastConfirmedSegment.end > lastConfirmedSegmentEndSeconds {
                    lastConfirmedSegmentEndSeconds = lastConfirmedSegment.end

                    // Add confirmed segments to the confirmedSegments array
                    if !self.confirmedSegments.contains(confirmedSegmentsArray) {
                        self.confirmedSegments.append(contentsOf: confirmedSegmentsArray)
                    }
                }

                // Update tranCriptions to reflect the remaining segments
                self.unconfirmedSegments = remainingSegments
            } else {
                // Handle the case where segments are fewer or equal to required
                self.unconfirmedSegments = segments
            }
        }
    }
}

#Preview {
    CriptionWatchView()
}
