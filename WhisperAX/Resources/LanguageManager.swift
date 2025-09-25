//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation
import SwiftUI
import ObjectiveC

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Bundle Extension for Language Switching
extension Bundle {
    static var bundle: Bundle = .main
    
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundle, Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.main, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &Bundle.bundle) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

/// Modern language manager using SwiftUI's localization system
@MainActor
class LanguageManagerNew: ObservableObject {
    static let shared = LanguageManagerNew()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            updateLocale()
        }
    }
    
    private init() {
        // 端末のプライマリ言語を取得して自動設定
        let systemLanguage = Self.getSystemPrimaryLanguage()
        self.currentLanguage = systemLanguage
        
        // アプリ起動時に言語設定を適用
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            self.currentLanguage = savedLanguage
        }
        
        updateLocale()
    }
    
    /// 端末のプライマリ言語を取得
    private static func getSystemPrimaryLanguage() -> String {
        // ユーザーが手動で選択した言語がある場合はそれを使用
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            return savedLanguage
        }
        
        // 端末の言語設定からプライマリ言語を取得
        let preferredLanguages = Locale.preferredLanguages
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        // アプリでサポートされている言語の中から最適なものを選択
        let supportedLanguages = Self.getAvailableLanguages()
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
        if newLanguage != currentLanguage {
            currentLanguage = newLanguage
        }
    }
    
    private func updateLocale() {
        // Localizable.xcstringsを使用する場合、システムの言語設定を変更
        // これはアプリの再起動が必要になる場合があります
        
        // 現在の言語設定を保存
        UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // UIの更新を強制
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
        
        print("LanguageManagerNew: Current language set to '\(currentLanguage)'")
    }
    
    static func getAvailableLanguages() -> [String] {
        return [
            "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr",
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
    
    func availableLanguages() -> [String] {
        return Self.getAvailableLanguages()
    }
    
    func languageDisplayName(for code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "zh": "中文",
            "de": "Deutsch",
            "es": "Español",
            "ru": "Русский",
            "ko": "한국어",
            "fr": "Français",
            "ja": "日本語",
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
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
    }
}

// MARK: - SwiftUI Environment Support
extension EnvironmentValues {
    private struct LanguageManagerKey: EnvironmentKey {
        static let defaultValue = LanguageManagerNew.shared
    }
    
    var languageManager: LanguageManagerNew {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}
