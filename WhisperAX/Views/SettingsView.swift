//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI
import WhisperKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AVFoundation
import CoreML
import Network

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManagerNew
    @EnvironmentObject var modelManager: WhisperModelManager
    @Binding var whisperKit: WhisperKit?
    @Binding var modelState: ModelState
    @Binding var selectedModel: String
    @Binding var availableModels: [String]
    @Binding var localModels: [String]
    @Binding var localModelPath: String
    @Binding var loadingProgressValue: Float
    @Binding var showComputeUnits: Bool
    @Binding var encoderComputeUnits: MLComputeUnits
    @Binding var decoderComputeUnits: MLComputeUnits
    @Binding var selectedTask: String
    @Binding var selectedLanguage: String
    @Binding var availableLanguages: [String]
    @Binding var enableTimestamps: Bool
    @Binding var enablePromptPrefill: Bool
    @Binding var enableCachePrefill: Bool
    @Binding var enableSpecialCharacters: Bool
    @Binding var enableEagerDecoding: Bool
    @Binding var enableDecoderPreview: Bool
    @Binding var preserveTextOnRecording: Bool
    @Binding var hideIconsDuringSTT: Bool
    @Binding var temperatureStart: Double
    @Binding var enableFixedTemperature: Bool
    @Binding var fixedTemperatureValue: Double
    @Binding var fallbackCount: Double
    @Binding var compressionCheckWindow: Double
    @Binding var sampleLength: Double
    @Binding var silenceThreshold: Double
    @Binding var realtimeDelayInterval: Double
    @Binding var useVAD: Bool
    @Binding var tokenConfirmationsNeeded: Double
    @Binding var concurrentWorkerCount: Double
    @Binding var chunkingStrategy: ChunkingStrategy
    @Binding var selectedAudioInput: String
    @Binding var audioDevices: [AudioDevice]?
    @Binding var repoName: String
    @Binding var sttFontSize: Double
    @Binding var sttFontFamily: String
    @Binding var enableLineBreaks: Bool
    @Binding var lineSpacing: Double
    @Binding var waveformActionType: String
    
    let onLoadModel: (String) -> Void
    let onDeleteModel: () -> Void
    let onFetchModels: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showModelSelection = false
    @State private var showLanguageSelection = false
    @State private var showUILanguageSelection = false
    @State private var networkMonitor: NWPathMonitor?
    @State private var isNetworkAvailable = true
    @State private var wasDownloadingWhenOffline = false
    @State private var showAdvancedSettings = false
    @State private var showExperimentalSettings = false
    @State private var showFontSelection = false
    @State private var showLanguageChangeAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 24) {

                    
                    
                    // Model Settings Section
                    SettingsSection(
                        title: String(localized: LocalizedStringResource("Model Settings", comment: "Model settings section")),
                        icon: "cpu",
                        iconColor: .primary
                    ) {
                        modelSelectorView
                        computeUnitsView
                    }
                    
                    // Audio Settings Section
                    SettingsSection(
                        title: String(localized: LocalizedStringResource("Audio Settings", comment: "Audio settings section")),
                        icon: "mic",
                        iconColor: .primary
                    ) {
                        audioDevicesView
                        basicSettingsView
                        sttFontSettingsView
                    }
                    
                    // Advanced Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.2")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .frame(width: 24, height: 24)
                            
                            Text(String(localized: LocalizedStringResource("Advanced Settings", comment: "Advanced settings section")))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showAdvancedSettings.toggle()
                            } label: {
                                Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 4)
                        
                        if showAdvancedSettings {
                            VStack(spacing: 0) {
                                advancedSettingsView
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showAdvancedSettings)
                    
                    // Experimental Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "flask")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .frame(width: 24, height: 24)
                            
                            Text(String(localized: LocalizedStringResource("Experimental Settings", comment: "Experimental settings section")))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showExperimentalSettings.toggle()
                            } label: {
                                Image(systemName: showExperimentalSettings ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 4)
                        
                        if showExperimentalSettings {
                            VStack(spacing: 0) {
                                experimentalSettingsView
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showExperimentalSettings)
                    
                     // UI Language Settings Section
                    SettingsSection(
                        title: String(localized: LocalizedStringResource("Display Language", comment: "Display language setting")),
                        icon: "globe",
                        iconColor: Color(hex: "1CA485")
                    ) {
                        uiLanguageSettingsView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle(String(localized: LocalizedStringResource("Settings", comment: "Settings view title")))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            })
        }
        .sheet(isPresented: $showModelSelection) {
            NavigationView {
                ModelSelectionView(modelManager: modelManager)
            }
            .onDisappear {
                if selectedModel != modelManager.selectedModel {
                    selectedModel = modelManager.selectedModel
                    modelState = .unloaded
                }
            }
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage)
        }
        .sheet(isPresented: $showFontSelection) {
            FontSelectionView(selectedFontFamily: $sttFontFamily)
        }
        .sheet(isPresented: $showUILanguageSelection) {
            UILanguageSelectionView()
        }
        .alert(String(localized: LocalizedStringResource("Language Changed", comment: "Language changed alert title")), isPresented: $showLanguageChangeAlert) {
            Button(String(localized: LocalizedStringResource("Restart App", comment: "Restart app button"))) {
                // アプリを再起動
                exit(0)
            }
            Button(String(localized: LocalizedStringResource("Continue", comment: "Continue button")), role: .cancel) { }
        } message: {
            Text(String(localized: LocalizedStringResource("The language has been changed. Please restart the app to see the changes.", comment: "Language changed alert message")))
        }
        .onAppear {
            modelManager.selectedModel = selectedModel
            modelManager.localModels = localModels
            startNetworkMonitoring()
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
        .onChange(of: selectedModel) { _, newValue in
            modelManager.selectedModel = newValue
        }
        .onChange(of: isNetworkAvailable) { _, isAvailable in
            if isAvailable && wasDownloadingWhenOffline {
                // Network came back online and we were downloading before
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    resumeDownloadIfNeeded()
                }
            }
        }
        .onChange(of: modelState) { _, newState in
            // Track if we were downloading when going offline
            if newState == .downloading || newState == .loading {
                wasDownloadingWhenOffline = true
            } else if newState == .loaded || newState == .unloaded {
                wasDownloadingWhenOffline = false
            }
        }
        .onChange(of: languageManager.currentLanguage) { _, newLanguage in
            // Language changed, force UI refresh
            // This will trigger a re-evaluation of all localized strings
            print("Language changed to: \(newLanguage)")
            
            // アプリの再起動を促すアラートを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showLanguageChangeAlert = true
            }
        }
    }
    
    // MARK: - Language Settings
    
    var uiLanguageSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button(action: {
                    showUILanguageSelection = true
                }) {
                    HStack(spacing: 8) {
                        Text(languageManager.languageDisplayName(for: languageManager.currentLanguage))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showUILanguageSelection) {
            UILanguageSelectionView()
        }
    }
    
    
    // MARK: - Model Settings
    
    var modelSelectorView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model Status Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Status Indicator
                    ZStack {
                        Circle()
                            .fill(modelManager.modelState == .loaded ? .green : (modelManager.modelState == .unloaded ? .red : .yellow))
                            .frame(width: 12, height: 12)
                        
                        if modelManager.modelState != .loaded && modelManager.modelState != .unloaded {
                            Circle()
                                .stroke(modelManager.modelState == .loaded ? .green : (modelManager.modelState == .unloaded ? .red : .yellow), lineWidth: 2)
                                .frame(width: 16, height: 16)
                                .opacity(0.6)
                                .scaleEffect(1.2)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: modelManager.modelState)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(modelStateDescription)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                }
                
                // Model Selection Card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "cpu")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let model = WhisperModels.shared.getModel(by: selectedModel) {
                                HStack(spacing: 8) {
                                    Text(model.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                }
                            } else {
                                Text(String(localized: LocalizedStringResource("No model selected", comment: "No model selected message")))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showModelSelection = true
                        }) {
                            HStack(spacing: 4) {
                                Text(String(localized: LocalizedStringResource("Change", comment: "Change button")))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await modelManager.deleteModel(selectedModel)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text(String(localized: LocalizedStringResource("Delete", comment: "Delete button")))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .disabled(localModels.isEmpty || !localModels.contains(selectedModel) || isBundledModel(selectedModel))
                        
                        Button(action: {
                            Task {
                                await modelManager.loadModel(selectedModel, redownload: true)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text(String(localized: LocalizedStringResource("Repair", comment: "Repair button")))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .disabled(localModels.isEmpty || !localModels.contains(selectedModel) || isBundledModel(selectedModel))
                        
                        #if os(macOS)
                        Button(action: {
                            let folderURL = whisperKit?.modelFolder ?? (localModels.contains(selectedModel) ? URL(fileURLWithPath: localModelPath) : nil)
                            if let folder = folderURL {
                                NSWorkspace.shared.open(folder)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text(String(localized: LocalizedStringResource("Open Folder", comment: "Open folder button")))
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        #endif
                        
                        Button(action: {
                            if let url = URL(string: "https://huggingface.co/\(repoName)") {
                                #if os(macOS)
                                NSWorkspace.shared.open(url)
                                #else
                                UIApplication.shared.open(url)
                                #endif
                            }
                        }) {
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Load Model Button or Progress
            if modelManager.modelState != .loading && modelManager.modelState != .prewarming && modelManager.modelState != .downloading {
                Button {
                    Task {
                        await modelManager.loadModel(selectedModel)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(String(localized: LocalizedStringResource("Load Model", comment: "Load model button")))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .background(
                    Color(red: 0.0, green: 0.388, blue: 0.216) // #006337
                )
                .foregroundColor(.white)
            } else if modelManager.optimizationProgress < 1.0 {
                VStack(spacing: 12) {
                    ProgressView(value: modelManager.optimizationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .tint(Color(hex: "1CA485"))
                    
                    Text(modelManager.optimizationStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var modelStateDescription: String {
        switch modelManager.modelState {
        case .loaded:
            return String(localized: LocalizedStringResource("Loaded", comment: "Loaded state"))
        case .unloaded:
            return String(localized: LocalizedStringResource("Unloaded", comment: "Unloaded state"))
        case .loading:
            return String(localized: LocalizedStringResource("Loading", comment: "Loading state"))
        case .prewarming:
            return String(localized: LocalizedStringResource("Prewarming", comment: "Prewarming state"))
        case .unloading:
            return String(localized: LocalizedStringResource("Unloading", comment: "Unloading state"))
        case .prewarmed:
            return String(localized: LocalizedStringResource("Prewarmed", comment: "Prewarmed state"))
        case .downloading:
            return String(localized: LocalizedStringResource("Downloading", comment: "Downloading state"))
        case .downloaded:
            return String(localized: LocalizedStringResource("Downloaded", comment: "Downloaded state"))
        }
    }
    
    private var selectedModelDisplayName: String {
        if let model = WhisperModels.shared.getModel(by: selectedModel) {
            return model.displayName
        }
        return selectedModel.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
    // バンドルされたモデルかどうかをチェック
    private func isBundledModel(_ model: String) -> Bool {
        return Bundle.main.path(forResource: model, ofType: nil) != nil
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        networkMonitor?.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasOffline = !self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied
                
                // If we just came back online and were downloading before
                if wasOffline && self.isNetworkAvailable && self.wasDownloadingWhenOffline {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.resumeDownloadIfNeeded()
                    }
                }
            }
        }
        
        networkMonitor?.start(queue: queue)
    }
    
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private func resumeDownloadIfNeeded() {
        // Check if we have a partial download that needs to be resumed
        if hasPartialDownload() && (modelState == .unloaded || modelState == .downloaded) {
            print("Resuming download for \(selectedModel) after network recovery")
            onLoadModel(selectedModel)
            modelState = .downloading
        }
    }
    
    private func hasPartialDownload() -> Bool {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let modelPath = documents.appendingPathComponent("WhisperKit").appendingPathComponent(selectedModel)
        
        // Check if model directory exists but is incomplete
        if FileManager.default.fileExists(atPath: modelPath.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: modelPath.path)
                // Check if it's a partial download (has some files but not all expected files)
                let expectedFiles = ["model.mlpackage", "tokenizer.json", "vocab.json"]
                let hasSomeFiles = !contents.isEmpty
                let hasAllFiles = expectedFiles.allSatisfy { file in
                    contents.contains { $0.contains(file.replacingOccurrences(of: ".mlpackage", with: "")) }
                }
                
                return hasSomeFiles && !hasAllFiles
            } catch {
                return false
            }
        }
        
        return false
    }
    
    var computeUnitsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                Text(String(localized: LocalizedStringResource("Compute Units", comment: "Compute units setting")))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    showComputeUnits.toggle()
                } label: {
                    Image(systemName: showComputeUnits ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Compute Units Settings
            if showComputeUnits {
                VStack(spacing: 16) {
                    // Audio Encoder
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill((whisperKit?.audioEncoder as? WhisperMLModel)?.modelState == .loaded ? .green : (modelState == .unloaded ? .red : .yellow))
                                    .frame(width: 8, height: 8)
                                
                                if modelState != .loaded && modelState != .unloaded {
                                    Circle()
                                        .stroke((whisperKit?.audioEncoder as? WhisperMLModel)?.modelState == .loaded ? .green : (modelState == .unloaded ? .red : .yellow), lineWidth: 1)
                                        .frame(width: 12, height: 12)
                                        .opacity(0.6)
                                        .scaleEffect(1.2)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: modelState)
                                }
                            }
                            
                            Text(String(localized: LocalizedStringResource("Audio Encoder", comment: "Audio encoder setting")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        
                        Picker("", selection: $encoderComputeUnits) {
                            Text(String(localized: LocalizedStringResource("CPU", comment: "CPU option"))).tag(MLComputeUnits.cpuOnly)
                            Text(String(localized: LocalizedStringResource("GPU", comment: "GPU option"))).tag(MLComputeUnits.cpuAndGPU)
                            Text(String(localized: LocalizedStringResource("Neural Engine", comment: "Neural Engine option"))).tag(MLComputeUnits.cpuAndNeuralEngine)
                        }
                        .onChange(of: encoderComputeUnits, initial: false) { _, _ in
                            onLoadModel(selectedModel)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Text Decoder
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill((whisperKit?.textDecoder as? WhisperMLModel)?.modelState == .loaded ? .green : (modelState == .unloaded ? .red : .yellow))
                                    .frame(width: 8, height: 8)
                                
                                if modelState != .loaded && modelState != .unloaded {
                                    Circle()
                                        .stroke((whisperKit?.textDecoder as? WhisperMLModel)?.modelState == .loaded ? .green : (modelState == .unloaded ? .red : .yellow), lineWidth: 1)
                                        .frame(width: 12, height: 12)
                                        .opacity(0.6)
                                        .scaleEffect(1.2)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: modelState)
                                }
                            }
                            
                            Text(String(localized: LocalizedStringResource("Text Decoder", comment: "Text decoder setting")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        
                        Picker("", selection: $decoderComputeUnits) {
                            Text(String(localized: LocalizedStringResource("CPU", comment: "CPU option"))).tag(MLComputeUnits.cpuOnly)
                            Text(String(localized: LocalizedStringResource("GPU", comment: "GPU option"))).tag(MLComputeUnits.cpuAndGPU)
                            Text(String(localized: LocalizedStringResource("Neural Engine", comment: "Neural Engine option"))).tag(MLComputeUnits.cpuAndNeuralEngine)
                        }
                        .onChange(of: decoderComputeUnits, initial: false) { _, _ in
                            onLoadModel(selectedModel)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showComputeUnits)
    }
    
    // MARK: - Audio Settings
    
    var audioDevicesView: some View {
        Group {
            #if os(macOS)
            HStack {
                if let audioDevices = audioDevices, !audioDevices.isEmpty {
                    Picker("", selection: $selectedAudioInput) {
                        ForEach(audioDevices, id: \.self) { device in
                            Text(device.name).tag(device.name)
                        }
                    }
                    .frame(width: 250)
                }
            }
            .onAppear {
                audioDevices = AudioProcessor.getAudioDevices()
                if let audioDevices = audioDevices,
                   !audioDevices.isEmpty,
                   selectedAudioInput == "No Audio Input",
                   let device = audioDevices.first
                {
                    selectedAudioInput = device.name
                }
            }
            #endif
        }
    }
    
    var basicSettingsView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                
                Picker("", selection: $selectedTask) {
                    ForEach(DecodingTask.allCases, id: \.self) { task in
                        Text(task.description.capitalized).tag(task.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(!(whisperKit?.modelVariant.isMultilingual ?? false))
                
                if selectedTask == "translate" {
                    Text(String(localized: LocalizedStringResource("Translation mode converts speech to English", comment: "Translation mode description")))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                } else if selectedTask == "transcribe" {
                    Text(String(localized: LocalizedStringResource("Transcription mode preserves original language", comment: "Transcription mode description")))
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }
                
                if selectedLanguage == "auto" {
                    Text(String(localized: LocalizedStringResource("Auto-detect language from audio content", comment: "Auto-detect language description")))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: LocalizedStringResource("Source Language", comment: "Source language setting")))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showLanguageSelection = true
                    }) {
                        HStack(spacing: 8) {
                            Text(selectedLanguage.isEmpty ? String(localized: LocalizedStringResource("Select Language", comment: "Select language button")) : languageManager.languageDisplayName(for: selectedLanguage))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Wave from Icon Action Setting
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: LocalizedStringResource("Wave form Icon Action", comment: "Wave form icon action setting")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $waveformActionType) {
                    Text(String(localized: LocalizedStringResource("Clear Text", comment: "Clear text option"))).tag("clear")
                    Text(String(localized: LocalizedStringResource("Show ASCII Art", comment: "Show ASCII art option"))).tag("ascii")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding(.vertical, 8)
    }
    
    var sttFontSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Font Family Selection
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: LocalizedStringResource("Text Font Type", comment: "Text font type setting")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    showFontSelection = true
                }) {
                    HStack(spacing: 8) {
                        Text(FontFamily.fontFamily(named: sttFontFamily)?.displayName ?? String(localized: LocalizedStringResource("System", comment: "System font option")))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Font Size Slider
            SliderSettingRow(
                title: String(localized: "Text Font Size"),
                value: $sttFontSize,
                range: 7...100,
                step: 1,
                displayValue: sttFontSize.formatted(.number),
                infoText: "Adjust font size for text display. Larger values make text more readable."
            )
            
            // Line Break Settings
            ToggleSettingRow(
                title: NSLocalizedString("line.breaks.punctuation", comment: "Setting for enabling line breaks after punctuation marks"),
                isOn: $enableLineBreaks,
                infoText: NSLocalizedString("line.breaks.punctuation.info", comment: "Information text explaining line breaks on punctuation setting")
            )
            
            // Line Spacing Slider (only show when line breaks are enabled)
            if enableLineBreaks {
                SliderSettingRow(
                    title: NSLocalizedString("line.spacing", comment: "Setting for controlling line spacing when line breaks are enabled"),
                    value: $lineSpacing,
                    range: 0...20,
                    step: 1,
                    displayValue: lineSpacing.formatted(.number),
                    infoText: NSLocalizedString("line.spacing.info", comment: "Information text explaining line spacing setting")
                )
            }
            
            // Font Preview
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Preview"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text(String(localized: "Sample text preview"))
                    .font(FontFamily.fontFamily(named: sttFontFamily)?.font(withSize: sttFontSize) ?? .system(size: sttFontSize))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Advanced Settings
    
    var advancedSettingsView: some View {
        VStack(spacing: 16) {
            // Toggle Settings
            VStack(spacing: 12) {
                ToggleSettingRow(
                    title: String(localized: "Show Timestamps"),
                    isOn: $enableTimestamps,
                    infoText: "Toggling this will include/exclude timestamps in both the UI and the prefill tokens.\nEither <|notimestamps|> or <|0.00|> will be forced based on this setting unless \"Prompt Prefill\" is de-selected."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Special Characters"),
                    isOn: $enableSpecialCharacters,
                    infoText: "Toggling this will include/exclude special characters in the transcription text."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Show Decoder Preview"),
                    isOn: $enableDecoderPreview,
                    infoText: "Toggling this will show a small preview of the decoder output in the UI under the transcribe. This can be useful for debugging."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Hide Icons During Transcription"),
                    isOn: $hideIconsDuringSTT,
                    infoText: "When enabled, all UI icons and buttons will be hidden during speech-to-text recording and transcription, allowing the text to fill the entire screen for better readability. You can tap the screen during STT to temporarily show icons."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Prompt Prefill"),
                    isOn: $enablePromptPrefill,
                    infoText: "When Prompt Prefill is on, it will force the task, language, and timestamp tokens in the decoding loop. \nToggle it off if you'd like the model to generate those tokens itself instead."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Cache Prefill"),
                    isOn: $enableCachePrefill,
                    infoText: "When Cache Prefill is on, the decoder will try to use a lookup table of pre-computed KV caches instead of computing them during the decoding loop. \nThis allows the model to skip the compute required to force the initial prefill tokens, and can speed up inference"
                )
            }
            
            // Slider Settings
            VStack(spacing: 16) {
                SliderSettingRow(
                    title: String(localized: "Chunking Strategy"),
                    value: Binding(
                        get: { chunkingStrategy == .vad ? 1.0 : 0.0 },
                        set: { chunkingStrategy = $0 > 0.5 ? .vad : .none }
                    ),
                    range: 0...1,
                    step: 1,
                    displayValue: chunkingStrategy == .vad ? String(localized: "VAD") : String(localized: "None"),
                    infoText: "Select the strategy to use for chunking audio data. If VAD is selected, the audio will be chunked based on voice activity (split on silent portions)."
                )
                
                SliderSettingRow(
                    title: String(localized: "Workers"),
                    value: $concurrentWorkerCount,
                    range: 0...32,
                    step: 1,
                    displayValue: concurrentWorkerCount.formatted(.number),
                    infoText: "How many workers to run transcription concurrently. Higher values increase memory usage but saturate the selected compute unit more, resulting in faster transcriptions. A value of 0 will use unlimited workers."
                )
                
                ToggleSettingRow(
                    title: String(localized: "Fixed Temperature"),
                    isOn: $enableFixedTemperature,
                    infoText: "Use a fixed temperature value of 0.0 for consistent transcription results.\nThis reduces text variations during recording."
                )
                
                if enableFixedTemperature {
                    SliderSettingRow(
                        title: String(localized: "Temperature Value"),
                        value: $fixedTemperatureValue,
                        range: 0...1,
                        step: 0.1,
                        displayValue: fixedTemperatureValue.formatted(.number),
                        infoText: "Fixed temperature value for consistent transcription.\nLower values provide more stable results."
                    )
                }
                
                SliderSettingRow(
                    title: String(localized: "Max Fallback Count"),
                    value: $fallbackCount,
                    range: 0...5,
                    step: 1,
                    displayValue: fallbackCount.formatted(.number),
                    infoText: "Controls how many times the decoder will fallback to a higher temperature if any of the decoding thresholds are exceeded.\n Higher values will cause the decoder to run multiple times on the same audio, which can improve accuracy at the cost of speed."
                )
                
                SliderSettingRow(
                    title: String(localized: "Compression Check Tokens"),
                    value: $compressionCheckWindow,
                    range: 0...100,
                    step: 5,
                    displayValue: compressionCheckWindow.formatted(.number),
                    infoText: "Amount of tokens to use when checking for whether the model is stuck in a repetition loop.\nRepetition is checked by using zlib compressed size of the text compared to non-compressed value.\n Lower values will catch repetitions sooner, but too low will miss repetition loops of phrases longer than the window."
                )
                
                SliderSettingRow(
                    title: String(localized: "Max Tokens Per Loop"),
                    value: $sampleLength,
                    range: 0...Double(min(whisperKit?.textDecoder.kvCacheMaxSequenceLength ?? Constants.maxTokenContext, Constants.maxTokenContext)),
                    step: 10,
                    displayValue: sampleLength.formatted(.number),
                    infoText: "Maximum number of tokens to generate per loop.\nCan be lowered based on the type of speech in order to further prevent repetition loops from going too long."
                )
                
                SliderSettingRow(
                    title: String(localized: "Silence Threshold"),
                    value: $silenceThreshold,
                    range: 0...1,
                    step: 0.05,
                    displayValue: silenceThreshold.formatted(.number),
                    infoText: "Relative silence threshold for the audio. \n Baseline is set by the quietest 100ms in the previous 2 seconds."
                )
                
                SliderSettingRow(
                    title: String(localized: "Realtime Delay Interval"),
                    value: $realtimeDelayInterval,
                    range: 0...30,
                    step: 1,
                    displayValue: realtimeDelayInterval.formatted(.number),
                    infoText: "Controls how long to wait for audio buffer to fill before running successive loops in streaming mode.\nHigher values will reduce the number of loops run per second, saving battery at the cost of higher latency."
                )
                
                ToggleSettingRow(
                    title: "Voice Activity Detection (VAD)",
                    isOn: $useVAD,
                    infoText: "When VAD is enabled, the app will only transcribe audio when speech is detected, reducing processing and improving battery life."
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Experimental Settings
    
    var experimentalSettingsView: some View {
        VStack(spacing: 16) {
            ToggleSettingRow(
                title: String(localized: "Eager Streaming Mode"),
                isOn: $enableEagerDecoding,
                infoText: "When Eager Streaming Mode is on, the transcription will be updated more frequently, but with potentially less accurate results."
            )
            
            SliderSettingRow(
                title: String(localized: "Token Confirmations"),
                value: $tokenConfirmationsNeeded,
                range: 1...10,
                step: 1,
                displayValue: tokenConfirmationsNeeded.formatted(.number),
                infoText: "Controls the number of consecutive tokens required to agree between decoder loops before considering them as confirmed in the streaming process."
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Components
    
    struct SettingsSection<Content: View>: View {
        let title: String
        let icon: String
        let iconColor: Color
        let content: Content
        
        init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
            self.title = title
            self.icon = icon
            self.iconColor = iconColor
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    struct ToggleSettingRow: View {
        let title: String
        @Binding var isOn: Bool
        let infoText: String
        @State private var showInfo = false
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfo) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(infoText)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: 300)
                }
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
    
    struct SliderSettingRow: View {
        let title: String
        @Binding var value: Double
        let range: ClosedRange<Double>
        let step: Double
        let displayValue: String
        let infoText: String
        @State private var showInfo = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showInfo) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(infoText)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: 300)
                    }
                }
                
                HStack(spacing: 12) {
                    Slider(value: $value, in: range, step: step)
                        .frame(maxWidth: .infinity)
                        .tint(.primary)
                    
                    Text(displayValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
    
    struct InfoButton: View {
        var infoText: String
        @State private var showInfo = false

        init(_ infoText: String) {
            self.infoText = infoText
        }

        var body: some View {
            Button(action: {
                showInfo = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(hex: "1CA485"))
            }
            .popover(isPresented: $showInfo) {
                Text(infoText)
                    .padding()
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

// MARK: - Model Selection View
struct ModelSelectionView: View {
    @ObservedObject var modelManager: WhisperModelManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ModelCategory? = nil
    @State private var showRecommendedOnly = false
    
    var filteredModels: [WhisperModel] {
        var models = WhisperModels.shared.allModels
        
        // Filter by category
        if let category = selectedCategory {
            models = models.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            models = models.filter { model in
                model.displayName.localizedCaseInsensitiveContains(searchText) ||
                model.id.localizedCaseInsensitiveContains(searchText) ||
                model.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by recommended only
        if showRecommendedOnly {
            let recommendedIds = Set(WhisperModels.shared.getRecommendedModels().map { $0.id })
            models = models.filter { recommendedIds.contains($0.id) }
        }
        
        return models
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterControls
                Divider()
                modelsList
            }
            .navigationTitle(String(localized: "Select Model"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            })
        }
    }
    
    private var searchAndFilterControls: some View {
        VStack(spacing: 12) {
            TextField(String(localized: "Search models..."), text: $searchText)
                .textFieldStyle(.roundedBorder)
            
            categoryFilter
            recommendedToggle
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(String(localized: "All")) {
                    selectedCategory = nil
                }
                .buttonStyle(.bordered)
                .foregroundColor(selectedCategory == nil ? .white : .primary)
                .background(selectedCategory == nil ? Color.accentColor : Color.clear)
                
                ForEach(ModelCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        selectedCategory = category
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(selectedCategory == category ? .white : .primary)
                    .background(selectedCategory == category ? Color.accentColor : Color.clear)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var recommendedToggle: some View {
        HStack {
            Toggle(String(localized: "Show Recommended Only"), isOn: $showRecommendedOnly)
                .toggleStyle(SwitchToggleStyle())
            Spacer()
        }
    }
    
    private var modelsList: some View {
        List {
            ForEach(filteredModels, id: \.id) { model in
                ModelRowView(
                    model: model,
                    isSelected: model.id == modelManager.selectedModel,
                    onTap: {
                        modelManager.selectedModel = model.id
                        dismiss()
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Model Row View
struct ModelRowView: View {
    let model: WhisperModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(model.size)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(model.languages)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        if let quantization = model.quantization {
                            Text(quantization.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "1CA485").opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        ForEach(model.specialFeatures, id: \.self) { feature in
                            Text(feature.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Language Search View
struct LanguageSearchView: View {
    let availableLanguages: [String]
    @Binding var selectedLanguage: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    
    var filteredLanguages: [String] {
        if searchText.isEmpty {
            return availableLanguages
        } else {
            return availableLanguages.filter { language in
                language.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            languageList
        }
            .navigationTitle(String(localized: "Select Language"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "Done")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(String(localized: "Search languages..."), text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }
    
    private var languageList: some View {
        List {
            ForEach(filteredLanguages, id: \.self) { language in
                languageRow(for: language)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func languageRow(for language: String) -> some View {
        Button(action: {
            selectedLanguage = language
            dismiss()
        }) {
            HStack {
                Text(language.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedLanguage == language {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Font Selection View
struct FontSelectionView: View {
    @Binding var selectedFontFamily: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredFonts: [FontFamily] {
        if searchText.isEmpty {
            return FontFamily.availableFonts
        } else {
            return FontFamily.availableFonts.filter { font in
                font.displayName.localizedCaseInsensitiveContains(searchText) ||
                font.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                Divider()
                fontsList
            }
            .navigationTitle(String(localized: "Select Font"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(String(localized: "Search fonts..."), text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }
    
    private var fontsList: some View {
        List {
            ForEach(filteredFonts, id: \.name) { font in
                fontRow(for: font)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func fontRow(for font: FontFamily) -> some View {
        Button(action: {
            selectedFontFamily = font.name
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(String(localized: "Sample text"))
                        .font(font.font(withSize: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedFontFamily == font.name {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

//初期値を設定

#Preview {
    SettingsView(
        whisperKit: .constant(nil),
        modelState: .constant(.unloaded),
        selectedModel: .constant("whisperkit-base"),
        availableModels: .constant(["whisperkit-base"]),
        localModels: .constant([]),
        localModelPath: .constant(""),
        loadingProgressValue: .constant(0.0),
        showComputeUnits: .constant(false),
        encoderComputeUnits: .constant(.cpuAndNeuralEngine),
        decoderComputeUnits: .constant(.cpuAndNeuralEngine),
        selectedTask: .constant("transcribe"),
        selectedLanguage: .constant("english"),
        availableLanguages: .constant(["english", "japanese"]),
        enableTimestamps: .constant(false),
        enablePromptPrefill: .constant(false),
        enableCachePrefill: .constant(false),
        enableSpecialCharacters: .constant(false),
        enableEagerDecoding: .constant(false),
        enableDecoderPreview: .constant(false),
        preserveTextOnRecording: .constant(true),
        hideIconsDuringSTT: .constant(false),
        temperatureStart: .constant(0.0),
        enableFixedTemperature: .constant(false),
        fixedTemperatureValue: .constant(0.0),
        fallbackCount: .constant(5.0),
        compressionCheckWindow: .constant(60.0),
        sampleLength: .constant(224.0),
        silenceThreshold: .constant(0.3),
        realtimeDelayInterval: .constant(1.0),
        useVAD: .constant(true),
        tokenConfirmationsNeeded: .constant(2.0),
        concurrentWorkerCount: .constant(4.0),
        chunkingStrategy: .constant(.vad),
        selectedAudioInput: .constant("No Audio Input"),
        audioDevices: .constant(nil),
        repoName: .constant("argmaxinc/whisperkit-coreml"),
        sttFontSize: .constant(16.0),
        sttFontFamily: .constant("System"),
        enableLineBreaks: .constant(true),
        lineSpacing: .constant(8.0),
        waveformActionType: .constant("clear"),
        onLoadModel: { _ in },
        onDeleteModel: { },
        onFetchModels: { }
    )
}

// MARK: - UI Language Selection View
struct UILanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManagerNew
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredLanguages: [String] {
        let languages = languageManager.availableLanguages()
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { language in
                let displayName = languageManager.languageDisplayName(for: language)
                return displayName.localizedCaseInsensitiveContains(searchText) ||
                       language.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                Divider()
                languageList
            }
            .navigationTitle(String(localized: "Select UI Language"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: LocalizedStringResource("Done", comment: "Done button"))) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(String(localized: "Search languages..."), text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .padding()
    }
    
    private var languageList: some View {
        List {
            ForEach(filteredLanguages, id: \.self) { language in
                languageRow(for: language)
            }
        }
    }
    
    private func languageRow(for language: String) -> some View {
        Button(action: {
            languageManager.setLanguage(language)
            // UIの即座更新のため、少し遅延してからdismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.languageDisplayName(for: language))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if language == languageManager.currentLanguage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

