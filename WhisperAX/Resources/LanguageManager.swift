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

/// Source Language（音声認識言語）専用の管理クラス
/// UI表示言語とは完全に独立して動作する
@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    /// 現在のSource Language（音声認識言語）の言語コード
    @Published var currentLanguage: String {
        didSet {
            // Source Language専用のキーで保存
            UserDefaults.standard.set(currentLanguage, forKey: "sourceLanguageCode")
            // Source Languageの変更はUIの表示言語には影響しない
            print("LanguageManager: Source language set to '\(currentLanguage)'")
        }
    }
    
    private init() {
        // 初期値として一時的にシステムデフォルトを設定（後で更新される）
        self.currentLanguage = Self.getSystemPrimaryLanguage()
        
        // アプリ起動時にSource Language設定を適用
        // 古いキーからのマイグレーション
        if let oldCurrentLanguageCode = UserDefaults.standard.string(forKey: "currentLanguageCode") {
            print("🔄 Migrating old currentLanguageCode to sourceLanguageCode: \(oldCurrentLanguageCode)")
            UserDefaults.standard.set(oldCurrentLanguageCode, forKey: "sourceLanguageCode")
            UserDefaults.standard.removeObject(forKey: "currentLanguageCode")
        }
        
        if let savedLanguage = UserDefaults.standard.string(forKey: "sourceLanguageCode") {
            // Constants.swiftと同じ完全な言語マッピング（99言語対応）
            let languageMapping: [String: String] = [
                "auto": "auto",
                "english": "en",
                "chinese": "zh",
                "german": "de",
                "spanish": "es",
                "russian": "ru",
                "korean": "ko",
                "french": "fr",
                "japanese": "ja",
                "portuguese": "pt",
                "turkish": "tr",
                "polish": "pl",
                "catalan": "ca",
                "dutch": "nl",
                "arabic": "ar",
                "swedish": "sv",
                "italian": "it",
                "indonesian": "id",
                "hindi": "hi",
                "finnish": "fi",
                "vietnamese": "vi",
                "hebrew": "he",
                "ukrainian": "uk",
                "greek": "el",
                "malay": "ms",
                "czech": "cs",
                "romanian": "ro",
                "danish": "da",
                "hungarian": "hu",
                "tamil": "ta",
                "norwegian": "no",
                "thai": "th",
                "urdu": "ur",
                "croatian": "hr",
                "bulgarian": "bg",
                "lithuanian": "lt",
                "latin": "la",
                "maori": "mi",
                "malayalam": "ml",
                "welsh": "cy",
                "slovak": "sk",
                "telugu": "te",
                "persian": "fa",
                "latvian": "lv",
                "bengali": "bn",
                "serbian": "sr",
                "azerbaijani": "az",
                "slovenian": "sl",
                "kannada": "kn",
                "estonian": "et",
                "macedonian": "mk",
                "breton": "br",
                "basque": "eu",
                "icelandic": "is",
                "armenian": "hy",
                "nepali": "ne",
                "mongolian": "mn",
                "bosnian": "bs",
                "kazakh": "kk",
                "albanian": "sq",
                "swahili": "sw",
                "galician": "gl",
                "marathi": "mr",
                "punjabi": "pa",
                "sinhala": "si",
                "khmer": "km",
                "shona": "sn",
                "yoruba": "yo",
                "somali": "so",
                "afrikaans": "af",
                "occitan": "oc",
                "georgian": "ka",
                "belarusian": "be",
                "tajik": "tg",
                "sindhi": "sd",
                "gujarati": "gu",
                "amharic": "am",
                "yiddish": "yi",
                "lao": "lo",
                "uzbek": "uz",
                "faroese": "fo",
                "haitian": "ht",
                "pashto": "ps",
                "turkmen": "tk",
                "nynorsk": "nn",
                "maltese": "mt",
                "sanskrit": "sa",
                "luxembourgish": "lb",
                "myanmar": "my",
                "tibetan": "bo",
                "tagalog": "tl",
                "malagasy": "mg",
                "assamese": "as",
                "tatar": "tt",
                "hawaiian": "haw",
                "lingala": "ln",
                "hausa": "ha",
                "bashkir": "ba",
                "javanese": "jw",
                "sundanese": "su",
                "cantonese": "yue"
            ]
            
            // 保存された値が言語コードか言語名かを判定
            let supportedLanguageCodes = Set(languageMapping.values)
            if supportedLanguageCodes.contains(savedLanguage) {
                // 保存された値が言語コード（"ja", "en"など）の場合
                self.currentLanguage = savedLanguage
            } else if let languageCode = languageMapping[savedLanguage] {
                // 保存された値が言語名（"japanese", "english"など）の場合
                self.currentLanguage = languageCode
            } else {
                // 無効な値の場合はシステムの言語設定に基づいて設定
                let systemLang = Self.getSystemPrimaryLanguageIgnoringUserDefaults()
                self.currentLanguage = systemLang
            }
        }
        
        // Source Language の初期化完了
    }
    
    /// UserDefaultsを無視して端末のプライマリ言語を取得
    private static func getSystemPrimaryLanguageIgnoringUserDefaults() -> String {
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
        
        // フォールバック: システムのデフォルト言語、サポートされていない場合は英語
        if supportedLanguages.contains(systemLanguage) {
            return systemLanguage
        } else {
            return "en"
        }
    }
    
    /// 端末のプライマリ言語を取得
    private static func getSystemPrimaryLanguage() -> String {
        // 保存されたSource Language設定があればそれを優先
        if let savedLanguage = UserDefaults.standard.string(forKey: "sourceLanguageCode") {
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
        
        // フォールバック: システムのデフォルト言語、サポートされていない場合は英語
        if supportedLanguages.contains(systemLanguage) {
            return systemLanguage
        } else {
            return "en"
        }
    }
    
    /// 端末の言語設定を再取得して自動切り替え
    func updateToSystemLanguage() {
        let newLanguage = Self.getSystemPrimaryLanguage()
        if newLanguage != currentLanguage {
            currentLanguage = newLanguage
        }
    }
    
    private func updateLocale() {
        // Bundleベースの言語切り替えを使用
        Bundle.setLanguage(currentLanguage)
        
        // システムレベルの言語設定も更新
        UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // UIの更新を強制
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
        
        print("LanguageManager: Language changed to '\(currentLanguage)'")
    }
    
    static func getAvailableLanguages() -> [String] {
        return [
            "auto", "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr",
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
            "auto": "Auto-detect",
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
        print("LanguageManager: Setting language to '\(languageCode)' from '\(currentLanguage)'")
        
        // 有効な言語コードかチェック
        let supportedLanguages = Self.getAvailableLanguages()
        guard supportedLanguages.contains(languageCode) else {
            print("LanguageManager: Warning - Unsupported language code '\(languageCode)'. Ignoring.")
            return
        }
        
        // 同じ言語の場合はスキップ
        if currentLanguage == languageCode {
            print("LanguageManager: Language '\(languageCode)' is already selected.")
            return
        }
        
        currentLanguage = languageCode
        print("LanguageManager: Language successfully changed to '\(languageCode)'")
    }
}

// MARK: - SwiftUI Environment Support
extension EnvironmentValues {
    private struct LanguageManagerKey: EnvironmentKey {
        static let defaultValue = LanguageManager.shared
    }
    
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}
