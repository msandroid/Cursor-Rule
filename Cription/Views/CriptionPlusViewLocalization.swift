//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

class CriptionPlusViewLocalization {
    static let shared = CriptionPlusViewLocalization()
    
    private init() {
        // Localizable.xcstringsのみを使用
    }
    
    func localizedString(for key: String, language: String = Locale.current.languageCode ?? "en") -> String {
        // Localizable.xcstringsから取得
        let localizedString = NSLocalizedString(key, comment: "")
        if localizedString != key {
            return localizedString
        }
        
        // フォールバック: キーをそのまま返す
        return key
    }
    
    func localizedString(for key: String, language: String = Locale.current.languageCode ?? "en", arguments: [String: String]) -> String {
        var text = localizedString(for: key, language: language)
        
        for (placeholder, value) in arguments {
            text = text.replacingOccurrences(of: "{\(placeholder)}", with: value)
        }
        
        return text
    }
}

// MARK: - Convenience Extensions
extension CriptionPlusViewLocalization {
    func title(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.title", language: language)
    }
    
    func subtitle(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.subtitle", language: language)
    }
    
    func choosePlan(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.choose_plan", language: language)
    }
    
    func weekly(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.weekly", language: language)
    }
    
    func monthly(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.monthly", language: language)
    }
    
    func yearly(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.yearly", language: language)
    }
    
    func perWeek(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.per_week", language: language)
    }
    
    func perMonth(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.per_month", language: language)
    }
    
    func perYear(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.per_year", language: language)
    }
    
    func weeklyDescription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.weekly_description", language: language)
    }
    
    func monthlyDescription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.monthly_description", language: language)
    }
    
    func yearlyDescription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.yearly_description", language: language)
    }
    
    func liveTranscription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.live_transcription", language: language)
    }
    
    func liveTranscriptionDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.live_transcription_desc", language: language)
    }
    
    func languageTranslation(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.language_translation", language: language)
    }
    
    func languageTranslationDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.language_translation_desc", language: language)
    }
    
    func offlineTranscription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.offline_transcription", language: language)
    }
    
    func offlineTranscriptionDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.offline_transcription_desc", language: language)
    }
    
    func fileTranscription(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.file_transcription", language: language)
    }
    
    func fileTranscriptionDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.file_transcription_desc", language: language)
    }
    
    func fileTranslation(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.file_translation", language: language)
    }
    
    func fileTranslationDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.file_translation_desc", language: language)
    }
    
    func exportTextAudio(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.export_text_audio", language: language)
    }
    
    func exportTextAudioDesc(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.export_text_audio_desc", language: language)
    }
    
    func privacyPolicy(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.privacy_policy", language: language)
    }
    
    func termsOfUse(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.terms_of_use", language: language)
    }
    
    func upgradeButton(price: String, language: String = Locale.current.languageCode ?? "en") -> String {
        let format = localizedString(for: "CriptionPlus.upgrade_button", language: language)
        return String(format: format, price)
    }
    
    func processing(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.processing", language: language)
    }
    
    func autoRenews(period: String, language: String = Locale.current.languageCode ?? "en") -> String {
        let format = localizedString(for: "CriptionPlus.auto_renews", language: language)
        return String(format: format, period)
    }
    
    func termsAgreement(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.terms_agreement", language: language)
    }
    
    func purchaseError(language: String = Locale.current.languageCode ?? "en") -> String {
        return localizedString(for: "CriptionPlus.purchase_error", language: language)
    }
}
