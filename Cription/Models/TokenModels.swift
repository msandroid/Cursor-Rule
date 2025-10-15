//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

/// 言語タイプ（Whisperでサポートされる100言語）
enum LanguageType: String, CaseIterable {
    // 主要言語
    case english = "English"
    case chinese = "Chinese"
    case german = "German"
    case spanish = "Spanish"
    case russian = "Russian"
    case korean = "Korean"
    case french = "French"
    case japanese = "Japanese"
    case portuguese = "Portuguese"
    case turkish = "Turkish"
    case polish = "Polish"
    case catalan = "Catalan"
    case dutch = "Dutch"
    case arabic = "Arabic"
    case swedish = "Swedish"
    case italian = "Italian"
    case indonesian = "Indonesian"
    case hindi = "Hindi"
    case finnish = "Finnish"
    case vietnamese = "Vietnamese"
    case hebrew = "Hebrew"
    case ukrainian = "Ukrainian"
    case greek = "Greek"
    case malay = "Malay"
    case czech = "Czech"
    case romanian = "Romanian"
    case danish = "Danish"
    case hungarian = "Hungarian"
    case tamil = "Tamil"
    case norwegian = "Norwegian"
    case thai = "Thai"
    case urdu = "Urdu"
    case croatian = "Croatian"
    case bulgarian = "Bulgarian"
    case lithuanian = "Lithuanian"
    case latin = "Latin"
    case maori = "Maori"
    case malayalam = "Malayalam"
    case welsh = "Welsh"
    case slovak = "Slovak"
    case telugu = "Telugu"
    case persian = "Persian"
    case latvian = "Latvian"
    case bengali = "Bengali"
    case serbian = "Serbian"
    case azerbaijani = "Azerbaijani"
    case slovenian = "Slovenian"
    case kannada = "Kannada"
    case estonian = "Estonian"
    case macedonian = "Macedonian"
    case breton = "Breton"
    case basque = "Basque"
    case icelandic = "Icelandic"
    case armenian = "Armenian"
    case nepali = "Nepali"
    case mongolian = "Mongolian"
    case bosnian = "Bosnian"
    case kazakh = "Kazakh"
    case albanian = "Albanian"
    case swahili = "Swahili"
    case galician = "Galician"
    case marathi = "Marathi"
    case punjabi = "Punjabi"
    case sinhala = "Sinhala"
    case khmer = "Khmer"
    case shona = "Shona"
    case yoruba = "Yoruba"
    case somali = "Somali"
    case afrikaans = "Afrikaans"
    case occitan = "Occitan"
    case georgian = "Georgian"
    case belarusian = "Belarusian"
    case tajik = "Tajik"
    case sindhi = "Sindhi"
    case gujarati = "Gujarati"
    case amharic = "Amharic"
    case yiddish = "Yiddish"
    case lao = "Lao"
    case uzbek = "Uzbek"
    case faroese = "Faroese"
    case haitianCreole = "Haitian Creole"
    case pashto = "Pashto"
    case turkmen = "Turkmen"
    case nynorsk = "Nynorsk"
    case maltese = "Maltese"
    case sanskrit = "Sanskrit"
    case luxembourgish = "Luxembourgish"
    case myanmar = "Myanmar"
    case tibetan = "Tibetan"
    case tagalog = "Tagalog"
    case malagasy = "Malagasy"
    case assamese = "Assamese"
    case tatar = "Tatar"
    case hawaiian = "Hawaiian"
    case lingala = "Lingala"
    case hausa = "Hausa"
    case bashkir = "Bashkir"
    case javanese = "Javanese"
    case sundanese = "Sundanese"
    case cantonese = "Cantonese"
    
    // 特殊ケース
    case mixed = "Mixed"
    case unknown = "Unknown"
    
    var tokenRatio: Double {
        switch self {
        // CJK言語（高密度）
        case .chinese, .japanese, .cantonese:
            return 1.2
        case .korean:
            return 1.3
        case .thai, .vietnamese, .lao, .khmer, .myanmar, .tibetan:
            return 1.4
            
        // インド系言語
        case .hindi, .bengali, .tamil, .telugu, .malayalam, .kannada, .gujarati, .marathi, .punjabi, .urdu, .sindhi, .nepali, .sinhala, .assamese:
            return 2.0
            
        // アラビア系言語
        case .arabic, .persian, .pashto, .turkmen, .tajik, .uzbek, .kazakh:
            return 2.5
            
        // キリル文字系
        case .russian, .ukrainian, .bulgarian, .macedonian, .serbian, .belarusian:
            return 3.0
            
        // ラテン文字系（ヨーロッパ）
        case .english, .spanish, .french, .german, .italian, .portuguese, .dutch, .swedish, .norwegian, .danish, .finnish, .polish, .czech, .slovak, .hungarian, .romanian, .croatian, .slovenian, .lithuanian, .latvian, .estonian, .icelandic, .faroese, .maltese, .luxembourgish:
            return 3.5
            
        // その他のラテン文字系
        case .turkish, .azerbaijani, .albanian, .basque, .catalan, .galician, .breton, .occitan:
            return 3.2
            
        // その他の文字体系
        case .greek, .armenian, .georgian, .mongolian, .amharic, .yiddish, .hebrew:
            return 2.8
            
        // アフリカ系言語
        case .swahili, .yoruba, .hausa, .shona, .lingala, .malagasy, .afrikaans, .somali:
            return 3.0
            
        // 太平洋系言語
        case .hawaiian, .maori, .tagalog, .javanese, .sundanese:
            return 3.2
            
        // その他の言語
        case .indonesian, .malay, .welsh, .bosnian, .tatar, .bashkir, .haitianCreole, .nynorsk:
            return 3.0
            
        // その他
        case .latin, .sanskrit:
            return 3.0
            
        // 特殊ケース
        case .mixed:
            return 2.5
        case .unknown:
            return 3.0
        }
    }
}

/// トークン統計情報
struct TokenStats {
    let tokenCount: Int
    let characterCount: Int
    let wordCount: Int
    let estimatedCost: Double
    let averageTokensPerWord: Double
    let averageCharactersPerToken: Double
    let detectedLanguage: LanguageType
    let languageConfidence: Double
    let audioDuration: Double  // 音声の長さ（秒）
    let selectedModel: String  // 使用モデル
    let isTranslation: Bool  // 翻訳処理かどうか
    let translationCost: Double  // 翻訳コスト
}
