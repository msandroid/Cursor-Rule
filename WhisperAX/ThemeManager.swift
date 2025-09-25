//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    private init() {
        // UserDefaultsから保存されたテーマ設定を読み込み
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
    
    var currentColorScheme: ColorScheme {
        return isDarkMode ? .dark : .light
    }
}
