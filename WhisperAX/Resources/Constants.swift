//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation

struct Constants {
    static let defaultLanguageCode = "auto"
    
    static let languages: [String: String] = [
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
    
    static let maxTokenContext = 448
    
    /// 言語コードから言語名を取得
    static func languageName(for code: String) -> String {
        for (name, langCode) in languages {
            if langCode == code {
                return name
            }
        }
        return code
    }
}
