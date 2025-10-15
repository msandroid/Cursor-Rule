//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 AYUMU MIYATANI. All rights reserved.

import SwiftUI
import Foundation

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredLanguages: [String] {
        let languageManager = LanguageManager.shared
        if searchText.isEmpty {
            return languageManager.availableLanguages()
        } else {
            return languageManager.availableLanguages().filter { languageCode in
                let displayName = sourceLanguageDisplayName(for: languageCode)
                return displayName.localizedCaseInsensitiveContains(searchText) ||
                       languageCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// Source Language用の表示名を取得
    private func sourceLanguageDisplayName(for code: String) -> String {
        return LanguageManager.shared.languageDisplayName(for: code)
    }
    
    /// 言語コードから言語名を取得するヘルパー関数（Constants.swiftと同じロジック）
    private func getLanguageName(for languageCode: String) -> String {
        // Constants.languagesの逆引き（言語コード→言語名）
        let constantsLanguages: [String: String] = [
            "auto": "auto",
            "en": "english",
            "zh": "chinese",
            "de": "german",
            "es": "spanish",
            "ru": "russian",
            "ko": "korean",
            "fr": "french",
            "ja": "japanese",
            "pt": "portuguese",
            "tr": "turkish",
            "pl": "polish",
            "ca": "catalan",
            "nl": "dutch",
            "ar": "arabic",
            "sv": "swedish",
            "it": "italian",
            "id": "indonesian",
            "hi": "hindi",
            "fi": "finnish",
            "vi": "vietnamese",
            "he": "hebrew",
            "uk": "ukrainian",
            "el": "greek",
            "ms": "malay",
            "cs": "czech",
            "ro": "romanian",
            "da": "danish",
            "hu": "hungarian",
            "ta": "tamil",
            "no": "norwegian",
            "th": "thai",
            "ur": "urdu",
            "hr": "croatian",
            "bg": "bulgarian",
            "lt": "lithuanian",
            "la": "latin",
            "mi": "maori",
            "ml": "malayalam",
            "cy": "welsh",
            "sk": "slovak",
            "te": "telugu",
            "fa": "persian",
            "lv": "latvian",
            "bn": "bengali",
            "sr": "serbian",
            "az": "azerbaijani",
            "sl": "slovenian",
            "kn": "kannada",
            "et": "estonian",
            "mk": "macedonian",
            "br": "breton",
            "eu": "basque",
            "is": "icelandic",
            "hy": "armenian",
            "ne": "nepali",
            "mn": "mongolian",
            "bs": "bosnian",
            "kk": "kazakh",
            "sq": "albanian",
            "sw": "swahili",
            "gl": "galician",
            "mr": "marathi",
            "pa": "punjabi",
            "si": "sinhala",
            "km": "khmer",
            "sn": "shona",
            "yo": "yoruba",
            "so": "somali",
            "af": "afrikaans",
            "oc": "occitan",
            "ka": "georgian",
            "be": "belarusian",
            "tg": "tajik",
            "sd": "sindhi",
            "gu": "gujarati",
            "am": "amharic",
            "yi": "yiddish",
            "lo": "lao",
            "uz": "uzbek",
            "fo": "faroese",
            "ht": "haitian",
            "ps": "pashto",
            "tk": "turkmen",
            "nn": "nynorsk",
            "mt": "maltese",
            "sa": "sanskrit",
            "lb": "luxembourgish",
            "my": "myanmar",
            "bo": "tibetan",
            "tl": "tagalog",
            "mg": "malagasy",
            "as": "assamese",
            "tt": "tatar",
            "haw": "hawaiian",
            "ln": "lingala",
            "ha": "hausa",
            "ba": "bashkir",
            "jw": "javanese",
            "su": "sundanese",
            "yue": "cantonese"
        ]
        
        let result = constantsLanguages[languageCode] ?? "english"
        
        if result == "english" && languageCode != "en" {
            print("⚠️ getLanguageName: Language code '\(languageCode)' not found in mapping, defaulting to 'english'")
        }
        
        return result
    }
    
    /// 言語名から言語コードを取得するヘルパー関数（Constants.languagesと同じ）
    private func getLanguageCode(for languageName: String) -> String {
        // Constants.languagesと同じマッピング
        let constantsLanguages: [String: String] = [
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
        
        return constantsLanguages[languageName] ?? "ja" // デフォルトは日本語
    }
    
    /// 言語コードから言語名に変換
    private func languageCodeToLanguageName(_ code: String) -> String {
        let languageMapping: [String: String] = [
            "en": "english",
            "zh": "chinese",
            "de": "german",
            "es": "spanish",
            "ru": "russian",
            "ko": "korean",
            "fr": "french",
            "ja": "japanese",
            "pt": "portuguese",
            "tr": "turkish",
            "pl": "polish",
            "ca": "catalan",
            "nl": "dutch",
            "ar": "arabic",
            "sv": "swedish",
            "it": "italian",
            "id": "indonesian",
            "hi": "hindi",
            "fi": "finnish",
            "vi": "vietnamese",
            "he": "hebrew",
            "uk": "ukrainian",
            "el": "greek",
            "ms": "malay",
            "cs": "czech",
            "ro": "romanian",
            "da": "danish",
            "hu": "hungarian",
            "ta": "tamil",
            "no": "norwegian",
            "th": "thai",
            "ur": "urdu",
            "hr": "croatian",
            "bg": "bulgarian",
            "lt": "lithuanian",
            "la": "latin",
            "mi": "maori",
            "ml": "malayalam",
            "cy": "welsh",
            "sk": "slovak",
            "te": "telugu",
            "fa": "persian",
            "lv": "latvian",
            "bn": "bengali",
            "sr": "serbian",
            "az": "azerbaijani",
            "sl": "slovenian",
            "kn": "kannada",
            "et": "estonian",
            "mk": "macedonian",
            "br": "breton",
            "eu": "basque",
            "is": "icelandic",
            "hy": "armenian",
            "ne": "nepali",
            "mn": "mongolian",
            "bs": "bosnian",
            "kk": "kazakh",
            "sq": "albanian",
            "sw": "swahili",
            "gl": "galician",
            "mr": "marathi",
            "pa": "punjabi",
            "si": "sinhala",
            "km": "khmer",
            "sn": "shona",
            "yo": "yoruba",
            "so": "somali",
            "af": "afrikaans",
            "oc": "occitan",
            "ka": "georgian",
            "be": "belarusian",
            "tg": "tajik",
            "sd": "sindhi",
            "gu": "gujarati",
            "am": "amharic",
            "yi": "yiddish",
            "lo": "lao",
            "uz": "uzbek",
            "fo": "faroese",
            "ht": "haitian",
            "ps": "pashto",
            "tk": "turkmen",
            "nn": "nynorsk",
            "mt": "maltese",
            "sa": "sanskrit",
            "lb": "luxembourgish",
            "my": "myanmar",
            "bo": "tibetan",
            "tl": "tagalog",
            "mg": "malagasy",
            "as": "assamese",
            "tt": "tatar",
            "haw": "hawaiian",
            "ln": "lingala",
            "ha": "hausa",
            "ba": "bashkir",
            "jw": "javanese",
            "su": "sundanese",
            "yue": "cantonese"
        ]
        return languageMapping[code] ?? code
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField(String(localized: "Search languages..."), text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                
                // Language List
                List {
                    ForEach(filteredLanguages, id: \.self) { languageCode in
                        LanguageRow(
                            languageCode: languageCode,
                            displayName: sourceLanguageDisplayName(for: languageCode),
                            isSelected: {
                                // selectedLanguageが言語コードの場合と言語名の場合の両方をサポート
                                let isDirectCodeMatch = languageCode == selectedLanguage
                                let mappedCodeFromName = getLanguageCode(for: selectedLanguage)
                                let isCodeFromNameMatch = mappedCodeFromName == languageCode
                                
                                let finalSelection = isDirectCodeMatch || isCodeFromNameMatch
                                
                                // デバッグログ（最初の5言語のみ）
                                if ["en", "ja", "zh", "de", "es"].contains(languageCode) {
                                    print("🔍 Language \(languageCode): selectedLanguage='\(selectedLanguage)', directCodeMatch=\(isDirectCodeMatch), mappedCode='\(mappedCodeFromName)', codeFromNameMatch=\(isCodeFromNameMatch), finalSelection=\(finalSelection)")
                                }
                                
                                return finalSelection
                            }()
                        ) {
                            // 言語コードから言語名を取得して設定
                            let newLanguageName = getLanguageName(for: languageCode)
                            print("🔄 BEFORE SELECTION:")
                            print("  - languageCode: \(languageCode)")
                            print("  - oldSelectedLanguage: '\(selectedLanguage)'")
                            print("  - newLanguageName: '\(newLanguageName)'")
                            
                            selectedLanguage = newLanguageName
                            
                            // LanguageManagerには言語コードを設定
                            LanguageManager.shared.setLanguage(languageCode)
                            
                            print("🔄 AFTER SELECTION:")
                            print("  - selectedLanguage set to: '\(selectedLanguage)'")
                            print("  - LanguageManager set to: \(languageCode)")
                            print("  - Display name: \(sourceLanguageDisplayName(for: languageCode))")
                            
                            dismiss()
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
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
    }
}

struct LanguageRow: View {
    let languageCode: String
    let displayName: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(languageCode.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .symbolEffect(.bounce, value: isSelected)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? .primary : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

#Preview {
    LanguageSelectionView(selectedLanguage: .constant("en"))
}
