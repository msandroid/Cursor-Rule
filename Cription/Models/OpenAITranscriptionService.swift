//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import WhisperKit

// MARK: - OpenAI TranCription Service

@MainActor
class OpenAITranCriptionService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var status: String = ""
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private let subscriptionManager = SubCriptionManager()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    func transcriptionAudio(audioData: Data, language: String? = nil, model: String = "whisper-1", customPrompt: String? = nil) async throws -> TranCriptionResult {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        // サブスクリプション制限チェック
        guard subscriptionManager.canUseOpenAITranCription() else {
            throw TranCriptionError.subscriptionLimitExceeded
        }
        
        // モデルアクセス制限チェック
        guard subscriptionManager.canUseCloudModel(model) else {
            // Free planでクレジット不足の場合はinsufficientCreditsエラーを投げる
            if subscriptionManager.subCriptionTier == .free {
                throw TranCriptionError.insufficientCredits
            } else {
                throw TranCriptionError.modelAccessDenied
            }
        }
        
        isProcessing = true
        progress = 0.0
        status = "Preparing tranCription..."
        error = nil
        
        defer {
            isProcessing = false
            progress = 0.0
            status = ""
        }
        
        do {
            // オーディオデータの基本検証
            guard !audioData.isEmpty else {
                print("❌ Audio data is empty")
                throw TranCriptionError.invalidAudioData
            }
            
            // ファイルサイズチェック（25MB制限）
            let maxFileSize = 25 * 1024 * 1024 // 25MB
            guard audioData.count <= maxFileSize else {
                print("❌ Audio file too large: \(audioData.count) bytes (max: \(maxFileSize))")
                throw TranCriptionError.fileTooLarge
            }
            
            // 最小サイズチェック（空でないことを確認）
            let minFileSize = 1024 // 1KB
            guard audioData.count >= minFileSize else {
                print("❌ Audio file too small: \(audioData.count) bytes (min: \(minFileSize))")
                throw TranCriptionError.invalidAudioData
            }
            
            print("✅ Audio data validation passed: \(audioData.count) bytes")
            
            status = "Uploading audio to OpenAI..."
            progress = 0.2
            
            // 言語が"auto"の場合はnilにして自動検出を有効化
            let finalLanguage = (language == "auto" || language == nil) ? nil : language
            
            let result = try await performTranCription(audioData: audioData, language: finalLanguage, model: model, customPrompt: customPrompt)
            
            // クレジットまたは使用量を消費
            let success = subscriptionManager.consumeAPICredits(
                duration: result.duration,
                model: model,
                isTranslation: false
            )
            
            guard success else {
                throw TranCriptionError.insufficientCredits
            }
            
            status = "TranCription completed!"
            progress = 1.0
            
            return result
            
        } catch {
            print("❌ OpenAI transcription failed: \(error)")
            if let tranCriptionError = error as? TranCriptionError {
                print("❌ TranCriptionError details: \(tranCriptionError)")
                self.error = tranCriptionError.localizedDescription
            } else {
                print("❌ Unexpected error type: \(type(of: error))")
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    func translateAudio(audioData: Data, model: String = "whisper-1", targetLanguage: String? = nil) async throws -> TranCriptionResult {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        // サブスクリプション制限チェック
        guard subscriptionManager.canUseOpenAITranCription() else {
            throw TranCriptionError.subscriptionLimitExceeded
        }
        
        // モデルアクセス制限チェック
        guard subscriptionManager.canUseCloudModel(model) else {
            // Free planでクレジット不足の場合はinsufficientCreditsエラーを投げる
            if subscriptionManager.subCriptionTier == .free {
                throw TranCriptionError.insufficientCredits
            } else {
                throw TranCriptionError.modelAccessDenied
            }
        }
        
        isProcessing = true
        progress = 0.0
        status = "Preparing translation..."
        error = nil
        
        defer {
            isProcessing = false
            progress = 0.0
            status = ""
        }
        
        do {
            // ファイルサイズチェック（25MB制限）
            let maxFileSize = 25 * 1024 * 1024 // 25MB
            guard audioData.count <= maxFileSize else {
                throw TranCriptionError.fileTooLarge
            }
            
            status = "Uploading audio to OpenAI..."
            progress = 0.2
            
            let result = try await performTranslation(audioData: audioData, model: model)
            
            // クレジットまたは使用量を消費
            let success = subscriptionManager.consumeAPICredits(
                duration: result.duration,
                model: model,
                isTranslation: true
            )
            
            guard success else {
                throw TranCriptionError.insufficientCredits
            }
            
            // targetLanguageが指定されている場合、さらにGPT-4o-miniで翻訳
            if let targetLanguage = targetLanguage, targetLanguage != "en" {
                status = "Translating to \(targetLanguage)..."
                progress = 0.6
                
                let textTranslationService = OpenAITextTranslationService(apiKey: apiKey)
                let translatedText = try await textTranslationService.translateText(text: result.text, targetLanguage: targetLanguage)
                
                return TranCriptionResult(
                    text: translatedText,
                    segments: [],
                    language: targetLanguage,
                    duration: result.duration
                )
            }
            
            status = "Translation completed!"
            progress = 1.0
            
            return result
            
        } catch {
            print("❌ OpenAI translation failed: \(error)")
            if let tranCriptionError = error as? TranCriptionError {
                print("❌ TranCriptionError details: \(tranCriptionError)")
                self.error = tranCriptionError.localizedDescription
            } else {
                print("❌ Unexpected error type: \(type(of: error))")
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func performTranCription(audioData: Data, language: String?, model: String, customPrompt: String? = nil) async throws -> TranCriptionResult {
        print("🔵 OpenAI API call starting - model: \(model), audioData size: \(audioData.count) bytes")
        if let lang = language {
            print("🔵 Language parameter: '\(lang)' (explicit language specified)")
        } else {
            print("🔵 Language parameter: nil (auto-detect mode)")
        }
        if let prompt = customPrompt {
            print("🔵 Custom prompt: '\(prompt)'")
        }
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        print("🔵 API request prepared - URL: \(baseURL)")
        
        // マルチパートフォームデータを作成（check-list.mdの実装に基づく）
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // モデル指定（最初に追加）
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendString("\(model)\r\n")
        
        // 言語指定（オプション）
        if let language = language {
            print("🔵 Adding language parameter to request: \(language)")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            body.appendString("\(language)\r\n")
        } else {
            print("✅ AUTO-DETECT MODE: No language parameter specified - OpenAI will detect the language automatically")
            print("   - This allows OpenAI to correctly identify the audio language (e.g., Japanese, English, etc.)")
        }
        
        // promptパラメータの設定（カスタムプロンプト優先）
        if let customPrompt = customPrompt, !customPrompt.isEmpty {
            // カスタムプロンプトがある場合はそれを使用
            print("🔵 Adding custom user prompt: \(customPrompt)")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            body.appendString("\(customPrompt)\r\n")
        } else if let language = language {
            // カスタムプロンプトがない場合は言語プロンプトを使用
            let languagePrompt = getLanguagePrompt(for: language)
            print("🔵 Adding language prompt to guide output language: \(languagePrompt)")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            body.appendString("\(languagePrompt)\r\n")
        }
        
        // ファイル部分（適切なMIMEタイプとファイル名）
        let (filename, mimeType) = detectAudioFormat(from: audioData)
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audioData)
        body.appendString("\r\n")
        
        // レスポンス形式とタイムスタンプ設定（モデルにより異なる）
        if model.contains("gpt-4o") {
            // gpt-4o系モデルはjsonのみサポート
            print("🔵 Using json response format for GPT-4o model")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
            body.appendString("json\r\n")
        } else {
            // whisper-1はverbose_jsonとtimestamp_granularitiesをサポート
            print("🔵 Using verbose_json response format for whisper-1 model")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
            body.appendString("verbose_json\r\n")
            
            // タイムスタンプ有効化（配列の各要素を個別に送信）
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n")
            body.appendString("word\r\n")
            
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n")
            body.appendString("segment\r\n")
        }
        
        body.appendString("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        // リクエスト概要をログ出力
        print("🔵 Request summary:")
        print("   - Endpoint: \(baseURL)")
        print("   - Model: \(model)")
        if let language = language {
            print("   - Language: \(language) (explicit)")
        } else {
            print("   - Language: nil (auto-detect mode)")
        }
        print("   - Body size: \(body.count) bytes")
        
        status = "Processing with OpenAI..."
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
            
            // 詳細なエラーハンドリング（check-list.mdに基づく）
            switch httpResponse.statusCode {
            case 401:
                print("❌ Unauthorized: Invalid API key")
                throw TranCriptionError.apiError(401, "Invalid API key. Please check your OpenAI API key.")
            case 403:
                print("❌ Forbidden: Model access denied")
                print("🔍 Make sure your API key has access to \(model) model.")
                print("🔍 Available models: whisper-1, gpt-4o-transcribe")
                print("🔍 You may need to enable the model in your OpenAI dashboard or use a different model.")
                throw TranCriptionError.apiError(403, "Model '\(model)' access denied. Please check your OpenAI API key permissions. Available models: whisper-1, gpt-4o-transcribe. You may need to select a different model or enable this model in your OpenAI dashboard.")
            case 413:
                print("❌ Payload Too Large: File size exceeds limit")
                throw TranCriptionError.apiError(413, "Audio file is too large. Please use a file smaller than 25MB.")
            case 404:
                print("❌ Model not found: \(model)")
                throw TranCriptionError.apiError(404, "Model '\(model)' not found. Please check the model name and ensure it's available in your account.")
            default:
                print("❌ API Error \(httpResponse.statusCode): \(errorMessage)")
                throw TranCriptionError.apiError(httpResponse.statusCode, errorMessage)
            }
        }
        
        status = "Parsing response..."
        progress = 0.8
        
        let tranCriptionResponse = try JSONDecoder().decode(OpenAITranCriptionResponse.self, from: data)
        
        print("🔵 OpenAI API Response:")
        print("   - Detected language: \(tranCriptionResponse.language ?? "unknown")")
        print("   - Text preview: \(String(tranCriptionResponse.text.prefix(100)))...")
        print("   - Duration: \(tranCriptionResponse.duration ?? 0.0)s")
        print("   - Segments count: \(tranCriptionResponse.segments?.count ?? 0)")
        
        return TranCriptionResult(
            text: tranCriptionResponse.text,
            segments: tranCriptionResponse.segments?.map { segment in
                TranCriptionSegment(
                    start: segment.start,
                    end: segment.end,
                    text: segment.text
                )
            } ?? [],
            language: tranCriptionResponse.language ?? "unknown",
            duration: tranCriptionResponse.duration ?? 0.0
        )
    }
    
    private func performTranslation(audioData: Data, model: String) async throws -> TranCriptionResult {
        print("🔵 OpenAI Translation API call starting - model: \(model), audioData size: \(audioData.count) bytes")
        print("⚠️ TRANSLATION MODE: Output will always be in English")
        
        let translationURL = "https://api.openai.com/v1/audio/translations"
        
        guard let url = URL(string: translationURL) else {
            print("❌ Invalid URL: \(translationURL)")
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        print("🔵 API request prepared - URL: \(translationURL)")
        
        // マルチパートフォームデータを作成
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // モデル指定
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.appendString("\(model)\r\n")
        
        // ファイル部分
        let (filename, mimeType) = detectAudioFormat(from: audioData)
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audioData)
        body.appendString("\r\n")
        
        // レスポンス形式指定（translationsはverbose_jsonをサポートしない）
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        body.appendString("json\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        status = "Processing translation with OpenAI..."
        progress = 0.5
        
        print("🔵 Sending request to OpenAI Translation API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("🔵 Received response from OpenAI Translation API")
        
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
                throw TranCriptionError.apiError(403, "Model '\(model)' access denied. Note: Translations only support whisper-1 model.")
            case 413:
                print("❌ Payload Too Large: File size exceeds limit")
                throw TranCriptionError.apiError(413, "Audio file is too large. Please use a file smaller than 25MB.")
            case 404:
                print("❌ Model not found: \(model)")
                throw TranCriptionError.apiError(404, "Model '\(model)' not found. Translations only support whisper-1 model.")
            default:
                print("❌ API Error \(httpResponse.statusCode): \(errorMessage)")
                throw TranCriptionError.apiError(httpResponse.statusCode, errorMessage)
            }
        }
        
        status = "Parsing response..."
        progress = 0.8
        
        // 翻訳APIはシンプルなJSONレスポンスのみを返す
        let translationResponse = try JSONDecoder().decode(OpenAITranslationResponse.self, from: data)
        
        return TranCriptionResult(
            text: translationResponse.text,
            segments: [],
            language: "en",  // 翻訳は常に英語
            duration: 0.0
        )
    }
    
    // MARK: - Helper Methods
    
    private func getLanguagePrompt(for languageCode: String) -> String {
        // 言語コードに基づいて、モデルに出力言語を指示するプロンプトを生成
        // OpenAI Whisperが対応する99言語全てをカバー
        let languagePrompts: [String: String] = [
            // 主要言語
            "en": "The following is English audio.",
            "zh": "以下是中文语音。",
            "de": "Das Folgende ist Audio auf Deutsch.",
            "es": "El siguiente es audio en español.",
            "ru": "Следующее - аудио на русском языке.",
            "ko": "다음은 한국어 음성입니다.",
            "fr": "Ce qui suit est un audio en français.",
            "ja": "誤字脱字は修正",
            "pt": "O seguinte é áudio em português.",
            "tr": "Aşağıdaki Türkçe sestir.",
            
            // ヨーロッパ言語
            "pl": "Poniżej znajduje się nagranie w języku polskim.",
            "ca": "El següent és àudio en català.",
            "nl": "Het volgende is audio in het Nederlands.",
            "sv": "Följande är ljud på svenska.",
            "it": "Il seguente è audio in italiano.",
            "fi": "Seuraava on ääni suomeksi.",
            "uk": "Нижче наведено аудіо українською мовою.",
            "el": "Ακολουθεί ήχος στα ελληνικά.",
            "cs": "Následující je audio v češtině.",
            "ro": "Următorul este audio în română.",
            "da": "Følgende er lyd på dansk.",
            "hu": "A következő hang magyarul.",
            "no": "Følgende er lyd på norsk.",
            "hr": "Sljedeći je audio na hrvatskom.",
            "bg": "Следващото е аудио на български.",
            "lt": "Toliau pateikiamas garsas lietuvių kalba.",
            "la": "Sequens est audio in Latina.",
            "cy": "Mae'r canlynol yn sain yn Gymraeg.",
            "sk": "Nasledujúci je zvuk v slovenčine.",
            "lv": "Tālāk ir audio latviešu valodā.",
            "sr": "Следеће је аудио на српском.",
            "sl": "Naslednji je zvok v slovenščini.",
            "et": "Järgnev on heli eesti keeles.",
            "mk": "Следново е аудио на македонски.",
            "br": "Ar pezh a zeu a zo son e brezhoneg.",
            "eu": "Hurrengoa euskarazko audioa da.",
            "is": "Eftirfarandi er hljóð á íslensku.",
            "nn": "Følgjande er lyd på nynorsk.",
            "mt": "Li jmiss huwa awdjo bil-Malti.",
            "lb": "Déi folgend ass Audio op Lëtzebuergesch.",
            
            // 中東・南アジア言語
            "ar": "التالي هو صوت باللغة العربية.",
            "he": "להלן שמע בעברית.",
            "fa": "موارد زیر صدا به زبان فارسی است.",
            "ur": "مندرجہ ذیل اردو آڈیو ہے۔",
            "ps": "لاندې په پښتو کې غږ دی.",
            "sd": "هيٺ ڏنل سنڌي آڊيو آهي.",
            
            // 南アジア・東南アジア言語
            "hi": "निम्नलिखित हिंदी ऑडियो है।",
            "th": "ต่อไปนี้เป็นเสียงภาษาไทย",
            "vi": "Sau đây là âm thanh tiếng Việt.",
            "id": "Berikut adalah audio dalam bahasa Indonesia.",
            "ms": "Berikut adalah audio dalam Bahasa Melayu.",
            "ta": "பின்வருவது தமிழ் ஆடியோ ஆகும்.",
            "ml": "താഴെ കൊടുത്തിരിക്കുന്നത് മലയാളം ഓഡിയോ ആണ്.",
            "te": "క్రింది తెలుగు ఆడియో.",
            "kn": "ಈ ಕೆಳಗಿನ ಕನ್ನಡ ಆಡಿಯೋ.",
            "mr": "खालील मराठी ऑडिओ आहे.",
            "gu": "નીચે ગુજરાતી ઓડિયો છે.",
            "bn": "নিম্নলিখিত বাংলা অডিয়ো।",
            "pa": "ਹੇਠਾਂ ਪੰਜਾਬੀ ਆਡੀਓ ਹੈ।",
            "si": "පහත සිංහල ශ්‍රව්‍ය වේ.",
            "km": "ខាងក្រោមគឺជាសំឡេងភាសាខ្មែរ។",
            "lo": "ຕໍ່ໄປນີ້ແມ່ນສຽງພາສາລາວ.",
            "my": "အောက်ပါမှာ မြန်မာ အသံ ဖြစ်ပါတယ်။",
            "ne": "निम्न नेपाली अडियो हो।",
            "as": "তলত অসমীয়া অডিঅ' আছে।",
            "tl": "Ang sumusunod ay audio sa Tagalog.",
            "jw": "Ing ngisor iki audio ing basa Jawa.",
            "su": "Ieu di handap audio dina basa Sunda.",
            
            // 東アジア言語
            "yue": "以下係粵語語音。",
            "mn": "Дараах нь монгол хэл дээрх аудио юм.",
            "bo": "འདི་ནི་བོད་ཀྱི་སྒྲ་ཡིན།",
            
            // その他のアジア・太平洋言語
            "hy": "Հետևյալն է հայերեն աուդիո։",
            "az": "Aşağıdakı azərbaycan dilində səsdir.",
            "be": "Наступны - аўдыё на беларускай мове.",
            "bs": "Sljedeće je audio na bosanskom.",
            "ka": "შემდეგი არის აუდიო ქართულად.",
            "kk": "Төменде қазақша аудио.",
            "tg": "Зерин садои тоҷикӣ аст.",
            "uz": "Quyida o'zbek tilida audio.",
            "tk": "Aşakdaky türkmen dilinde ses.",
            "tt": "Түбәндә татар телендә аудио.",
            "ba": "Киләһе башҡорт телендә аудио.",
            
            // アフリカ言語
            "af": "Die volgende is klank in Afrikaans.",
            "sw": "Ifuatayo ni sauti katika Kiswahili.",
            "am": "ከዚህ በታች በአማርኛ የድምጽ ነው።",
            "ha": "Mai zuwa yana sauti a Hausa.",
            "yo": "Atẹle jẹ ohun ni ede Yoruba.",
            "so": "Soo socda waa cod Soomaali ah.",
            "sn": "Zvinotevera ndiyo inzwi muchiShona.",
            "mg": "Izay manaraka dia feo amin'ny teny Malagasy.",
            "ln": "Oyo elandi ezali mongongo na Lingala.",
            
            // その他の言語
            "mi": "Ko te mea e whai ake nei he oro i te reo Māori.",
            "sq": "Sa vijon është audio në shqip.",
            "gl": "O seguinte é audio en galego.",
            "oc": "Lo seguent es àudio en occitan.",
            "fo": "Fylgjandi er ljóð á føroyskt.",
            "ht": "Sa ki annapre a se odyo an kreyòl ayisyen.",
            "sa": "अधः संस्कृतम् ऑडियो अस्ति।",
            "yi": "די פֿאָלגנדע איז אַודיאָ אויף ייִדיש.",
            "haw": "ʻO ka mea e hiki mai nei he leo ʻōlelo Hawaiʻi."
        ]
        
        // 言語プロンプトが見つからない場合は、英語でフォールバック
        if let prompt = languagePrompts[languageCode] {
            return prompt
        } else {
            print("⚠️ No specific prompt for language code '\(languageCode)', using fallback")
            return "The following is audio in \(languageCode) language."
        }
    }
    
    private func detectAudioFormat(from audioData: Data) -> (filename: String, mimeType: String) {
        // オーディオデータの基本検証
        guard !audioData.isEmpty else {
            print("❌ Cannot detect format: audio data is empty")
            return ("audio.mp3", "audio/mpeg") // デフォルト
        }
        
        // マジックバイトでファイル形式を検出
        let prefix = audioData.prefix(12)
        
        // MP3 (starts with FF FB or FF F3 or FF F2 or ID3)
        if prefix.count >= 2 {
            if prefix[0] == 0xFF && (prefix[1] & 0xE0) == 0xE0 {
                print("🔍 Detected audio format: MP3")
                return ("audio.mp3", "audio/mpeg")
            }
        }
        
        if prefix.count >= 3 {
            if prefix[0] == 0x49 && prefix[1] == 0x44 && prefix[2] == 0x33 {  // ID3
                print("🔍 Detected audio format: MP3 with ID3 tag")
                return ("audio.mp3", "audio/mpeg")
            }
        }
        
        // M4A/MP4 (starts with ftyp)
        if prefix.count >= 8 {
            if prefix[4] == 0x66 && prefix[5] == 0x74 && prefix[6] == 0x79 && prefix[7] == 0x70 {
                print("🔍 Detected audio format: M4A/MP4")
                return ("audio.m4a", "audio/mp4")
            }
        }
        
        // WAV (starts with RIFF....WAVE)
        if prefix.count >= 12 {
            if prefix[0] == 0x52 && prefix[1] == 0x49 && prefix[2] == 0x46 && prefix[3] == 0x46 &&
               prefix[8] == 0x57 && prefix[9] == 0x41 && prefix[10] == 0x56 && prefix[11] == 0x45 {
                print("🔍 Detected audio format: WAV")
                return ("audio.wav", "audio/wav")
            }
        }
        
        // FLAC (starts with fLaC)
        if prefix.count >= 4 {
            if prefix[0] == 0x66 && prefix[1] == 0x4C && prefix[2] == 0x61 && prefix[3] == 0x43 {
                print("🔍 Detected audio format: FLAC")
                return ("audio.flac", "audio/flac")
            }
        }
        
        // OGG (starts with OggS)
        if prefix.count >= 4 {
            if prefix[0] == 0x4F && prefix[1] == 0x67 && prefix[2] == 0x67 && prefix[3] == 0x53 {
                print("🔍 Detected audio format: OGG")
                return ("audio.ogg", "audio/ogg")
            }
        }
        
        // WebM (starts with 0x1A 0x45 0xDF 0xA3)
        if prefix.count >= 4 {
            if prefix[0] == 0x1A && prefix[1] == 0x45 && prefix[2] == 0xDF && prefix[3] == 0xA3 {
                print("🔍 Detected audio format: WebM")
                return ("audio.webm", "audio/webm")
            }
        }
        
        // デフォルトはMP3として扱う（最も一般的なフォーマット）
        print("⚠️ Unknown audio format, defaulting to MP3")
        return ("audio.mp3", "audio/mpeg")
    }
}

// MARK: - Supporting Types


// MARK: - TranCription Service Supporting Types

// MARK: - OpenAI API Response Models

private struct OpenAITranCriptionResponse: Codable {
    let text: String
    let language: String?
    let duration: Double?
    let segments: [OpenAISegment]?
}

private struct OpenAITranslationResponse: Codable {
    let text: String
}

private struct OpenAISegment: Codable {
    let start: Double
    let end: Double
    let text: String
}

// MARK: - Data Extension for String Appending

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

