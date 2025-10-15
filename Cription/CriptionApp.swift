//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI
import Security
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@main
struct CriptionApp: App {
    @StateObject private var languageManager = LanguageManager.shared  // Source Language
    @StateObject private var displayLanguageManager = DisplayLanguageManager.shared  // UI Display Language
    @StateObject private var modelManager = WhisperModelManager()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    @StateObject private var tranCriptionServiceManager = TranCriptionServiceManager()
    @StateObject private var creditManager = CreditManager.shared
    
    init() {
        // Config.xcconfigからKeychainへの移行処理を実行
        SecureKeychainManager.shared.migrateFromConfig()
        
        // UserDefaultsからKeychainへの移行処理を実行
        Self.migrateAPIKeyFromUserDefaults()
        
        // アプリ起動時に言語設定を適用
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            // 保存された言語設定を適用
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        } else {
            // 端末の言語設定を確認して自動切り替え
            LanguageManager.shared.updateToSystemLanguage()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)  // Source Language
                .environmentObject(displayLanguageManager)  // UI Display Language
                .environmentObject(modelManager)
                .environmentObject(themeManager)
                .environmentObject(backgroundTaskManager)
                .environmentObject(tranCriptionServiceManager)
                .environmentObject(creditManager)
                .preferredColorScheme(themeManager.currentColorScheme)
                #if canImport(UIKit)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    backgroundTaskManager.startBackgroundTask()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    backgroundTaskManager.endBackgroundTask()
                }
                .onAppear {
                    // WhisperModelManagerをTranCriptionServiceManagerに設定
                    tranCriptionServiceManager.setWhisperModelManager(modelManager)
                    
                    // KeychainからAPIキーを読み込んで設定
                    tranCriptionServiceManager.loadAPIKeyFromKeychain()
                    
                    // バックグラウンドタスクの設定をView表示時に実行
                    backgroundTaskManager.scheduleBackgroundProcessing()
                    
                    // アプリ起動時の自動モデルロード確認
                    print("🚀 App launched - Model manager state: \(modelManager.modelState)")
                    print("🚀 Selected model: \(modelManager.selectedModel)")
                    print("🚀 Local models available: \(modelManager.localModels)")
                    
                    // バンドルモデルの自動ロード処理
                    Task {
                        await performAutoLoad()
                    }
                }
                #endif
            #if os(macOS)
                .frame(minWidth: 1000, minHeight: 700)
            #endif
        }
    }
    
    // MARK: - Auto Load Management
    
    private func performAutoLoad() async {
        print("🔄 Starting automatic model loading process")
        
        // OpenAIモデルが選択されている場合は、WhisperKitモデルの自動ロードをスキップ
        if modelManager.selectedModel == "whisper-1" || modelManager.selectedModel == "gpt-4o-mini-transcribe" || modelManager.selectedModel == "gpt-4o-transcribe" {
            print("🔄 OpenAI model selected (\(modelManager.selectedModel)), skipping WhisperKit auto-load")
            return
        }
        
        // モデルが既にロード済みの場合はスキップ
        if modelManager.modelState == .loaded {
            print("✅ Model already loaded, skipping auto-load")
            return
        }
        
        // バンドルモデルを再検索して確実に利用可能にする
        print("🔄 Re-scanning for bundled models")
        let bundledModels = modelManager.findAllBundledModels()
        if !bundledModels.isEmpty {
            print("✅ Found bundled models: \(bundledModels)")
            for model in bundledModels {
                if !modelManager.localModels.contains(model) {
                    modelManager.localModels.append(model)
                    print("✅ Added bundled model to local models: \(model)")
                }
            }
        }
        
        // バンドルモデルが利用可能かチェック
        guard !modelManager.localModels.isEmpty else {
            print("⚠️ No bundled models available in local models: \(modelManager.localModels)")
            print("🔄 Attempting to find bundled models manually")
            
            // 手動でバンドルモデルを検索
            let bundledModelNames = ["openai_whisper-small_216MB", "openai_whisper-tiny.en", "openai_whisper-base", "openai_whisper-base.en"]
            var foundModels: [String] = []
            
            for modelName in bundledModelNames {
                if let bundlePath = Bundle.main.path(forResource: modelName, ofType: nil) {
                    print("✅ Found bundled model: \(modelName) at \(bundlePath)")
                    foundModels.append(modelName)
                }
            }
            
            if !foundModels.isEmpty {
                modelManager.localModels.append(contentsOf: foundModels)
                print("✅ Added \(foundModels.count) bundled models to localModels")
            } else {
                print("❌ No bundled models found")
                return
            }
            return
        }
        
        print("🔄 Triggering automatic bundled model loading")
        await modelManager.autoOptimizeAndLoadModel()
        
        // ロード結果を確認
        if modelManager.modelState == .loaded {
            print("✅ Bundled model loaded successfully: \(modelManager.selectedModel)")
        } else {
            print("❌ Failed to load bundled model, current state: \(modelManager.modelState)")
            print("🔄 Attempting fallback model loading")
            
            // フォールバック: 他のバンドルモデルを試す
            for model in modelManager.localModels {
                if !model.hasPrefix("whisper-") {
                    print("🔄 Trying fallback model: \(model)")
                    await modelManager.loadModel(model)
                    if modelManager.modelState == .loaded {
                        print("✅ Fallback model loaded successfully: \(model)")
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Keychain Management
    
    private static func migrateAPIKeyFromUserDefaults() {
        // UserDefaultsからAPIキーを取得
        if let oldAPIKey = UserDefaults.standard.string(forKey: "openai_api_key"),
           !oldAPIKey.isEmpty {
            
            // Keychainに保存
            if SecureKeychainManager.shared.saveAPIKey(oldAPIKey) {
                // UserDefaultsから削除
                UserDefaults.standard.removeObject(forKey: "openai_api_key")
                UserDefaults.standard.synchronize()
                print("✅ API key migrated from UserDefaults to Keychain")
            } else {
                print("❌ Failed to migrate API key to Keychain")
            }
        }
    }
}
