//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import Foundation

struct FontSettings: Codable {
    var family: String
    var size: Double
    
    static let `default` = FontSettings(family: "System", size: 16.0)
}

class FontSettingsManager: ObservableObject {
    @Published var settings: FontSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "FontSettings"
    
    init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(FontSettings.self, from: data) {
            self.settings = decodedSettings
        } else {
            self.settings = FontSettings.default
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func resetToDefault() {
        settings = FontSettings.default
    }
}

// Available font families for STT display
struct FontFamily {
    let name: String
    let displayName: String
    let font: Font
    
    static let availableFonts: [FontFamily] = [
        // English
        FontFamily(name: "System", displayName: "System (English)", font: .system(.body)),
        FontFamily(name: "Helvetica", displayName: "Helvetica", font: .custom("Helvetica", size: 16)),
        FontFamily(name: "Arial", displayName: "Arial", font: .custom("Arial", size: 16)),
        FontFamily(name: "TimesNewRoman", displayName: "Times New Roman", font: .custom("TimesNewRomanPSMT", size: 16)),
        FontFamily(name: "Georgia", displayName: "Georgia", font: .custom("Georgia", size: 16)),
        FontFamily(name: "Verdana", displayName: "Verdana", font: .custom("Verdana", size: 16)),
        FontFamily(name: "TrebuchetMS", displayName: "Trebuchet MS", font: .custom("TrebuchetMS", size: 16)),
        // Chinese (Mandarin)
        FontFamily(name: "PingFangSC", displayName: "PingFang SC (Chinese)", font: .custom("PingFangSC-Regular", size: 16)),
        FontFamily(name: "HeitiSC", displayName: "Heiti SC (Chinese)", font: .custom("STHeitiSC-Medium", size: 16)),
        // Japanese
        FontFamily(name: "HiraginoSans", displayName: "Hiragino Sans (Japanese)", font: .custom("HiraginoSans-W3", size: 16)),
        FontFamily(name: "YuGothic", displayName: "Yu Gothic (Japanese)", font: .custom("YuGothic-Medium", size: 16)),
        FontFamily(name: "ToppanBunkyuMidashiGoStdN", displayName: "Toppan Bunkyu Midashi Go StdN (Japanese)", font: .custom("ToppanBunkyuMidashiGoStdN", size: 16)),
        // Korean
        FontFamily(name: "AppleSDGothicNeo", displayName: "Apple SD Gothic Neo (Korean)", font: .custom("AppleSDGothicNeo-Regular", size: 16)),
        // Hindi
        FontFamily(name: "DevanagariSangamMN", displayName: "Devanagari Sangam MN (Hindi)", font: .custom("DevanagariSangamMN", size: 16)),
        // Spanish (use English fonts)
        // French (use English fonts)
        // Arabic
        FontFamily(name: "GeezaPro", displayName: "Geeza Pro (Arabic)", font: .custom("GeezaPro", size: 16)),
        // Bengali
        FontFamily(name: "BanglaSangamMN", displayName: "Bangla Sangam MN (Bengali)", font: .custom("BanglaSangamMN", size: 16)),
        // Russian
        FontFamily(name: "ArialCyrillic", displayName: "Arial (Cyrillic/Russian)", font: .custom("Arial", size: 16)),
        // Portuguese (use English fonts)
        // Urdu
        FontFamily(name: "Nastaeen", displayName: "Nastaeen (Urdu)", font: .custom("Nastaeen", size: 16)), // May not be available on all systems
        // German (use English fonts)
        // Italian (use English fonts)
        // Indonesian / Malay
        FontFamily(name: "Avenir", displayName: "Avenir (Indonesian / Malay)", font: .custom("Avenir", size: 16)),
        // Thai
        FontFamily(name: "Thonburi", displayName: "Thonburi (Thai)", font: .custom("Thonburi", size: 16)),
        FontFamily(name: "SukhumvitSet", displayName: "Sukhumvit Set (Thai)", font: .custom("SukhumvitSet-Text", size: 16)),
        // Other useful monospace and decorative fonts
        FontFamily(name: "Menlo", displayName: "Menlo", font: .custom("Menlo", size: 16)),
        FontFamily(name: "Monaco", displayName: "Monaco", font: .custom("Monaco", size: 16)),
        FontFamily(name: "SFMono", displayName: "SF Mono", font: .custom("SFMono-Regular", size: 16)),
        FontFamily(name: "AvenirNext", displayName: "Avenir Next", font: .custom("AvenirNext-Regular", size: 16)),
        FontFamily(name: "Futura", displayName: "Futura", font: .custom("Futura-Medium", size: 16)),
        FontFamily(name: "GillSans", displayName: "Gill Sans", font: .custom("GillSans", size: 16)),
        FontFamily(name: "Optima", displayName: "Optima", font: .custom("Optima-Regular", size: 16)),
        FontFamily(name: "Palatino", displayName: "Palatino", font: .custom("Palatino-Roman", size: 16)),
        FontFamily(name: "Didot", displayName: "Didot", font: .custom("Didot", size: 16)),
        FontFamily(name: "Copperplate", displayName: "Copperplate", font: .custom("Copperplate", size: 16)),
        FontFamily(name: "Baskerville", displayName: "Baskerville", font: .custom("Baskerville", size: 16)),
        FontFamily(name: "ChalkboardSE", displayName: "Chalkboard SE", font: .custom("ChalkboardSE-Regular", size: 16)),
        FontFamily(name: "Noteworthy", displayName: "Noteworthy", font: .custom("Noteworthy-Regular", size: 16)),
        FontFamily(name: "Papyrus", displayName: "Papyrus", font: .custom("Papyrus", size: 16)),
        FontFamily(name: "MarkerFelt", displayName: "Marker Felt", font: .custom("MarkerFelt-Thin", size: 16))
    ]
    
    static func fontFamily(named name: String) -> FontFamily? {
        return availableFonts.first { $0.name == name }
    }
    
    func font(withSize size: Double) -> Font {
        if name == "System" {
            return .system(size: size)
        } else {
            return .custom(name, size: size)
        }
    }
}
