//  For licensing see accompanying LICENSE.md file.
//  Copyright © 2025 Cription. All rights reserved.

import Foundation

// MARK: - Fireworks Serverless ASR Service

@MainActor
class FireworksServerlessASRService: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "https://audio-turbo.us-virginia-1.direct.fireworks.ai/v1/audio/transcriptions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    func transcribeAudio(
        audioData: Data,
        model: String,
        language: String? = nil,
        task: String = "transcribe"
    ) async throws -> TranCriptionResult {
        guard !isProcessing else {
            throw TranCriptionError.alreadyProcessing
        }
        
        isProcessing = true
        error = nil
        
        defer {
            isProcessing = false
        }
        
        do {
            let result = try await performTranscription(
                audioData: audioData,
                model: model,
                language: language,
                task: task
            )
            return result
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func performTranscription(
        audioData: Data,
        model: String,
        language: String?,
        task: String
    ) async throws -> TranCriptionResult {
        
        guard let url = URL(string: baseURL) else {
            throw TranCriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // マルチパートフォームデータを作成
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // モデルパラメータ
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        
        // タスクパラメータ
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"task\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(task)\r\n".data(using: .utf8)!)
        
        // 言語パラメータ（指定されている場合）
        if let language = language, !language.isEmpty && language != "auto" {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // 音声ファイル
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 境界の終了
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🚀 Sending request to Fireworks Serverless API")
        print("📋 Model: \(model)")
        print("📋 Task: \(task)")
        print("📋 Language: \(language ?? "auto")")
        print("📋 Audio size: \(audioData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranCriptionError.invalidResponse
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: \(errorMessage)")
            throw TranCriptionError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TranCriptionError.invalidResponse
        }
        
        print("📋 API Response: \(json)")
        
        // Fireworks APIの応答形式に合わせて解析
        guard let text = json["text"] as? String else {
            throw TranCriptionError.invalidResponse
        }
        
        let detectedLanguage = json["language"] as? String ?? language ?? "unknown"
        let duration = json["duration"] as? Double ?? 0.0
        
        // セグメント情報の解析（利用可能な場合）
        var segments: [TranCriptionSegment] = []
        if let segmentsData = json["segments"] as? [[String: Any]] {
            segments = segmentsData.compactMap { segmentData in
                guard let start = segmentData["start"] as? Double,
                      let end = segmentData["end"] as? Double,
                      let segmentText = segmentData["text"] as? String else {
                    return nil
                }
                return TranCriptionSegment(
                    start: start,
                    end: end,
                    text: segmentText
                )
            }
        }
        
        return TranCriptionResult(
            text: text,
            segments: segments,
            language: detectedLanguage,
            duration: duration
        )
    }
}
