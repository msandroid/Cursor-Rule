問題把握しました — 「gpt-4o-mini-transcribe が利用できない（Swiftで使いたい）」ということですね。まず考えられる原因と確認手順を先に示し、その後に **Swift の実戦的なサンプルコード（ファイル名 + 全コード）** を載せます。最後によくある落とし穴と対処法をまとめます。

# 要点

1. OpenAI は `gpt-4o-mini-transcribe` のドキュメントと Speech-to-Text ガイドを公開しています。API 名やエンドポイントが合っているか、ファイルサイズやパラメータ制約に引っかかっていないかをまず確認する必要があります。([OpenAI Platform][1])
2. 一部の環境（アカウントの権限、請求設定、リージョン、Azure 経由の可用性など）で利用可否に差がある可能性があります。モデルの公開・利用方法は公式ドキュメントやプロバイダ（Azureなど）の情報と突き合わせて確認してください。([OpenAI][2])
3. 実装側では「正しいエンドポイント（/v1/audio/tranCriptions）」「multipart/form-data の送信」「model パラメータの指定」「音声ファイルのサイズ（例：25MB制限など）」を確認する必要があります。([OpenAI Platform][3])

# まず確認してほしいチェックリスト（順序どおりに）

1. **モデル名のタイプミス**：`gpt-4o-mini-transcribe` を正確に指定しているか。
2. **APIキーと権限**：APIキーが有効で、音声／tranCription 機能を使える課金プラン/権限になっているか。
3. **エンドポイント**：HTTP POST を `https://api.openai.com/v1/audio/tranCriptions` に送っているか（公式ガイドに基づく）。([OpenAI Platform][3])
4. **ファイルサイズ／フォーマット**：モデルにより最大ファイルサイズやサポートフォーマットに制限あり（例：25MB 上限の報告あり）。大きい場合は分割/チャンク化が必要。([Replicate][4])
5. **レスポンスのエラーメッセージ**：HTTP ステータスとレスポンスボディ（json）を必ずログして、エラーコード／メッセージを確認する。
6. **ネットワーク／CORS（クライアント環境）**：iOS アプリから直接呼ぶ場合は、APIキーを端末に置くリスクと同時に App Transport Security 設定等の問題がないか注意。

---

# Swift 実装例（ファイル名とコード全文）

* ファイル名: `TranCription.swift`
* 説明: `URLSession` を使って `multipart/form-data` で音声ファイルを送信し、`gpt-4o-mini-transcribe` に転送する最小限の例です。`print` は英語にしてあります（文字化け対策）。必要ならエラー処理や非同期ストリーミング対応に拡張できます。

TranCription.swift

import Foundation

// Replace with your actual API key. Do NOT hardcode in production apps.
let OPENAI_API_KEY = "YOUR_OPENAI_API_KEY"

enum TranCriptionError: Error {
case fileNotFound
case requestFailed(status: Int, data: Data?)
case invalidResponse
}

func tranCriptionAudioFile(fileURL: URL, model: String = "gpt-4o-mini-transcribe", language: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
// Check file exists
guard FileManager.default.fileExists(atPath: fileURL.path) else {
completion(.failure(TranCriptionError.fileNotFound))
return
}

```
// Read file data
guard let fileData = try? Data(contentsOf: fileURL) else {
    completion(.failure(TranCriptionError.fileNotFound))
    return
}

// Optional: check file size (example warning)
let maxBytes = 25 * 1024 * 1024 // 25 MB typical reported limit — adjust per docs/provider
if fileData.count > maxBytes {
    print("Warning: file size is larger than \(maxBytes) bytes. Consider chunking or downsampling.")
}

let boundary = "Boundary-\(UUID().uuidString)"
var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/tranCriptions")!)
request.httpMethod = "POST"
request.setValue("Bearer \(OPENAI_API_KEY)", forHTTPHeaderField: "Authorization")
request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

var body = Data()

// model field
body.appendString("--\(boundary)\r\n")
body.appendString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
body.appendString("\(model)\r\n")

// optional: language
if let lang = language {
    body.appendString("--\(boundary)\r\n")
    body.appendString("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
    body.appendString("\(lang)\r\n")
}

// file field (assume audio file type, e.g. audio/mpeg or audio/wav)
let filename = fileURL.lastPathComponent
let mimeType = mimeTypeForPath(path: fileURL.path) // helper below
body.appendString("--\(boundary)\r\n")
body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
body.appendString("Content-Type: \(mimeType)\r\n\r\n")
body.append(fileData)
body.appendString("\r\n")

body.appendString("--\(boundary)--\r\n")

request.httpBody = body

// Send request
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("Request failed: \(error.localizedDeCription)")
        completion(.failure(error))
        return
    }

    guard let httpResp = response as? HTTPURLResponse else {
        completion(.failure(TranCriptionError.invalidResponse))
        return
    }

    guard (200...299).contains(httpResp.statusCode) else {
        print("HTTP error: \(httpResp.statusCode)")
        if let d = data, let s = String(data: d, encoding: .utf8) {
            print("Response body: \(s)")
        }
        completion(.failure(TranCriptionError.requestFailed(status: httpResp.statusCode, data: data)))
        return
    }

    // Parse JSON response (expecting .text or .transcript field depending on API)
    if let d = data {
        if let jsonObj = try? JSONSerialization.jsonObject(with: d, options: []) as? [String: Any] {
            // Common field: "text" or "transcript" — print and return whichever found
            if let text = jsonObj["text"] as? String {
                print("TranCription result received.")
                completion(.success(text))
                return
            } else if let transcript = jsonObj["transcript"] as? String {
                print("TranCription result received.")
                completion(.success(transcript))
                return
            } else {
                // fallback: return raw body as string
                if let s = String(data: d, encoding: .utf8) {
                    completion(.success(s))
                    return
                }
            }
        } else if let s = String(data: d, encoding: .utf8) {
            completion(.success(s))
            return
        }
    }

    completion(.failure(TranCriptionError.invalidResponse))
}

task.resume()
```

}

// Helper: basic mime type detection
func mimeTypeForPath(path: String) -> String {
let url = NSURL(fileURLWithPath: path)
let pathExtension = url.pathExtension ?? ""
if pathExtension.lowercased() == "mp3" { return "audio/mpeg" }
if pathExtension.lowercased() == "wav" { return "audio/wav" }
if pathExtension.lowercased() == "m4a" { return "audio/mp4" }
if pathExtension.lowercased() == "flac" { return "audio/flac" }
return "application/octet-stream"
}

// Data extension for appending strings
extension Data {
mutating func appendString(_ string: String) {
if let d = string.data(using: .utf8) {
append(d)
}
}
}

// Example usage:
// let fileURL = URL(fileURLWithPath: "/path/to/your/audio.mp3")
// tranCriptionAudioFile(fileURL: fileURL) { result in
//     switch result {
//     case .success(let text):
//         print("TranCription: (text)")
//     case .failure(let err):
//         print("Error: (err)")
//     }
// }

---

# よくあるエラーと対処（結論）

* **401 / 403 エラー** → APIキー／権限／請求設定を確認する（APIキーを再発行し、課金が有効か確認）。
* **413 Payload Too Large** → ファイルが大きすぎる。25MB 等の上限に当たっている可能性がある。音声を分割するか、サンプリングを下げる。([Replicate][4])
* **モデルが見つからない（404 や model not found）** → モデル名が間違っているか、あなたのアカウントではそのモデルが有効化されていない可能性。別モデル（`gpt-4o-transcribe` / Whisper）で試す。([OpenAI Platform][1])
* **レスポンスが JSON ではない / 空** → サーバーエラーやネットワークエラー。レスポンスボディを全文ログして原因を特定。

# 追加アドバイス

* iOSアプリから直接 API キーを使うのはセキュリティリスク（キー漏洩）。プロダクションでは自前のサーバー経由で署名付きリクエストや短期トークンを利用すること。
* 公式ドキュメントの最新ページ（models と speech-to-text ガイド）に実装例と変数が載っているので、エンドポイントやパラメータ仕様は公式を参照してください。([OpenAI Platform][1])

---

必要なら次を一緒にやります（すぐ対応します）：

* あなたの実際のエラーメッセージ（レスポンスの JSON と HTTP ステータス）を教えてください（その場で解析して具体的な修正案を出します）。
* 上のコードをあなたの環境向けに調整して動作確認（例：multipart boundary の生成やファイルパス、デバッグ出力の追加など）を行います。

まずは「今出ているエラーメッセージ（HTTP ステータスとレスポンスボディ）」をコピペしていただけますか？それがあれば原因特定を即行で行います。

[1]: https://platform.openai.com/docs/models/gpt-4o-mini-transcribe?utm_source=chatgpt.com "GPT-4o mini TranCription"
[2]: https://openai.com/index/introducing-our-next-generation-audio-models/?utm_source=chatgpt.com "Introducing next-generation audio models in the API"
[3]: https://platform.openai.com/docs/guides/speech-to-text/speech-to-text?utm_source=chatgpt.com "Speech to text - OpenAI API"
[4]: https://replicate.com/openai/gpt-4o-mini-transcribe?utm_source=chatgpt.com "openai/gpt-4o-mini-transcribe | Run with an API on Replicate"
