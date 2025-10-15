//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import Foundation
import SwiftUI
import ObjectiveC

/// UI表示言語専用の管理クラス
/// 音声認識言語（Source Language）とは完全に独立して動作する
@MainActor
class DisplayLanguageManager: ObservableObject {
    static let shared = DisplayLanguageManager()
    
    /// 現在のUI表示言語（言語コード）
    @Published var currentDisplayLanguage: String {
        didSet {
            // UI表示言語は専用のキーで保存
            UserDefaults.standard.set(currentDisplayLanguage, forKey: "uiDisplayLanguageCode")
            updateUILocale()
        }
    }
    
    private init() {
        // デフォルトでシステム言語を設定
        self.currentDisplayLanguage = Self.getSystemPrimaryLanguage()
        
        // アプリ起動時にUI表示言語設定を適用
        if let savedLanguage = UserDefaults.standard.string(forKey: "uiDisplayLanguageCode") {
            self.currentDisplayLanguage = savedLanguage
        }
        
        updateUILocale()
    }
    
    /// 端末のプライマリ言語を取得
    private static func getSystemPrimaryLanguage() -> String {
        // 保存されたUI表示言語設定があればそれを優先
        if let savedLanguage = UserDefaults.standard.string(forKey: "uiDisplayLanguageCode") {
            return savedLanguage
        }
        
        // 端末の言語設定からプライマリ言語を取得
        let preferredLanguages = Locale.preferredLanguages
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        // アプリでサポートされている言語の中から最適なものを選択
        let supportedLanguages = Self.getAvailableDisplayLanguages()
        for preferredLang in preferredLanguages {
            let langCode = String(preferredLang.prefix(2)) // "ja-JP" -> "ja"
            if supportedLanguages.contains(langCode) {
                return langCode
            }
        }
        
        // フォールバック: システムのデフォルト言語
        return systemLanguage
    }
    
    /// 端末の言語設定を再取得して自動切り替え
    func updateToSystemLanguage() {
        let newLanguage = Self.getSystemPrimaryLanguage()
        if newLanguage != currentDisplayLanguage {
            currentDisplayLanguage = newLanguage
        }
    }
    
    private func updateUILocale() {
        // Localizable.xcstringsを使用する場合、システムの言語設定を変更
        // これはアプリの再起動が必要になる場合があります
        
        // 現在の言語設定を保存
        UserDefaults.standard.set([currentDisplayLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // UIの更新を強制
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .displayLanguageChanged, object: nil)
        }
        
        print("DisplayLanguageManager: UI language set to '\(currentDisplayLanguage)'")
    }
    
    /// UI表示に適した言語のリストを取得（autoは除外）
    static func getAvailableDisplayLanguages() -> [String] {
        return [
            "en", "ja", "zh", "de", "es", "ru", "ko", "fr", "pt", "tr",
            "pl", "ca", "nl", "ar", "sv", "it", "id", "hi", "fi", "vi",
            "he", "uk", "el", "ms", "cs", "ro", "da", "hu", "ta", "no",
            "th", "ur", "hr", "bg", "lt", "la", "mi", "ml", "cy", "sk",
            "te", "fa", "lv", "bn", "sr", "az", "sl", "kn", "et", "mk",
            "br", "eu", "is", "hy", "ne", "mn", "bs", "kk", "sq", "sw",
            "gl", "mr", "pa", "si", "km", "sn", "yo", "so", "af", "oc",
            "ka", "be", "tg", "sd", "gu", "am", "yi", "lo", "uz", "fo",
            "ht", "ps", "tk", "nn", "mt", "sa", "lb", "my", "bo", "tl",
            "mg", "as", "tt", "haw", "ln", "ha", "ba", "jw", "su", "yue"
        ]
    }
    
    func availableDisplayLanguages() -> [String] {
        return Self.getAvailableDisplayLanguages()
    }
    
    func displayLanguageDisplayName(for code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "ja": "日本語",
            "zh": "中文",
            "de": "Deutsch",
            "es": "Español",
            "ru": "Русский",
            "ko": "한국어",
            "fr": "Français",
            "pt": "Português",
            "tr": "Türkçe",
            "pl": "Polski",
            "ca": "Català",
            "nl": "Nederlands",
            "ar": "العربية",
            "sv": "Svenska",
            "it": "Italiano",
            "id": "Bahasa Indonesia",
            "hi": "हिन्दी",
            "fi": "Suomi",
            "vi": "Tiếng Việt",
            "he": "עברית",
            "uk": "Українська",
            "el": "Ελληνικά",
            "ms": "Bahasa Melayu",
            "cs": "Čeština",
            "ro": "Română",
            "da": "Dansk",
            "hu": "Magyar",
            "ta": "தமிழ்",
            "no": "Norsk",
            "th": "ไทย",
            "ur": "اردو",
            "hr": "Hrvatski",
            "bg": "Български",
            "lt": "Lietuvių",
            "la": "Latina",
            "mi": "Te Reo Māori",
            "ml": "മലയാളം",
            "cy": "Cymraeg",
            "sk": "Slovenčina",
            "te": "తెలుగు",
            "fa": "فارسی",
            "lv": "Latviešu",
            "bn": "বাংলা",
            "sr": "Српски",
            "az": "Azərbaycan",
            "sl": "Slovenščina",
            "kn": "ಕನ್ನಡ",
            "et": "Eesti",
            "mk": "Македонски",
            "br": "Brezhoneg",
            "eu": "Euskera",
            "is": "Íslenska",
            "hy": "Հայերեն",
            "ne": "नेपाली",
            "mn": "Монгол",
            "bs": "Bosanski",
            "kk": "Қазақ",
            "sq": "Shqip",
            "sw": "Kiswahili",
            "gl": "Galego",
            "mr": "मराठी",
            "pa": "ਪੰਜਾਬੀ",
            "si": "සිංහල",
            "km": "ខ្មែរ",
            "sn": "ChiShona",
            "yo": "Yorùbá",
            "so": "Soomaali",
            "af": "Afrikaans",
            "oc": "Occitan",
            "ka": "ქართული",
            "be": "Беларуская",
            "tg": "Тоҷикӣ",
            "sd": "سنڌي",
            "gu": "ગુજરાતી",
            "am": "አማርኛ",
            "yi": "ייִדיש",
            "lo": "ລາວ",
            "uz": "O'zbek",
            "fo": "Føroyskt",
            "ht": "Kreyòl Ayisyen",
            "ps": "پښتو",
            "tk": "Türkmen",
            "nn": "Nynorsk",
            "mt": "Malti",
            "sa": "संस्कृतम्",
            "lb": "Lëtzebuergesch",
            "my": "မြန်မာ",
            "bo": "བོད་ཡིག",
            "tl": "Tagalog",
            "mg": "Malagasy",
            "as": "অসমীয়া",
            "tt": "Татар",
            "haw": "ʻŌlelo Hawaiʻi",
            "ln": "Lingála",
            "ha": "Hausa",
            "ba": "Башҡорт",
            "jw": "Basa Jawa",
            "su": "Basa Sunda",
            "yue": "粵語"
        ]
        
        return languageNames[code] ?? code.capitalized
    }
    
    func setDisplayLanguage(_ languageCode: String) {
        currentDisplayLanguage = languageCode
    }
}

// MARK: - Display Language Notification
extension Notification.Name {
    static let displayLanguageChanged = Notification.Name("displayLanguageChanged")
}

// MARK: - SwiftUI Environment Support for Display Language
extension EnvironmentValues {
    private struct DisplayLanguageManagerKey: EnvironmentKey {
        static let defaultValue = DisplayLanguageManager.shared
    }
    
    var displayLanguageManager: DisplayLanguageManager {
        get { self[DisplayLanguageManagerKey.self] }
        set { self[DisplayLanguageManagerKey.self] = newValue }
    }
}
