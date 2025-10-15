//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation
import SwiftUI
import AVFoundation

// MARK: - OpenAI Streaming Transcription Service

@MainActor
class OpenAIStreamingTranscriptionService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var streamingText: String = ""
    @Published var error: String?
    @Published var audioSamples: [Float] = []
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/transcriptions"
    private let subscriptionManager = SubCriptionManager()
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: [Int16] = []
    private let bufferSizeThreshold = 48000  // 増加: 24000 → 48000 (2秒 → 2秒、API呼び出し回数を削減)
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.cription.streaming", qos: .userInitiated)
    private var currentModel: String = "gpt-4o-mini-transcribe"
    private var waveformSamples: [Float] = []
    private let maxWaveformSamples = 1000
    
    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }
    
    // MARK: - Public Methods
    
    func startStreamingTranscription(model: String = "gpt-4o-mini-transcribe", language: String? = nil) async throws {
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
        isRecording = true
        error = nil
        streamingText = "Listening..."
        audioBuffer = []
        
        print("✅ Starting streaming transcription")
        print("   - Model: \(currentModel)")
        print("   - Language: \(language ?? "auto")")
        print("   - Using OpenAI Streaming Transcription (Fallback)")
        
        // オーディオ録音を開始
        try await startAudioCapture(language: language)
    }
    
    func stopStreamingTranscription() async {
        isRecording = false
        
        // 残りのバッファを処理
        if !audioBuffer.isEmpty {
            await processAudioBuffer(language: nil, isFinal: true)
        }
        
        // クレジット消費（録音時間を推定）
        let estimatedDuration = Double(audioBuffer.count) / 16000.0 // 16kHzサンプリングレート
        if estimatedDuration > 0 {
            let success = subscriptionManager.consumeAPICredits(
                duration: estimatedDuration,
                model: currentModel,
                isTranslation: false
            )
            
            if !success {
                error = "Insufficient credits for streaming transcription"
            }
        }
        
        // 波形サンプルをクリア
        waveformSamples = []
        audioSamples = []
        
        // オーディオ録音を停止
        stopAudioCapture()
    }
    
    // MARK: - Private Methods
    
    private func startAudioCapture(language: String?) async throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw TranCriptionError.invalidAudioData
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            throw TranCriptionError.invalidAudioData
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 24kHz, mono, PCM16に変換するフォーマット
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
                guard self.isRecording else { return }
                
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
                    return
                }
                
                // PCM16データをバッファに追加
                self.appendAudioData(buffer: convertedBuffer, language: language)
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
    
    private func appendAudioData(buffer: AVAudioPCMBuffer, language: String?) {
        guard let channelData = buffer.int16ChannelData else {
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        audioBuffer.append(contentsOf: samples)
        
        // 波形表示用のサンプルを更新
        updateWaveformSamples(from: samples)
        
        // バッファが閾値を超えたら処理
        if audioBuffer.count >= bufferSizeThreshold && !isProcessing {
            let bufferToProcess = audioBuffer
            audioBuffer = []
            
            Task {
                await processAudioBuffer(samples: bufferToProcess, language: language, isFinal: false)
            }
        }
    }
    
    private func updateWaveformSamples(from samples: [Int16]) {
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
    
    private func processAudioBuffer(samples: [Int16]? = nil, language: String? = nil, isFinal: Bool) async {
        let samplesToProcess = samples ?? audioBuffer
        
        guard !samplesToProcess.isEmpty else {
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // PCM16データをWAVフォーマットに変換
            let wavData = createWAVData(from: samplesToProcess, sampleRate: 24000)
            
            // OpenAI Whisper APIに送信
            let result = try await transcribeAudio(wavData, language: language)
            
            await MainActor.run {
                if !result.isEmpty {
                    // 新しいテキストを追加（スペースで区切る）
                    if self.streamingText.isEmpty || self.streamingText == "Listening..." {
                        self.streamingText = result
                    } else {
                        self.streamingText += " " + result
                    }
                    print("✅ Streaming text updated (model: \(self.currentModel)): \(result)")
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Transcription error: \(error.localizedDescription)"
                print("❌ Transcription error: \(error)")
            }
        }
    }
    
    private func createWAVData(from samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        
        // WAVヘッダー
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate * Int(numChannels) * Int(bitsPerSample) / 8)
        let blockAlign = UInt16(numChannels * bitsPerSample / 8)
        let dataSize = UInt32(samples.count * 2)
        
        // RIFF chunk
        data.append("RIFF".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: (36 + dataSize).littleEndian) { Array($0) })
        data.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        data.append("fmt ".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        
        // data chunk
        data.append("data".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        
        // PCM data
        for sample in samples {
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }
        
        return data
    }
    
    private func transcribeAudio(_ audioData: Data, language: String?) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // model parameter - 選択されたモデルを使用
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(currentModel)\r\n".data(using: .utf8)!)
        
        print("🔧 Using model: \(currentModel) for streaming transcription")
        
        // language parameter (if specified)
        if let language = language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // response_format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // file parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranCriptionError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw TranCriptionError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = json?["text"] as? String ?? ""
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
