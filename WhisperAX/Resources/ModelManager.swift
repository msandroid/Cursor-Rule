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
        
        print("WhisperModelManager: Loading model \(model)")
        
        whisperKit = nil
        Task {
            // Check if the model is bundled in the app first
            var bundledModelPath: URL?
            
            // Try to find bundled model in Resources directory
            if let resourceURL = Bundle.main.resourceURL {
                let modelURL = resourceURL.appendingPathComponent(model)
                
                // Check if model directory exists and contains required files
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: modelURL.path) {
                    let audioEncoderPath = modelURL.appendingPathComponent("AudioEncoder.mlmodelc/model.mil")
                    let textDecoderPath = modelURL.appendingPathComponent("TextDecoder.mlmodelc/model.mil")
                    let melSpectrogramPath = modelURL.appendingPathComponent("MelSpectrogram.mlmodelc/model.mil")
                    
                    if fileManager.fileExists(atPath: audioEncoderPath.path) &&
                       fileManager.fileExists(atPath: textDecoderPath.path) &&
                       fileManager.fileExists(atPath: melSpectrogramPath.path) {
                        bundledModelPath = modelURL
                        print("Found bundled model at: \(modelURL.path)")
                    } else {
                        print("Model directory exists but missing required files at: \(modelURL.path)")
                    }
                } else {
                    print("Model directory not found at: \(modelURL.path)")
                }
            }
            
            let config = WhisperKitConfig(verbose: true,
                                          logLevel: .debug,
                                          prewarm: true,
                                          load: true,
                                          download: false,
                                          modelFolder: bundledModelPath)
            
            whisperKit = try await WhisperKit(config)
            guard let whisperKit = whisperKit else {
                await MainActor.run {
                    modelState = .unloaded
                    isOptimizing = false
                }
                return
            }
            
            await MainActor.run {
                optimizationProgress = 0.3
                optimizationStatus = "Loading model files..."
            }
            
            // WhisperKit with load: true will automatically load models
            await MainActor.run {
                modelState = .loaded
                isOptimizing = false
                optimizationProgress = 1.0
                optimizationStatus = "Model loaded successfully"
            }
        }
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
