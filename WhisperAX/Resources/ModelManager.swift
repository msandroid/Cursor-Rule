//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation
import SwiftUI

class WhisperModelManager: ObservableObject {
    @Published var selectedModel: String = "openai_whisper-base"
    @Published var localModels: [String] = []
    
    func addLocalModel(_ model: String) {
        if !localModels.contains(model) {
            localModels.append(model)
        }
    }
    
    func removeLocalModel(_ model: String) {
        localModels.removeAll { $0 == model }
    }
    
    func selectModel(_ modelId: String) {
        selectedModel = modelId
    }
}
