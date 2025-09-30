//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct WhisperAXApp: App {
    @StateObject private var languageManager = LanguageManager.shared  // Source Language
    @StateObject private var displayLanguageManager = DisplayLanguageManager.shared  // UI Display Language
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
                .preferredColorScheme(themeManager.currentColorScheme)
                #if canImport(UIKit)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    backgroundTaskManager.startBackgroundTask()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    backgroundTaskManager.endBackgroundTask()
                }
                .onAppear {
                    // バックグラウンドタスクの設定をView表示時に実行
                    backgroundTaskManager.scheduleBackgroundProcessing()
                }
                #endif
            #if os(macOS)
                .frame(minWidth: 1000, minHeight: 700)
            #endif
        }
    }
}
