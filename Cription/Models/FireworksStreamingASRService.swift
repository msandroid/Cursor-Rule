//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import AVFoundation

// MARK: - Fireworks Streaming ASR Service

@MainActor
class FireworksStreamingASRService: ObservableObject {
    @Published var isRecording = false
    @Published var streamingText = ""
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "wss://audio-streaming.us-virginia-1.direct.fireworks.ai/v1/audio/transcriptions/streaming"
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: [Float] = []
    private var bufferSize: Int = 0
    private let maxBufferSize = 16000 * 3 // 3秒分のバッファ
    
    init(apiKey: String) {
        self.apiKey = apiKey
        setupAudioSession()
    }
    
    deinit {
        Task { @MainActor in
            stopStreamingTranscription()
        }
    }
    
    // MARK: - Public Methods
    
    func startStreamingTranscription(model: String, language: String? = nil) async throws {
        guard !isRecording else {
            throw TranCriptionError.alreadyProcessing
        }
        
        isRecording = true
        streamingText = ""
        error = nil
        
        do {
            try await connectWebSocket(model: model, language: language)
            try await startAudioCapture()
        } catch {
            isRecording = false
            throw error
        }
    }
    
    func stopStreamingTranscription() {
        isRecording = false
        stopAudioCapture()
        disconnectWebSocket()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session setup completed")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            self.error = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    private func connectWebSocket(model: String, language: String?) async throws {
        // v2モデルまたはwhisper-v3モデルの場合は異なるエンドポイントを使用
        let endpoint: String
        if model.contains("v2") {
            endpoint = "wss://audio-streaming-v2.api.fireworks.ai/v1/audio/transcriptions/streaming"
        } else if model.contains("whisper-v3") {
            // whisper-v3モデルは通常のエンドポイントを使用
            endpoint = baseURL
        } else {
            endpoint = baseURL
        }
        let urlString = "\(endpoint)?model=\(model)"
        guard let url = URL(string: urlString) else {
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: request)
        
        webSocketTask?.resume()
        
        // 接続確認のため少し待機
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 初期メッセージを送信（Fireworks APIの仕様に合わせて調整）
        let initialMessage = [
            "model": model,
            "language": language ?? "auto",
            "stream": true,
            "response_format": "json"
        ] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: initialMessage),
           let message = String(data: data, encoding: .utf8) {
            try await webSocketTask?.send(.string(message))
        }
        
        // メッセージ受信を開始
        receiveMessages()
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.handleWebSocketMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.handleWebSocketMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    
                    // 次のメッセージを受信
                    if self?.isRecording == true {
                        self?.receiveMessages()
                    }
                    
                case .failure(let error):
                    self?.error = "WebSocket error: \(error.localizedDescription)"
                    self?.isRecording = false
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        print("📨 Received WebSocket message: \(message)")
        
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse WebSocket message as JSON")
            return
        }
        
        // Fireworks APIの応答形式に合わせて調整
        if let text = json["text"] as? String {
            streamingText = text
            print("✅ Updated streaming text: \(text)")
        } else if let transcription = json["transcription"] as? String {
            streamingText = transcription
            print("✅ Updated streaming text from transcription: \(transcription)")
        }
        
        if let error = json["error"] as? String {
            self.error = error
            print("❌ WebSocket error: \(error)")
        }
        
        // デバッグ用：受信したJSONの全内容をログ出力
        print("📋 Full WebSocket response: \(json)")
    }
    
    private func startAudioCapture() async throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw TranCriptionError.invalidAudioData
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw TranCriptionError.invalidAudioData
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 16kHzにリサンプリング
        let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                self?.processAudioBuffer(buffer, targetFormat: targetFormat)
            }
        }
        
        try audioEngine.start()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            return
        }
        
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
            return
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if error == nil, let channelData = convertedBuffer.floatChannelData {
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(convertedBuffer.frameLength)))
            audioBuffer.append(contentsOf: samples)
            
            // バッファサイズを制限
            if audioBuffer.count > maxBufferSize {
                audioBuffer.removeFirst(audioBuffer.count - maxBufferSize)
            }
            
            // 定期的に音声データを送信
            if audioBuffer.count >= 16000 { // 1秒分
                sendAudioData()
            }
        }
    }
    
    private func sendAudioData() {
        guard isRecording, !audioBuffer.isEmpty else { return }
        
        // 音声データをBase64エンコード
        let audioData = Data(bytes: audioBuffer, count: audioBuffer.count * MemoryLayout<Float>.size)
        let base64Audio = audioData.base64EncodedString()
        
        let message = [
            "audio": base64Audio,
            "format": "pcm_f32le",
            "sample_rate": 16000,
            "channels": 1
        ] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let messageString = String(data: data, encoding: .utf8) {
            Task {
                do {
                    try await webSocketTask?.send(.string(messageString))
                    print("🎵 Sent audio data chunk (\(audioBuffer.count) samples)")
                } catch {
                    print("❌ Failed to send audio data: \(error)")
                    self.error = "Failed to send audio data: \(error.localizedDescription)"
                }
            }
        }
        
        // バッファをクリア
        audioBuffer.removeAll()
    }
    
    private func stopAudioCapture() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        audioBuffer.removeAll()
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
    }
}
