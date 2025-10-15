//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import AVFoundation

// MARK: - OpenAI Realtime Transcription Service (Official API with Delta Events)

@MainActor
class OpenAIRealtimeTranscriptionService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var realtimeText: String = ""
    @Published var error: String?
    @Published var audioSamples: [Float] = []
    
    private let apiKey: String
    private let baseURL = "wss://api.openai.com/v1/realtime"
    private let subscriptionManager = SubCriptionManager()
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var currentModel: String = "gpt-4o-mini-transcribe"
    private var currentLanguage: String?
    private var sessionReady = false
    private var isConnected = false
    private let connectionTimeout: TimeInterval = 30.0
    private let maxRetryAttempts: Int = 3
    private var retryCount: Int = 0
    private var waveformSamples: [Float] = []
    private let maxWaveformSamples = 1000
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }
    
    // MARK: - Public Methods
    
    func startRealtimeTranscription(model: String = "gpt-4o-mini-transcribe", language: String? = nil) async throws {
        guard !isRecording else {
            throw TranCriptionError.alreadyProcessing
        }
        
        // サブスクリプション制限チェック
        guard subscriptionManager.canUseOpenAITranCription() else {
            throw TranCriptionError.subscriptionLimitExceeded
        }
        
        // モデルアクセス制限チェック
        guard subscriptionManager.canUseCloudModel(model) else {
            throw TranCriptionError.modelAccessDenied
        }
        
        currentModel = model
        currentLanguage = language
        sessionReady = false
        error = nil
        retryCount = 0
        realtimeText = "Connecting..."
        
        print("✅ Starting realtime transcription with delta events")
        print("   - Model: \(currentModel)")
        print("   - Language: \(language ?? "auto")")
        print("   - Delta behavior: \(currentModel == "whisper-1" ? "Full transcript" : "Incremental")")
        
        // リトライ機能付きでWebSocket接続を確立
        do {
            try await connectWebSocketWithRetry()
        } catch {
            print("❌ Failed to establish WebSocket connection after retries")
            throw error
        }
        
        // セッションが準備完了するまで待機
        let startTime = Date()
        while !sessionReady && isConnected && error == nil {
            if Date().timeIntervalSince(startTime) > connectionTimeout {
                print("❌ Session setup timeout after \(connectionTimeout)s")
                throw TranCriptionError.apiError(408, "Session setup timeout")
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms待機
        }
        
        // エラーが発生した場合は例外をスロー
        if let errorMessage = error {
            throw TranCriptionError.apiError(400, errorMessage)
        }
        
        // 接続が切断された場合
        if !isConnected {
            throw TranCriptionError.apiError(0, "Connection lost")
        }
        
        print("✅ Session ready, starting audio capture")
        
        // オーディオ録音を開始
        try await startAudioCapture()
        
        isRecording = true
        realtimeText = "Listening..."
    }
    
    func stopRealtimeTranscription() async {
        isRecording = false
        sessionReady = false
        
        // クレジット消費（録音時間を推定）
        let estimatedDuration = Double(audioSamples.count) / 16000.0 // 16kHzサンプリングレート
        if estimatedDuration > 0 {
            let success = subscriptionManager.consumeAPICredits(
                duration: estimatedDuration,
                model: currentModel,
                isTranslation: false
            )
            
            if !success {
                error = "Insufficient credits for realtime transcription"
            }
        }
        
        // 波形サンプルをクリア
        waveformSamples = []
        audioSamples = []
        
        // オーディオ録音を停止
        stopAudioCapture()
        
        // WebSocket接続を切断
        disconnectWebSocket()
    }
    
    // MARK: - Private Methods - WebSocket
    
    private func connectWebSocketWithRetry() async throws {
        for attempt in 1...maxRetryAttempts {
            do {
                print("🔄 Connection attempt \(attempt)/\(maxRetryAttempts)")
                try await connectWebSocket()
                return // 成功した場合は終了
            } catch {
                print("❌ Connection attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxRetryAttempts {
                    let delay = TimeInterval(attempt * 2) // 指数バックオフ
                    print("⏳ Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("❌ All connection attempts failed")
                    throw error
                }
            }
        }
    }
    
    private func connectWebSocket() async throws {
        // Realtime API対応モデルにマッピング
        let realtimeModelMapping: [String: String] = [
            "whisper-1": "gpt-4o-realtime-preview-2024-12-17",
            "gpt-4o-transcribe": "gpt-4o-realtime-preview-2024-12-17", 
            "gpt-4o-mini-transcribe": "gpt-4o-mini-realtime-preview-2024-12-17"
        ]
        
        let realtimeModel = realtimeModelMapping[currentModel] ?? "gpt-4o-realtime-preview-2024-12-17"
        
        print("🔗 WebSocket connection initiated")
        print("   - User selected model: \(currentModel)")
        print("   - Mapped to realtime model: \(realtimeModel)")
        
        guard let url = URL(string: "\(baseURL)?model=\(realtimeModel)") else {
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.timeoutInterval = connectionTimeout
        
        // WebSocket専用の設定
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = connectionTimeout
        config.timeoutIntervalForResource = connectionTimeout
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        print("   - URL: \(url)")
        print("   - Timeout: \(connectionTimeout)s")
        
        // 接続完了を待機
        let startTime = Date()
        while !isConnected && Date().timeIntervalSince(startTime) < connectionTimeout {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms待機
        }
        
        guard isConnected else {
            throw TranCriptionError.apiError(408, "WebSocket connection timeout")
        }
        
        print("✅ WebSocket connected successfully")
        
        // WebSocketメッセージ受信ループを開始
        Task {
            await receiveMessages()
        }
        
        // セッション設定を送信
        try await sendSessionConfig()
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func sendSessionConfig() async throws {
        // 最小限の設定でサーバーエラーを回避
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text"],
                "input_audio_format": "pcm16"
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: sessionUpdate)
        let message = URLSessionWebSocketTask.Message.data(jsonData)
        try await webSocketTask?.send(message)
        
        print("✅ Session config sent (minimal format)")
        print("   - User model: \(currentModel)")
        print("   - Config: \(String(data: jsonData, encoding: .utf8) ?? "N/A")")
    }
    
    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            while isConnected {
                let message = try await webSocketTask.receive()
                
                switch message {
                case .data(let data):
                    await handleMessage(data: data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        await handleMessage(data: data)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            print("❌ WebSocket receive error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "WebSocket error: \(error.localizedDescription)"
                self.isConnected = false
                self.sessionReady = false
            }
        }
    }
    
    private func handleMessage(data: Data) async {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                print("⚠️ Failed to parse message type")
                return
            }
            
            print("📩 Received message type: \(type)")
            
            switch type {
            case "session.created":
                print("✅ Session created")
                await MainActor.run {
                    self.realtimeText = "Connecting..."
                }
                
            case "session.updated":
                print("✅ Session updated - ready for audio")
                await MainActor.run {
                    self.sessionReady = true
                    self.realtimeText = "Ready..."
                }
                
            case "response.audio_transcript.delta":
                // 公式のdeltaイベント：部分的な転写結果
                if let delta = json["delta"] as? String {
                    print("📝 Delta: \(delta)")
                    await MainActor.run {
                        if self.realtimeText == "Listening..." || self.realtimeText == "Ready..." {
                            self.realtimeText = delta
                        } else {
                            self.realtimeText += delta
                        }
                    }
                }
                
            case "response.audio_transcript.done":
                // 公式のcompletedイベント：最終的な転写結果
                if let transcript = json["transcript"] as? String {
                    print("✅ Transcription completed: \(transcript)")
                    await MainActor.run {
                        self.realtimeText = transcript
                    }
                }
                
            case "response.done":
                // 公式の完了イベント
                if let response = json["response"] as? [String: Any],
                   let status = response["status"] as? String,
                   status == "failed",
                   let statusDetails = response["status_details"] as? [String: Any],
                   let error = statusDetails["error"] as? [String: Any],
                   let errorMessage = error["message"] as? String {
                    print("❌ Response failed: \(errorMessage)")
                    await MainActor.run {
                        self.error = "Response failed: \(errorMessage)"
                    }
                }
                
            case "error":
                if let errorInfo = json["error"] as? [String: Any],
                   let message = errorInfo["message"] as? String {
                    print("❌ Realtime API Error: \(message)")
                    await MainActor.run {
                        self.error = message
                        self.sessionReady = false
                        self.isConnected = false
                    }
                    
                    // サーバーエラーの場合は自動リトライを停止
                    if message.contains("server had an error") || message.contains("internal server error") {
                        print("❌ Server error detected, stopping automatic reconnection")
                        print("   - This appears to be a server-side issue with OpenAI's Realtime API")
                        print("   - Please try again later or contact OpenAI support")
                    }
                }
                
            case "input_audio_buffer.speech_started":
                print("🎤 Speech started")
                await MainActor.run {
                    self.realtimeText = "Listening..."
                }
                
            case "input_audio_buffer.speech_stopped":
                print("🎤 Speech stopped")
                
            case "response.audio.delta":
                // 音声レスポンスのdelta（通常は転写では使用しない）
                print("🔊 Audio delta received")
                
            case "response.audio.done":
                // 音声レスポンスの完了（通常は転写では使用しない）
                print("🔊 Audio response completed")
                
            default:
                print("ℹ️ Unhandled message type: \(type)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("   Full message: \(jsonString)")
                }
            }
        } catch {
            print("❌ Failed to parse message: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to parse message: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods - Audio
    
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
        
        // 24kHz, mono, PCM16に変換するフォーマット（OpenAI Realtime API要件）
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        ) else {
            throw TranCriptionError.invalidAudioData
        }
        
        guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
            throw TranCriptionError.invalidAudioData
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                do {
                    // セッションが準備完了していない場合はスキップ
                    guard self.sessionReady else {
                        return
                    }
                    
                    // PCMバッファを変換
                    let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / recordingFormat.sampleRate)
                    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else {
                        return
                    }
                    
                    var error: NSError?
                    let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                        outStatus.pointee = .haveData
                        return buffer
                    }
                    
                    if status == .error, let error = error {
                        print("❌ Audio conversion error: \(error.localizedDescription)")
                        self.error = "Audio conversion error: \(error.localizedDescription)"
                        return
                    }
                    
                    // 波形表示用のサンプルを更新
                    self.updateWaveformSamples(from: convertedBuffer)
                    
                    // PCM16データをWebSocketで送信
                    try await self.sendAudioData(buffer: convertedBuffer)
                    
                } catch {
                    print("❌ Audio processing error: \(error.localizedDescription)")
                }
            }
        }
        
        try audioEngine.start()
    }
    
    private func stopAudioCapture() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
    }
    
    private func updateWaveformSamples(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Int16サンプルをFloatに変換して波形表示用に追加
        let floatSamples = samples.map { Float($0) / Float(Int16.max) }
        
        waveformSamples.append(contentsOf: floatSamples)
        
        // 最大サンプル数を超えた場合は古いサンプルを削除
        if waveformSamples.count > maxWaveformSamples {
            let removeCount = waveformSamples.count - maxWaveformSamples
            waveformSamples.removeFirst(removeCount)
        }
        
        // メインスレッドでUIを更新
        Task { @MainActor in
            self.audioSamples = self.waveformSamples
        }
    }
    
    private func sendAudioData(buffer: AVAudioPCMBuffer) async throws {
        // WebSocketが接続されているか確認
        guard let webSocketTask = webSocketTask, 
              webSocketTask.state == .running else {
            return
        }
        
        // セッションが準備完了しているか確認
        guard sessionReady else {
            return
        }
        
        guard let channelData = buffer.int16ChannelData else {
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        let data = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)
        
        // Base64エンコード
        let base64Audio = data.base64EncodedString()
        
        let message: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Audio
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: message)
        let webSocketMessage = URLSessionWebSocketTask.Message.data(jsonData)
        
        do {
            try await webSocketTask.send(webSocketMessage)
        } catch {
            print("❌ Failed to send audio data: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to send audio: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension OpenAIRealtimeTranscriptionService: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            print("✅ WebSocket connection opened")
            self.isConnected = true
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            print("❌ WebSocket connection closed: \(closeCode)")
            self.isConnected = false
            self.sessionReady = false
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                print("❌ WebSocket error: \(error.localizedDescription)")
                self.error = "WebSocket error: \(error.localizedDescription)"
                self.isConnected = false
                self.sessionReady = false
            }
        }
    }
}