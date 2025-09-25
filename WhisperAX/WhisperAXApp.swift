//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct WhisperAXApp: App {
    @StateObject private var languageManager = LanguageManagerNew.shared
    @StateObject private var modelManager = WhisperModelManager()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    
    init() {
        // アプリ起動時に言語設定を適用
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            // 保存された言語設定を適用
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        } else {
            // 端末の言語設定を確認して自動切り替え
            LanguageManagerNew.shared.updateToSystemLanguage()
        }
        
        // バックグラウンドタスクの設定
        setupBackgroundTasks()
    }
    
    private func setupBackgroundTasks() {
        // バックグラウンド処理のスケジュール
        backgroundTaskManager.scheduleBackgroundProcessing()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environmentObject(modelManager)
                .environmentObject(themeManager)
                .environmentObject(backgroundTaskManager)
                .preferredColorScheme(themeManager.currentColorScheme)
                #if canImport(UIKit)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    backgroundTaskManager.startBackgroundTask()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    backgroundTaskManager.endBackgroundTask()
                }
                #endif
            #if os(macOS)
                .frame(minWidth: 1000, minHeight: 700)
            #endif
        }
    }
}
