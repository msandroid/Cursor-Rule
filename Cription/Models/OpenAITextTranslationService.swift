//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI

@MainActor
class OpenAITextTranslationService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var status: String = ""
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let subscriptionManager = SubCriptionManager()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translateText(text: String, targetLanguage: String) async throws -> String {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        // サブスクリプション制限チェック
        guard subscriptionManager.canUseOpenAITranCription() else {
            throw TranCriptionError.subscriptionLimitExceeded
        }
        
        // モデルアクセス制限チェック（GPT-4o-miniは常にクラウドモデル）
        guard subscriptionManager.canUseCloudModel("gpt-4o-mini") else {
            // Free planでクレジット不足の場合はinsufficientCreditsエラーを投げる
            if subscriptionManager.subCriptionTier == .free {
                throw TranCriptionError.insufficientCredits
            } else {
                throw TranCriptionError.modelAccessDenied
            }
        }
        
        isProcessing = true
        progress = 0.0
        status = "Translating to \(targetLanguage)..."
        error = nil
        
        defer {
            isProcessing = false
            progress = 0.0
            status = ""
        }
        
        do {
            progress = 0.2
            
            let translatedText = try await performTextTranslation(text: text, targetLanguage: targetLanguage)
            
            // クレジット消費（テキスト翻訳は短時間と仮定）
            let estimatedDuration = 1.0 // 1秒と仮定
            let success = subscriptionManager.consumeAPICredits(
                duration: estimatedDuration,
                model: "gpt-4o-mini",
                isTranslation: true
            )
            
            guard success else {
                throw TranCriptionError.insufficientCredits
            }
            
            status = "Translation completed!"
            progress = 1.0
            
            return translatedText
            
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    private func performTextTranslation(text: String, targetLanguage: String) async throws -> String {
        print("🔵 OpenAI Text Translation API call starting - model: gpt-4o-mini, target language: \(targetLanguage)")
        print("🔵 Text length: \(text.count) characters")
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let languageName = getLanguageFullName(for: targetLanguage)
        
        let systemPrompt = "You are a professional translator. Translate the given English text to \(languageName). Maintain the original meaning, tone, and formatting. Only return the translated text without any explanations or additional content."
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        status = "Processing translation with GPT-4o-mini..."
        progress = 0.5
        
        print("🔵 Sending request to OpenAI API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("🔵 Received response from OpenAI API")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw TranCriptionError.invalidResponse
        }
        
        print("🔵 HTTP status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API error \(httpResponse.statusCode): \(errorMessage)")
            
            switch httpResponse.statusCode {
            case 401:
                print("❌ Unauthorized: Invalid API key")
                throw TranCriptionError.apiError(401, "Invalid API key. Please check your OpenAI API key.")
            case 403:
                print("❌ Forbidden: Model access denied")
                throw TranCriptionError.apiError(403, "Model 'gpt-4o-mini' access denied.")
            case 429:
                print("❌ Rate limit exceeded")
                throw TranCriptionError.apiError(429, "Rate limit exceeded. Please try again later.")
            default:
                print("❌ API Error \(httpResponse.statusCode): \(errorMessage)")
                throw TranCriptionError.apiError(httpResponse.statusCode, errorMessage)
            }
        }
        
        status = "Parsing response..."
        progress = 0.8
        
        let translationResponse = try JSONDecoder().decode(GPTChatCompletionResponse.self, from: data)
        
        guard let translatedText = translationResponse.choices.first?.message.content else {
            print("❌ No translation content in response")
            throw TranCriptionError.invalidResponse
        }
        
        print("🔵 OpenAI Text Translation Response:")
        print("   - Target language: \(languageName)")
        print("   - Translated text preview: \(String(translatedText.prefix(100)))...")
        
        return translatedText
    }
    
    private func getLanguageFullName(for code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "zh": "Chinese",
            "de": "German",
            "es": "Spanish",
            "ru": "Russian",
            "ko": "Korean",
            "fr": "French",
            "ja": "Japanese",
            "pt": "Portuguese",
            "tr": "Turkish",
            "pl": "Polish",
            "ca": "Catalan",
            "nl": "Dutch",
            "ar": "Arabic",
            "sv": "Swedish",
            "it": "Italian",
            "id": "Indonesian",
            "hi": "Hindi",
            "fi": "Finnish",
            "vi": "Vietnamese",
            "he": "Hebrew",
            "uk": "Ukrainian",
            "el": "Greek",
            "ms": "Malay",
            "cs": "Czech",
            "ro": "Romanian",
            "da": "Danish",
            "hu": "Hungarian",
            "ta": "Tamil",
            "no": "Norwegian",
            "th": "Thai",
            "ur": "Urdu",
            "hr": "Croatian",
            "bg": "Bulgarian",
            "lt": "Lithuanian",
            "la": "Latin",
            "mi": "Maori",
            "ml": "Malayalam",
            "cy": "Welsh",
            "sk": "Slovak",
            "te": "Telugu",
            "fa": "Persian",
            "lv": "Latvian",
            "bn": "Bengali",
            "sr": "Serbian",
            "az": "Azerbaijani",
            "sl": "Slovenian",
            "kn": "Kannada",
            "et": "Estonian",
            "mk": "Macedonian",
            "br": "Breton",
            "eu": "Basque",
            "is": "Icelandic",
            "hy": "Armenian",
            "ne": "Nepali",
            "mn": "Mongolian",
            "bs": "Bosnian",
            "kk": "Kazakh",
            "sq": "Albanian",
            "sw": "Swahili",
            "gl": "Galician",
            "mr": "Marathi",
            "pa": "Punjabi",
            "si": "Sinhala",
            "km": "Khmer",
            "sn": "Shona",
            "yo": "Yoruba",
            "so": "Somali",
            "af": "Afrikaans",
            "oc": "Occitan",
            "ka": "Georgian",
            "be": "Belarusian",
            "tg": "Tajik",
            "sd": "Sindhi",
            "gu": "Gujarati",
            "am": "Amharic",
            "yi": "Yiddish",
            "lo": "Lao",
            "uz": "Uzbek",
            "fo": "Faroese",
            "ht": "Haitian Creole",
            "ps": "Pashto",
            "tk": "Turkmen",
            "nn": "Norwegian Nynorsk",
            "mt": "Maltese",
            "sa": "Sanskrit",
            "lb": "Luxembourgish",
            "my": "Burmese",
            "bo": "Tibetan",
            "tl": "Tagalog",
            "mg": "Malagasy",
            "as": "Assamese",
            "tt": "Tatar",
            "haw": "Hawaiian",
            "ln": "Lingala",
            "ha": "Hausa",
            "ba": "Bashkir",
            "jw": "Javanese",
            "su": "Sundanese",
            "yue": "Cantonese"
        ]
        
        return languageNames[code] ?? code
    }
}

private struct GPTChatCompletionResponse: Codable {
    let choices: [GPTChoice]
}

private struct GPTChoice: Codable {
    let message: GPTMessage
}

private struct GPTMessage: Codable {
    let content: String
}

