//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Scribe. All rights reserved.

import Foundation
import SwiftUI
import WhisperKit

enum ModelState: CustomStringConvertible {
    case loaded
    case unloaded
    case loading
    case prewarming
    case unloading
    case prewarmed
    case downloading
    case downloaded
    
    var description: String {
        switch self {
        case .loaded: return "Loaded"
        case .unloaded: return "Unloaded"
        case .loading: return "Loading"
        case .prewarming: return "Prewarming"
        case .unloading: return "Unloading"
        case .prewarmed: return "Prewarmed"
        case .downloading: return "Downloading"
        case .downloaded: return "Downloaded"
        }
    }
}

@MainActor
class WhisperModelManager: ObservableObject {
    @Published var selectedModel: String = "openai_whisper-base"
    @Published var localModels: [String] = []
    @Published var modelState: ModelState = .unloaded
    @Published var whisperKit: WhisperKit?
    @Published var isOptimizing: Bool = false
    @Published var optimizationProgress: Float = 0.0
    @Published var optimizationStatus: String = ""
    
    var selectedModelDisplayName: String {
        return selectedModel.components(separatedBy: "_").dropFirst().joined(separator: " ")
    }
    
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
    
    func loadModel(_ model: String, redownload: Bool = false) async {
        modelState = .loading
        isOptimizing = true
        optimizationProgress = 0.0
        optimizationStatus = "Initializing..."
        
        // WhisperKitの初期化と設定は実際のモデル読み込み処理に委譲
        // ここでは状態管理のみを行う
        print("WhisperModelManager: Loading model \(model)")
    }
    
    func deleteModel(_ model: String) async {
        modelState = .unloading
        if selectedModel == model {
            whisperKit = nil
            modelState = .unloaded
        }
        removeLocalModel(model)
    }
    
    func updateOptimizationProgress(_ progress: Float, status: String) {
        optimizationProgress = progress
        optimizationStatus = status
    }
    
    func setWhisperKit(_ kit: WhisperKit?) {
        whisperKit = kit
        if kit != nil {
            modelState = .loaded
            isOptimizing = false
            optimizationProgress = 1.0
            optimizationStatus = "Loaded"
        } else {
            modelState = .unloaded
            isOptimizing = false
            optimizationProgress = 0.0
            optimizationStatus = ""
        }
    }
}
