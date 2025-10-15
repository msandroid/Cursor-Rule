//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import SwiftUI
import AVFoundation

struct TranCriptionTestView: View {
    @EnvironmentObject var tranCriptionServiceManager: TranCriptionServiceManager
    @EnvironmentObject var modelManager: WhisperModelManager
    @State private var isRecording = false
    @State private var tranCriptionResult: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Model Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Model")
                        .font(.headline)
                    
                    Text(modelManager.selectedModelDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isOpenAIModel(modelManager.selectedModel) {
                        HStack {
                            Image(systemName: "cloud")
                                .foregroundColor(.blue)
                            Text("Cloud-based tranCription")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    } else {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.green)
                            Text("Local tranCription")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Recording Controls
                VStack(spacing: 16) {
                    Button(action: toggleRecording) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title)
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing)
                    
                    if isProcessing {
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                
                // TranCription Result
                if !tranCriptionResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TranCription Result")
                            .font(.headline)
                        
                        ScrollView {
                            Text(tranCriptionResult)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("TranCription Test")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    private func isOpenAIModel(_ modelId: String) -> Bool {
        return modelId == "whisper-1" || modelId == "gpt-4o-transcribe" || modelId == "gpt-4o-mini-transcribe"
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // TODO: Implement actual recording functionality
        isRecording = true
        errorMessage = nil
    }
    
    private func stopRecording() {
        isRecording = false
        // TODO: Process recorded audio and call tranCription service
        testTranCription()
    }
    
    private func testTranCription() {
        isProcessing = true
        errorMessage = nil
        
        // テスト用のダミー音声データを作成
        let dummyAudioData = Data(count: 1024) // 1KB dummy data
        
        Task {
            do {
                let result = try await tranCriptionServiceManager.transcriptionAudio(
                    audioData: dummyAudioData,
                    language: "en"
                )
                
                await MainActor.run {
                    tranCriptionResult = result.text
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    TranCriptionTestView()
        .environmentObject(TranCriptionServiceManager())
        .environmentObject(WhisperModelManager())
}
