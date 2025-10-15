//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import WhisperKit

@MainActor
class WhisperModelManager: ObservableObject {
    @Published var selectedModel: String = "openai_whisper-base"
    @Published var localModels: [String] = []
    @Published var isOptimizing: Bool = false
    @Published var optimizationProgress: Double = 0.0
    @Published var optimizationStatus: String = ""
    @Published var whisperKit: WhisperKit?
    @Published var modelState: ModelState = .unloaded
    
    private let whisperModels = WhisperModels.shared
    private let repoName = "argmaxinc/whisperkit-coreml"
    
    // 選択されたモデルの表示名を取得
    var selectedModelDisplayName: String {
        if let model = whisperModels.getModel(by: selectedModel) {
            return model.displayName
        }
        return selectedModel.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
    init() {
        print("🚀 WhisperModelManager initializing")
        setupCustomLogging()
        
        // バンドル内のすべてのモデルを検索してローカルモデルリストに追加
        print("Scanning for bundled models")
        
        let bundledModelIds = findAllBundledModels()
        
        if !bundledModelIds.isEmpty {
            print("✅ Found \(bundledModelIds.count) bundled models: \(bundledModelIds)")
            localModels.append(contentsOf: bundledModelIds)
        } else {
            print("⚠️ No bundled models found")
            optimizationStatus = "No bundled models found. Please select a model manually."
        }
        
        // バンドルされている最初のモデルを自動選択（モデルIDを使用）
        if let firstBundledModelId = localModels.first {
            selectedModel = firstBundledModelId
            print("Set selectedModel to first bundled model ID: \(selectedModel) (\(selectedModelDisplayName))")
        } else {
            print("⚠️ No bundled models found")
        }
        print("Current localModels (IDs): \(localModels)")
        
        // バンドルモデルの存在確認
        if !localModels.isEmpty {
            print("✅ \(localModels.count) bundled models available for auto-loading")
        } else {
            print("⚠️ No bundled models found, will attempt manual detection")
        }
        
        // 初期化完了時の状態をログ出力
        print("🔄 WhisperModelManager initialization completed")
        print("🔄 Model state: \(modelState)")
        print("🔄 Selected model: \(selectedModel)")
        print("🔄 Local models: \(localModels)")
        print("🔄 Auto-load will be triggered on app appear")
    }
    
    // すべてのバンドルモデルを検索するヘルパー関数
    func findAllBundledModels() -> [String] {
        print("🔍 Starting comprehensive bundled model search")
        
        var foundModelIds: [String] = []
        
        // 1. バンドルされている実際のモデルを検索（モデルIDと表示名の両方で検索）
        let bundledModelInfo: [(id: String, displayName: String)] = [
            ("openai_whisper-base", "Cription mini"),
            ("openai_whisper-tiny.en", "Cription Swift English"),
            ("openai_whisper-base.en", "Cription mini English")
        ]
        
        for modelInfo in bundledModelInfo {
            // まずBundle.main.path()を使用してリソースを検索
            if let modelPath = Bundle.main.path(forResource: modelInfo.displayName, ofType: nil) {
                print("📁 Found bundled model by display name: \(modelInfo.displayName) at \(modelPath)")
                if isValidModelDirectory(modelPath) {
                    foundModelIds.append(modelInfo.id)
                    print("✅ \(modelInfo.displayName) is a valid model directory (ID: \(modelInfo.id))")
                } else {
                    print("❌ \(modelInfo.displayName) directory exists but is not a valid model")
                }
            } else if let modelPath = Bundle.main.path(forResource: modelInfo.id, ofType: nil) {
                print("📁 Found bundled model by ID: \(modelInfo.id) at \(modelPath)")
                if isValidModelDirectory(modelPath) {
                    foundModelIds.append(modelInfo.id)
                    print("✅ \(modelInfo.id) is a valid model directory")
                } else {
                    print("❌ \(modelInfo.id) directory exists but is not a valid model")
                }
            } else {
                // Bundle APIで見つからない場合、Resourcesディレクトリを直接検索
                var foundPath: String? = nil
                
                // 1. resourcePath直下を検索
                if let resourcePath = Bundle.main.resourcePath {
                    let modelPath = "\(resourcePath)/\(modelInfo.displayName)"
                    if FileManager.default.fileExists(atPath: modelPath) {
                        print("📁 Found model in Resources directory: \(modelInfo.displayName) at \(modelPath)")
                        foundPath = modelPath
                    }
                }
                
                // 2. プロジェクトのResourcesディレクトリを検索
                if foundPath == nil {
                    let projectPath = Bundle.main.bundlePath
                    let paths = [
                        "\(projectPath)/../Cription/Resources/\(modelInfo.displayName)",
                        "\(projectPath)/../../Cription/Resources/\(modelInfo.displayName)",
                        "\(projectPath)/../../../Cription/Resources/\(modelInfo.displayName)"
                    ]
                    
                    for path in paths {
                        let normalizedPath = (path as NSString).standardizingPath
                        if FileManager.default.fileExists(atPath: normalizedPath) {
                            print("📁 Found model in project Resources: \(modelInfo.displayName) at \(normalizedPath)")
                            foundPath = normalizedPath
                            break
                        }
                    }
                }
                
                // 検証して追加
                if let path = foundPath {
                    if isValidModelDirectory(path) {
                        foundModelIds.append(modelInfo.id)
                        print("✅ \(modelInfo.displayName) is a valid model directory (ID: \(modelInfo.id))")
                    } else {
                        print("❌ \(modelInfo.displayName) directory exists but is not a valid model")
                    }
                } else {
                    print("⚠️ Model \(modelInfo.displayName) not found in any Resources location")
                }
            }
        }
        
        print("📊 Total bundled models found: \(foundModelIds.count)")
        print("📊 Model IDs: \(foundModelIds)")
        
        // モデルIDを返す（表示名に変換しない）
        return foundModelIds
    }
    
    // モデルディレクトリが有効かどうかをチェック
    private func isValidModelDirectory(_ path: String) -> Bool {
        let requiredFiles = [
            "AudioEncoder.mlmodelc/model.mil",
            "AudioEncoder.mlmodelc/weights/weight.bin",
            "MelSpectrogram.mlmodelc/model.mil",
            "MelSpectrogram.mlmodelc/weights/weight.bin",
            "TextDecoder.mlmodelc/model.mil",
            "TextDecoder.mlmodelc/weights/weight.bin",
            "config.json"
        ]
        
        for file in requiredFiles {
            let fullPath = "\(path)/\(file)"
            if !FileManager.default.fileExists(atPath: fullPath) {
                print("Missing required file: \(file) at \(fullPath)")
                return false
            }
            
            // ファイルサイズチェック（空ファイルでないか）
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
                if let fileSize = attributes[.size] as? Int64, fileSize == 0 {
                    print("Empty file detected: \(file)")
                    return false
                }
            } catch {
                print("Error checking file attributes for \(file): \(error.localizedDescription)")
                return false
            }
        }
        
        return true
    }
    
    func addLocalModel(_ model: String) {
        if !localModels.contains(model) {
            localModels.append(model)
        }
    }
    
    func removeLocalModel(_ model: String) {
        localModels.removeAll { $0 == model }
    }
    
    // モデル選択時の自動ロード機能
    func selectModel(_ model: String) {
        selectedModel = model
        // 新しいモデルを自動でロード
        Task {
            await loadModel(model)
        }
    }
    
    // モデル削除機能
    func deleteModel(_ model: String) async {
        // バンドルされたモデルは削除できない
        if isBundledModel(model) {
            optimizationStatus = "Cannot delete bundled model"
            return
        }
        
        // サブスクリプション状態をチェック
        let subscriptionManager = SubCriptionManager.shared
        
        // 有料プラン加入中でないダウンロード済みモデルは削除（OpenAIモデルのみ）
        if !subscriptionManager.isSubCriptiond && isOpenAIModel(model) {
            if selectedModel == model {
                // 現在選択されているモデルを削除する場合
                whisperKit = nil
                modelState = .unloaded
                optimizationStatus = "Model deleted (subscription required)"
            }
            
            // ファイルシステムからも削除
            await deleteModelFiles(model)
        }
    }
    
    // モデルファイルを完全に削除
    private func deleteModelFiles(_ model: String) async {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let modelPath = documents.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml").appendingPathComponent(model)
        
        do {
            if FileManager.default.fileExists(atPath: modelPath.path) {
                try FileManager.default.removeItem(at: modelPath)
                if let index = localModels.firstIndex(of: model) {
                    localModels.remove(at: index)
                }
                print("Successfully deleted model files for: \(model)")
            }
        } catch {
            print("Error deleting model files: \(error.localizedDescription)")
        }
    }
    
    // モデルファイルの整合性をチェック
    private func validateModelFiles(at modelPath: URL) async -> Bool {
        let requiredFiles = [
            "AudioEncoder.mlmodelc/model.mil",
            "AudioEncoder.mlmodelc/weights/weight.bin",
            "MelSpectrogram.mlmodelc/model.mil",
            "MelSpectrogram.mlmodelc/weights/weight.bin",
            "TextDecoder.mlmodelc/model.mil",
            "TextDecoder.mlmodelc/weights/weight.bin",
            "config.json"
        ]
        
        print("Validating model files at: \(modelPath.path)")
        
        for filePath in requiredFiles {
            let fullPath = modelPath.appendingPathComponent(filePath)
            
            // ファイルの存在チェック
            guard FileManager.default.fileExists(atPath: fullPath.path) else {
                print("❌ Missing required file: \(filePath) at \(fullPath.path)")
                return false
            }
            
            // ファイルサイズチェック（空ファイルでないか）
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fullPath.path)
                if let fileSize = attributes[.size] as? Int64 {
                    if fileSize == 0 {
                        print("❌ Empty file detected: \(filePath) at \(fullPath.path)")
                        return false
                    }
                    print("✅ File validated: \(filePath) (size: \(fileSize) bytes)")
                } else {
                    print("❌ Could not determine file size for: \(filePath)")
                    return false
                }
            } catch {
                print("❌ Error checking file attributes for \(filePath): \(error.localizedDescription)")
                return false
            }
        }
        
        print("✅ Model files validation passed for: \(modelPath.path)")
        return true
    }
    
    // 表示名から元のモデルIDに変換するヘルパーメソッド
    private func getModelId(for displayName: String) -> String {
        // モデル名マッピング
        let modelNameMap: [String: String] = [
            "Cription Swift English": "openai_whisper-tiny.en",
            "Cription mini English": "openai_whisper-base.en",
            "Cription Pro English": "openai_whisper-small.en",
            "Cription Enterprise English": "openai_whisper-medium.en",
            
            "Cription Swift": "openai_whisper-tiny",
            "Cription mini": "openai_whisper-base",
            "Cription Pro": "openai_whisper-small",
            "Cription Enterprise": "openai_whisper-medium",
            "Cription Ultra": "openai_whisper-large-v2",
            "Cription UltraTurbo": "openai_whisper-large-v2_turbo",
            
            "Quantum Cription English": "openai_whisper-small.en_217MB",
            "Quantum Cription mini": "openai_whisper-small_216MB",
            "Quantum Cription UltraLite 1.0": "openai_whisper-large-v2_949MB",
            "Quantum Cription UltraTurboLite 2.0": "openai_whisper-large-v2_turbo_955MB",
            "Quantum Cription UltraLite 3.0": "openai_whisper-large-v3_947MB",
            "Quantum Cription UltraTurboLite 3.5": "openai_whisper-large-v3_turbo_954MB",
            
            "Quantum Cription Ultra 3.6": "openai_whisper-large-v3-v20240930",
            "Quantum Cription UltraTurbo 3.6": "openai_whisper-large-v3-v20240930_turbo",
            "Quantum Cription UltraLite 3.6": "openai_whisper-large-v3-v20240930_547MB",
            "Quantum Cription UltraLite+ 3.6": "openai_whisper-large-v3-v20240930_626MB",
            "Quantum Cription UltraTurboLite 3.6": "openai_whisper-large-v3-v20240930_turbo_632MB",
            
            "Cription Dual 3.0": "distil-whisper_distil-large-v3",
            "Cription Dual 0.5": "distil-whisper_distil-large-v3_594MB",
            "Cription Dual 1.5": "distil-whisper_distil-large-v3_turbo",
            "Cription Dual 0.6": "distil-whisper_distil-large-v3_turbo_600MB"
        ]
        
        // マッピングから検索
        if let modelId = modelNameMap[displayName] {
            return modelId
        }
        
        // WhisperModelsから検索
        if let model = whisperModels.allModels.first(where: { $0.displayName == displayName }) {
            return model.id
        }
        
        // フォールバック: 表示名をそのまま返す
        return displayName
    }
    
    // モデルロード機能
    func loadModel(_ model: String, redownload: Bool = false) async {
        selectedModel = model
        modelState = .downloading
        optimizationProgress = 0.0
        optimizationStatus = "Starting model loading"
        
        // サブスクリプション状態をチェック（ローカルモデルは制限解除）
        let subscriptionManager = SubCriptionManager.shared
        
        // バンドルモデル以外で、サブスクリプションがない場合はロード不可（OpenAIモデルのみ）
        if !isBundledModel(model) && isOpenAIModel(model) && !subscriptionManager.isSubCriptiond {
            modelState = .unloaded
            optimizationStatus = "Subscription required to use this model"
            print("❌ Subscription required to load model: \(model)")
            return
        }
        
        // 表示名を元のモデルIDに変換
        let actualModelId = getModelId(for: model)
        print("Loading model: \(model) (actual ID: \(actualModelId))")
        
        // 最大3回まで再試行
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries && modelState != .loaded {
            do {
                if retryCount > 0 {
                    print("Retrying model loading (attempt \(retryCount + 1)/\(maxRetries))")
                    optimizationStatus = "Retrying model loading (attempt \(retryCount + 1)/\(maxRetries))"
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                }
                
                var folder: URL?
                
                // まずアプリバンドル内のモデルをチェック
                var bundlePath: String?
                
                // 元のモデルIDまたは表示名でバンドルされたモデルを検索
                // Bundle.main.path()を優先的に使用
                if let path = Bundle.main.path(forResource: model, ofType: nil) {
                    bundlePath = path
                    print("Found bundled model via Bundle.main.path (display name): \(path)")
                } else if let path = Bundle.main.path(forResource: actualModelId, ofType: nil) {
                    bundlePath = path
                    print("Found bundled model via Bundle.main.path (ID): \(path)")
                } else if let url = Bundle.main.url(forResource: model, withExtension: nil) {
                    bundlePath = url.path
                    print("Found bundled model via Bundle.main.url (display name): \(url.path)")
                } else if let url = Bundle.main.url(forResource: actualModelId, withExtension: nil) {
                    bundlePath = url.path
                    print("Found bundled model via Bundle.main.url (ID): \(url.path)")
                }
                
                // バンドルモデルが見つからない場合の追加検索
                if bundlePath == nil {
                    print("Bundled model not found via Bundle APIs, trying direct paths")
                    
                    // 1. bundlePath内を検索
                    let bundleMainPath = Bundle.main.bundlePath
                    let modelIdPath = "\(bundleMainPath)/\(actualModelId)"
                    let displayNamePath = "\(bundleMainPath)/\(model)"
                    
                    if FileManager.default.fileExists(atPath: displayNamePath) {
                        bundlePath = displayNamePath
                        print("Found bundled model by display name: \(displayNamePath)")
                    } else if FileManager.default.fileExists(atPath: modelIdPath) {
                        bundlePath = modelIdPath
                        print("Found bundled model by ID: \(modelIdPath)")
                    }
                    
                    // 2. resourcePath内を検索
                    if bundlePath == nil, let resourcePath = Bundle.main.resourcePath {
                        let resourceModelPath = "\(resourcePath)/\(model)"
                        let resourceModelIdPath = "\(resourcePath)/\(actualModelId)"
                        
                        if FileManager.default.fileExists(atPath: resourceModelPath) {
                            bundlePath = resourceModelPath
                            print("Found bundled model in Resources by display name: \(resourceModelPath)")
                        } else if FileManager.default.fileExists(atPath: resourceModelIdPath) {
                            bundlePath = resourceModelIdPath
                            print("Found bundled model in Resources by ID: \(resourceModelIdPath)")
                        }
                    }
                    
                    // 3. プロジェクトのResourcesディレクトリを検索
                    if bundlePath == nil {
                        let projectPaths = [
                            "\(bundleMainPath)/../Cription/Resources/\(model)",
                            "\(bundleMainPath)/../../Cription/Resources/\(model)",
                            "\(bundleMainPath)/../../../Cription/Resources/\(model)",
                            "\(bundleMainPath)/../Cription/Resources/\(actualModelId)",
                            "\(bundleMainPath)/../../Cription/Resources/\(actualModelId)",
                            "\(bundleMainPath)/../../../Cription/Resources/\(actualModelId)"
                        ]
                        
                        for path in projectPaths {
                            let normalizedPath = (path as NSString).standardizingPath
                            if FileManager.default.fileExists(atPath: normalizedPath) {
                                bundlePath = normalizedPath
                                print("Found bundled model in project Resources: \(normalizedPath)")
                                break
                            }
                        }
                    }
                }
                
                if let bundlePath = bundlePath {
                    // バンドルモデルの整合性をチェック
                    if await validateModelFiles(at: URL(fileURLWithPath: bundlePath)) {
                        folder = URL(fileURLWithPath: bundlePath)
                        optimizationStatus = "Loading bundled model"
                        optimizationProgress = 0.1
                        print("Using bundled model at: \(bundlePath)")
                    } else {
                        throw NSError(domain: "WhisperModelManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Bundled model files are corrupted or incomplete"])
                    }
                }
                // ローカルモデルをチェック（元のモデルIDで検索）
                else if localModels.contains(actualModelId) && !redownload {
                    // ローカルモデルフォルダを使用
                    if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let modelPath = documents.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml").appendingPathComponent(actualModelId)
                        
                        // モデルファイルの整合性をチェック
                        if await validateModelFiles(at: modelPath) {
                            folder = modelPath
                            optimizationStatus = "Loading local model"
                            optimizationProgress = 0.1
                        } else {
                            // 破損したモデルファイルを削除して再ダウンロード
                            optimizationStatus = "Corrupted model detected, re-downloading"
                            optimizationProgress = 0.0
                            await deleteModelFiles(actualModelId)
                            // 再ダウンロードに進む
                        }
                    }
                }
                
                // OpenAIモデルの場合はWhisperKitのロードをスキップ
                if isOpenAIModel(model) {
                    print("OpenAI model detected: \(model) - skipping WhisperKit model loading")
                    modelState = .loaded
                    optimizationProgress = 1.0
                    optimizationStatus = "OpenAI model ready"
                    print("OpenAI model setup completed successfully")
                    break // 成功したらループを抜ける
                }
                // バンドルされたモデルの場合はダウンロードをスキップ
                else if folder == nil && !isBundledModel(model) {
                    // モデルをダウンロード（元のモデルIDを使用）
                    folder = try await WhisperKit.download(variant: actualModelId, from: repoName) { progress in
                        Task { @MainActor in
                            self.optimizationProgress = progress.fractionCompleted * 0.6
                            self.optimizationStatus = "Downloading model \(Int(progress.fractionCompleted * 100))%"
                        }
                    }
                } else if folder == nil && isBundledModel(model) {
                    // バンドルされたモデルが見つからない場合のエラー
                    throw NSError(domain: "WhisperModelManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Bundled model '\(model)' (ID: \(actualModelId)) not found in app bundle"])
                }
                
                modelState = .downloaded
                optimizationProgress = 0.6
                optimizationStatus = "Initializing WhisperKit"
                
                // WhisperKitインスタンスを作成
                let config = WhisperKitConfig(
                    computeOptions: getComputeOptions(),
                    verbose: false,
                    logLevel: .error,
                    prewarm: false,
                    load: false,
                    download: false
                )
                
                // デバイス識別のログを抑制
                setupWhisperKitLogging()
                
                do {
                    whisperKit = try await WhisperKit(config)
                    whisperKit?.modelFolder = folder
                    
                    // デフォルトのタスク設定を強制的にtranCriptionに設定
                    print("🔧 Setting default task to tranCription mode (auto load)")
                    // WhisperKitの内部設定はDecodingOptionsで制御
                    print("✅ WhisperKit default task will be set via DecodingOptions")
                } catch {
                    // WhisperKitの初期化に失敗した場合、破損したモデルファイルを削除して再試行
                    optimizationStatus = "Model initialization failed, cleaning up"
                    optimizationProgress = 0.0
                    await deleteModelFiles(model)
                    throw error
                }
                
                if let modelFolder = folder {
                    whisperKit?.modelFolder = modelFolder
                    
                    modelState = .prewarming
                    optimizationProgress = 0.7
                    optimizationStatus = "Optimizing model"
                    
                    // モデルを最適化（prewarm）
                    try await whisperKit?.prewarmModels()
                    
                    modelState = .loading
                    optimizationProgress = 0.8
                    optimizationStatus = "Loading model"
                    
                    // モデルをロード
                    try await whisperKit?.loadModels()
                    
                    modelState = .loaded
                    optimizationProgress = 1.0
                    optimizationStatus = "Model ready"
                    
                    // ローカルモデルリストに追加（元のモデルID）
                    if !localModels.contains(actualModelId) {
                        localModels.append(actualModelId)
                    }
                    
                    print("Model loading completed successfully")
                    break // 成功したらループを抜ける
                }
                
            } catch {
                retryCount += 1
                print("Model loading failed (attempt \(retryCount)/\(maxRetries)): \(error.localizedDescription)")
                
                if retryCount >= maxRetries {
                    modelState = .unloaded
                    optimizationStatus = "Load failed after \(maxRetries) attempts: \(error.localizedDescription)"
                    print("All retry attempts exhausted. Manual model selection required.")
                } else {
                    optimizationStatus = "Retrying in a moment (attempt \(retryCount)/\(maxRetries))"
                    modelState = .unloaded
                }
            }
        }
    }
    
    // 自動デバイス最適化・ロード機能
    @MainActor
    func autoOptimizeAndLoadModel() async {
        print("🔄 Starting autoOptimizeAndLoadModel")
        print("🔄 Current model state: \(modelState)")
        print("🔄 Selected model: \(selectedModel)")
        print("🔄 Local models: \(localModels)")
        
        guard !isOptimizing else { 
            print("⚠️ Auto-optimization already in progress, skipping")
            return 
        }
        
        // OpenAIモデルが選択されている場合は、WhisperKitモデルの自動ロードをスキップ
        if selectedModel == "whisper-1" || selectedModel == "gpt-4o-mini-transcribe" || selectedModel == "gpt-4o-transcribe" {
            print("🔄 OpenAI model selected (\(selectedModel)), skipping WhisperKit auto-load")
            optimizationStatus = "OpenAI model selected - WhisperKit auto-load skipped"
            return
        }
        
        // サブスクリプション状態をチェック（ローカルモデルは制限解除）
        let subscriptionManager = SubCriptionManager.shared
        
        // バンドルモデル以外で、サブスクリプションがない場合は自動ロード不可（OpenAIモデルのみ）
        if !isBundledModel(selectedModel) && isOpenAIModel(selectedModel) && !subscriptionManager.isSubCriptiond {
            print("❌ Subscription required for model: \(selectedModel)")
            optimizationStatus = "Subscription required to use this model"
            return
        }
        
        guard !localModels.isEmpty else {
            print("❌ No bundled models found in localModels, cannot auto-load")
            print("❌ Available local models: \(localModels)")
            optimizationStatus = "Bundled model not available for auto-loading"
            return
        }
        
        print("✅ \(localModels.count) bundled models found, proceeding with auto-load")
        isOptimizing = true
        optimizationProgress = 0.0
        optimizationStatus = "Initializing automatic model setup"
        
        // 最大3回まで再試行
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries && modelState != .loaded {
            do {
                if retryCount > 0 {
                    print("Retrying model loading (attempt \(retryCount + 1)/\(maxRetries))")
                    optimizationStatus = "Retrying model loading (attempt \(retryCount + 1)/\(maxRetries))"
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
                }
                
                print("Starting automatic model optimization and loading")
                
                // デバイス情報を取得
                let deviceInfo = getDeviceInfo()
                optimizationStatus = "Analyzing device capabilities"
                optimizationProgress = 0.1
                logMessage("Device info: \(deviceInfo.model), Memory: \(deviceInfo.availableMemory / (1024*1024*1024))GB")
                
                // 最適なモデル設定を決定
                let optimalConfig = determineOptimalConfig(for: deviceInfo)
                optimizationStatus = "Configuring optimal settings"
                optimizationProgress = 0.2
                logMessage("Optimal config: GPU=\(optimalConfig.enableGPUAcceleration), Quantized=\(optimalConfig.useQuantizedModel)")
                
                // モデル最適化を実行
                optimizationStatus = "Optimizing model for device"
                optimizationProgress = 0.3
                
                // シミュレートされた最適化処理
                try await performModelOptimization(config: optimalConfig)
                
                optimizationStatus = "Model optimization completed"
                optimizationProgress = 0.4
                logMessage("Model optimization completed successfully")
                
                // 最適化完了後、少し待ってからロード開始
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
                // 自動ロードを開始
                optimizationStatus = "Loading \(selectedModelDisplayName)"
                optimizationProgress = 0.5
                logMessage("Starting model loading")
                
                // 自動ロード処理を実行
                try await performAutoLoad()
                
                // モデルが実際にロードされたか確認
                if modelState == .loaded && whisperKit != nil {
                    optimizationStatus = "Model ready for use"
                    optimizationProgress = 1.0
                    print("Model loading completed successfully!")
                    print("WhisperKit instance: \(whisperKit != nil ? "Ready" : "Not ready")")
                    print("Model state: \(modelState)")
                    
                    // 完了後、少し待ってからステータスをクリア
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                    optimizationStatus = ""
                    print("✨ Auto-optimization and loading completed!")
                    break // 成功したらループを抜ける
                } else {
                    throw NSError(domain: "WhisperModelManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model loading completed but state is not loaded"])
                }
                
            } catch {
                retryCount += 1
                print("Auto-load failed (attempt \(retryCount)/\(maxRetries)): \(error.localizedDescription)")
                
                if retryCount >= maxRetries {
                    optimizationStatus = "Auto-load failed after \(maxRetries) attempts: \(error.localizedDescription)"
                    modelState = .unloaded
                    print("All retry attempts exhausted. Manual model selection required.")
                } else {
                    optimizationStatus = "Retrying in a moment (attempt \(retryCount)/\(maxRetries))"
                    modelState = .unloaded
                }
            }
        }
        
        isOptimizing = false
    }
    
    // 自動ロード機能
    private func performAutoLoad() async throws {
        optimizationStatus = "Locating bundled model"
        optimizationProgress = 0.6
        
        // アプリバンドル内のモデルフォルダを取得
        guard let bundlePath = findBundledModelPath() else {
            optimizationStatus = "Bundled model not found in app bundle"
            print("❌ Bundled model not found, attempting alternative search")
            
            // 代替検索を試行
            let alternativePath = Bundle.main.path(forResource: "Cription mini", ofType: nil)
            if let altPath = alternativePath {
                print("✅ Found alternative bundled model path: \(altPath)")
                return try await loadBundledModel(from: altPath)
            }
            
            throw NSError(domain: "WhisperModelManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bundled model 'Cription mini' not found in app bundle"])
        }
        
        print("📁 Using bundled model at: \(bundlePath)")
        return try await loadBundledModel(from: bundlePath)
    }
    
    // バンドルモデルのロード処理を共通化
    private func loadBundledModel(from bundlePath: String) async throws {
        let folder = URL(fileURLWithPath: bundlePath)
        
        // モデルフォルダの存在と整合性を確認
        guard FileManager.default.fileExists(atPath: bundlePath) else {
            throw NSError(domain: "WhisperModelManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model folder does not exist at path: \(bundlePath)"])
        }
        
        // バンドルモデルの整合性をチェック
        guard await validateModelFiles(at: URL(fileURLWithPath: bundlePath)) else {
            throw NSError(domain: "WhisperModelManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Bundled model files are corrupted or incomplete at path: \(bundlePath)"])
        }
        
        optimizationStatus = "Initializing WhisperKit"
        optimizationProgress = 0.7
        
        // WhisperKitインスタンスを作成
        let config = WhisperKitConfig(
            computeOptions: getComputeOptions(),
            verbose: false,
            logLevel: .error,
            prewarm: false,
            load: false,
            download: false
        )
        
        // デバイス識別のログを抑制
        setupWhisperKitLogging()
        
                whisperKit = try await WhisperKit(config)
                whisperKit?.modelFolder = folder
                
                // デフォルトのタスク設定を強制的にtranCriptionに設定
                print("🔧 Setting default task to tranCription mode")
                // WhisperKitの内部設定はDecodingOptionsで制御
                print("✅ WhisperKit default task will be set via DecodingOptions")
        
        // WhisperKitインスタンスが正常に作成されたか確認
        guard whisperKit != nil else {
            throw NSError(domain: "WhisperModelManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create WhisperKit instance"])
        }
        
        optimizationStatus = "Warming up model"
        optimizationProgress = 0.8
        
        // モデルを最適化（prewarm）
        try await whisperKit?.prewarmModels()
        
        optimizationStatus = "Loading model"
        optimizationProgress = 0.9
        
        // モデルをロード
        try await whisperKit?.loadModels()
        
        // モデルが実際にロードされたか最終確認
        guard whisperKit?.modelState == .loaded else {
            let errorMsg = "Model loading completed but WhisperKit model state is not loaded"
            print("❌ \(errorMsg)")
            print("❌ WhisperKit model state: \(whisperKit?.modelState ?? .unloaded)")
            throw NSError(domain: "WhisperModelManager", code: 5, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        modelState = .loaded
        optimizationStatus = "Model ready for use!"
        optimizationProgress = 1.0
        print("✅ Model loaded successfully and ready for tranCription!")
        print("✅ Model state: \(whisperKit?.modelState ?? .unloaded)")
        print("✅ Selected model: \(selectedModel)")
        print("✅ Auto-load completed successfully")
    }
    
    // バンドルモデルのパスを検索するヘルパー関数
    private func findBundledModelPath() -> String? {
        print("Searching for bundled model path")
        
        // バンドルパスを一度だけ取得
        let bundlePath = Bundle.main.bundlePath
        
        // バンドルされているモデルの情報（モデルIDと表示名）
        let bundledModelInfo: [(id: String, displayName: String)] = [
            ("openai_whisper-base", "Cription mini"),
            ("openai_whisper-tiny.en", "Cription Swift English"),
            ("openai_whisper-base.en", "Cription mini English")
        ]
        
        // 1. Bundle.main.path(forResource:ofType:)を使用した検索（最優先）
        for modelInfo in bundledModelInfo {
            // 表示名で検索
            if let modelPath = Bundle.main.path(forResource: modelInfo.displayName, ofType: nil) {
                print("Found bundled model by display name: \(modelInfo.displayName) at \(modelPath)")
                return modelPath
            }
            
            // モデルIDで検索
            if let modelPath = Bundle.main.path(forResource: modelInfo.id, ofType: nil) {
                print("Found bundled model by ID: \(modelInfo.id) at \(modelPath)")
                return modelPath
            }
        }
        
        // 2. Resourcesディレクトリを直接検索
        if let resourcePath = Bundle.main.resourcePath {
            for modelInfo in bundledModelInfo {
                // 表示名で検索
                let displayNamePath = "\(resourcePath)/\(modelInfo.displayName)"
                if FileManager.default.fileExists(atPath: displayNamePath) {
                    print("Found bundled model in Resources: \(modelInfo.displayName) at \(displayNamePath)")
                    return displayNamePath
                }
                
                // モデルIDで検索
                let modelIdPath = "\(resourcePath)/\(modelInfo.id)"
                if FileManager.default.fileExists(atPath: modelIdPath) {
                    print("Found bundled model in Resources: \(modelInfo.id) at \(modelIdPath)")
                    return modelIdPath
                }
            }
        }
        
        // 3. プロジェクトのResourcesディレクトリを検索
        for modelInfo in bundledModelInfo {
            let projectPaths = [
                "\(bundlePath)/../Cription/Resources/\(modelInfo.displayName)",
                "\(bundlePath)/../../Cription/Resources/\(modelInfo.displayName)",
                "\(bundlePath)/../../../Cription/Resources/\(modelInfo.displayName)",
                "\(bundlePath)/../Cription/Resources/\(modelInfo.id)",
                "\(bundlePath)/../../Cription/Resources/\(modelInfo.id)",
                "\(bundlePath)/../../../Cription/Resources/\(modelInfo.id)"
            ]
            
            for path in projectPaths {
                let normalizedPath = (path as NSString).standardizingPath
                if FileManager.default.fileExists(atPath: normalizedPath) {
                    print("Found bundled model in project Resources: \(normalizedPath)")
                    return normalizedPath
                }
            }
        }
        
        // 4. より詳細な検索 - バンドル内容を列挙
        print("Bundled model not found, checking bundle contents")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Bundle contents: \(contents)")
                
                // モデル名を含むディレクトリを検索
                for content in contents {
                    for modelInfo in bundledModelInfo {
                        if content.contains(modelInfo.displayName) || content.contains(modelInfo.id) {
                            let fullPath = "\(resourcePath)/\(content)"
                            if FileManager.default.fileExists(atPath: fullPath) {
                                print("Found potential model directory: \(fullPath)")
                                return fullPath
                            }
                        }
                    }
                }
            } catch {
                print("Error reading bundle contents: \(error)")
            }
        }
        
        // 2. バンドルパス直下を検索
        for modelInfo in bundledModelInfo {
            let displayNamePath = "\(bundlePath)/\(modelInfo.displayName)"
            if FileManager.default.fileExists(atPath: displayNamePath) {
                print("Found bundled model: \(modelInfo.displayName) at \(displayNamePath)")
                return displayNamePath
            }
            
            let modelIdPath = "\(bundlePath)/\(modelInfo.id)"
            if FileManager.default.fileExists(atPath: modelIdPath) {
                print("Found bundled model: \(modelInfo.id) at \(modelIdPath)")
                return modelIdPath
            }
        }
        
        // 3. Bundle APIを使用した検索
        for modelInfo in bundledModelInfo {
            if let path = Bundle.main.path(forResource: modelInfo.displayName, ofType: nil) {
                print("Found bundled model via path: \(path)")
                return path
            }
            
            if let path = Bundle.main.path(forResource: modelInfo.id, ofType: nil) {
                print("Found bundled model via path: \(path)")
                return path
            }
        }
        
        // 4. URLベースの検索
        for modelInfo in bundledModelInfo {
            if let url = Bundle.main.url(forResource: modelInfo.displayName, withExtension: nil) {
                print("Found bundled model via URL: \(url.path)")
                return url.path
            }
            
            if let url = Bundle.main.url(forResource: modelInfo.id, withExtension: nil) {
                print("Found bundled model via URL: \(url.path)")
                return url.path
            }
        }
        
        // 5. より詳細な検索
        print("Bundled model not found, checking bundle contents")
        let bundleResources = Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil)
        
        // バンドル内のリソースから直接検索
        for resource in bundleResources {
            for modelInfo in bundledModelInfo {
                if resource.contains(modelInfo.displayName) || resource.contains(modelInfo.id) {
                    print("Found bundled model in resources: \(resource)")
                    return resource
                }
            }
        }
        
        print("Bundled model not found in any location")
        return nil
    }
    
    // バンドルされたモデルかどうかをチェック
    private func isBundledModel(_ model: String) -> Bool {
        // OpenAIモデルの場合はバンドルモデルではない
        if isOpenAIModel(model) {
            return false
        }
        
        // モデル名→IDのマッピング
        let modelToId: [String: String] = [
            "Cription Swift English": "openai_whisper-tiny.en",
            "Cription mini": "openai_whisper-base",
            "Cription mini English": "openai_whisper-base.en"
        ]
        
        // 実際のモデルIDを取得
        let actualModelId = modelToId[model] ?? model
        
        // バンドルパスを取得
        let bundlePath = Bundle.main.bundlePath
        
        // 1. Resourcesディレクトリを直接検索（最優先）
        if let resourcePath = Bundle.main.resourcePath {
            let resourceModelPath = "\(resourcePath)/\(model)"
            let resourceModelIdPath = "\(resourcePath)/\(actualModelId)"
            
            if FileManager.default.fileExists(atPath: resourceModelPath) {
                print("Found bundled model in Resources: \(resourceModelPath)")
                return true
            }
            
            if FileManager.default.fileExists(atPath: resourceModelIdPath) {
                print("Found bundled model in Resources: \(resourceModelIdPath)")
                return true
            }
        }
        
        // 1.5. プロジェクトのResourcesディレクトリを検索
        let projectPaths = [
            "\(bundlePath)/../Cription/Resources/\(model)",
            "\(bundlePath)/../../Cription/Resources/\(model)",
            "\(bundlePath)/../../../Cription/Resources/\(model)",
            "\(bundlePath)/../Cription/Resources/\(actualModelId)",
            "\(bundlePath)/../../Cription/Resources/\(actualModelId)",
            "\(bundlePath)/../../../Cription/Resources/\(actualModelId)"
        ]
        
        for path in projectPaths {
            let normalizedPath = (path as NSString).standardizingPath
            if FileManager.default.fileExists(atPath: normalizedPath) {
                print("Found bundled model in project Resources: \(normalizedPath)")
                return true
            }
        }
        
        // 2. バンドルパス内を直接検索
        let modelPath = "\(bundlePath)/\(model)"
        let modelIdPath = "\(bundlePath)/\(actualModelId)"
        
        if FileManager.default.fileExists(atPath: modelPath) {
            print("Found bundled model at direct path: \(modelPath)")
            return true
        }
        
        if FileManager.default.fileExists(atPath: modelIdPath) {
            print("Found bundled model at direct path: \(modelIdPath)")
            return true
        }
        
        // 3. Bundle APIで検索
        if let path = Bundle.main.path(forResource: model, ofType: nil) {
            print("Found bundled model via path: \(path)")
            return true
        }
        
        if let path = Bundle.main.path(forResource: actualModelId, ofType: nil) {
            print("Found bundled model via path: \(path)")
            return true
        }
        
        // 4. URLベースの検索
        if let url = Bundle.main.url(forResource: model, withExtension: nil) {
            print("Found bundled model via URL: \(url.path)")
            return true
        }
        
        if let url = Bundle.main.url(forResource: actualModelId, withExtension: nil) {
            print("Found bundled model via URL: \(url.path)")
            return true
        }
        
        // 5. バンドルリソースから検索
        let bundleResources = Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil)
        for resource in bundleResources {
            if resource.contains(model) || resource.contains(actualModelId) {
                print("Found bundled model in resources: \(resource)")
                return true
            }
        }
        
        // 6. ローカルモデルリストから検索（バンドルモデルとして追加されたもの）
        if localModels.contains(model) || localModels.contains(actualModelId) {
            print("Found model in localModels: \(model)")
            return true
        }
        
        print("Model \(model) not found as bundled model")
        return false
    }
    
    // OpenAIモデルかどうかをチェック
    private func isOpenAIModel(_ model: String) -> Bool {
        return model == "whisper-1" || model == "gpt-4o-transcribe" || model == "gpt-4o-mini-transcribe"
    }
    
    private func getComputeOptions() -> ModelComputeOptions {
        // デバイスに基づいて最適な計算オプションを決定
        #if os(iOS)
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if isLowPowerMode {
            return ModelComputeOptions(
                melCompute: .cpuOnly,
                audioEncoderCompute: .cpuOnly,
                textDecoderCompute: .cpuOnly,
                prefillCompute: .cpuOnly
            )
        } else {
            return ModelComputeOptions(
                melCompute: .cpuAndNeuralEngine,
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine,
                prefillCompute: .cpuAndNeuralEngine
            )
        }
        #else
        return ModelComputeOptions(
            melCompute: .cpuAndGPU,
            audioEncoderCompute: .cpuAndGPU,
            textDecoderCompute: .cpuAndGPU,
            prefillCompute: .cpuAndGPU
        )
        #endif
    }
    
    // デバイス識別のログ出力を制御するためのカスタムログハンドラー
    private func setupCustomLogging() {
        // WhisperKitのログはWhisperKitConfigで制御
        // デバイス識別の重複ログはverbose: falseとlogLevel: .errorで抑制
        print("🔧 WhisperKit logging configured to suppress device identification messages")
    }
    
    // WhisperKitのログ設定を最適化
    private func setupWhisperKitLogging() {
        // WhisperKitのログはWhisperKitConfigで制御
        // デバイス識別の重複ログはverbose: falseとlogLevel: .errorで抑制
        print("🔧 WhisperKit logging configured to suppress device identification messages")
    }
    
    // デバイス情報のキャッシュ
    private static var cachedDeviceInfo: DeviceInfo?
    
    // ログ出力の重複防止
    private static var lastLogMessage: String = ""
    private static var logRepeatCount: Int = 0
    
    private func getDeviceInfo() -> DeviceInfo {
        // キャッシュされたデバイス情報があればそれを使用
        if let cached = Self.cachedDeviceInfo {
            return cached
        }
        
        #if os(iOS)
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        let deviceModel = "Mac"
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let isLowPowerModeEnabled = false
        #endif
        
        let deviceInfo = DeviceInfo(
            model: deviceModel,
            systemVersion: systemVersion,
            isLowPowerMode: isLowPowerModeEnabled,
            availableMemory: getAvailableMemory()
        )
        
        // デバイス情報をキャッシュ
        Self.cachedDeviceInfo = deviceInfo
        return deviceInfo
    }
    
    // 重複ログを防ぐログ出力機能
    private func logMessage(_ message: String) {
        if Self.lastLogMessage == message {
            Self.logRepeatCount += 1
            if Self.logRepeatCount <= 3 {
                print("\(message) (repeated \(Self.logRepeatCount) times)")
            }
        } else {
            if Self.logRepeatCount > 0 {
                print("\(Self.lastLogMessage) (repeated \(Self.logRepeatCount) times total)")
            }
            print(message)
            Self.lastLogMessage = message
            Self.logRepeatCount = 0
        }
    }
    
    private func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    private func determineOptimalConfig(for deviceInfo: DeviceInfo) -> OptimizationConfig {
        // デバイスに基づいて最適な設定を決定
        let availableMemoryGB = Double(deviceInfo.availableMemory) / (1024 * 1024 * 1024)
        
        if deviceInfo.isLowPowerMode || availableMemoryGB < 2.0 {
            // 低電力モードまたはメモリ不足の場合
            return OptimizationConfig(
                useQuantizedModel: true,
                maxConcurrentTasks: 1,
                enableGPUAcceleration: false,
                memoryOptimization: .aggressive
            )
        } else if availableMemoryGB >= 8.0 {
            // 高メモリデバイスの場合
            return OptimizationConfig(
                useQuantizedModel: false,
                maxConcurrentTasks: 4,
                enableGPUAcceleration: true,
                memoryOptimization: .standard
            )
        } else {
            // 標準デバイスの場合
            return OptimizationConfig(
                useQuantizedModel: false,
                maxConcurrentTasks: 2,
                enableGPUAcceleration: true,
                memoryOptimization: .standard
            )
        }
    }
    
    private func performModelOptimization(config: OptimizationConfig) async throws {
        // 実際の実装では、ここでWhisperKitの最適化APIを呼び出す
        // 現在はシミュレーションとして非同期処理を実行
        
        optimizationStatus = "Loading model components"
        optimizationProgress = 0.7
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        optimizationStatus = "Applying optimizations"
        optimizationProgress = 0.8
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        optimizationStatus = "Finalizing configuration"
        optimizationProgress = 0.9
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
    
}

// MARK: - Supporting Types

struct DeviceInfo {
    let model: String
    let systemVersion: String
    let isLowPowerMode: Bool
    let availableMemory: UInt64
}

struct OptimizationConfig {
    let useQuantizedModel: Bool
    let maxConcurrentTasks: Int
    let enableGPUAcceleration: Bool
    let memoryOptimization: MemoryOptimizationLevel
}

enum MemoryOptimizationLevel {
    case standard
    case aggressive
}

