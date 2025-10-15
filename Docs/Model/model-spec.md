[36 tools called]

Whisperモデルの音声長制限について調査した結果をお答えします。

## 音声の長さ制限について

**Whisperモデルでは、基本的に音声の長さ制限はモデルサイズに関係なく同じです。**

### 主なポイント：

1. **30秒チャンク処理**
   - Whisperモデルは基本的に30秒の音声チャンクで処理されます
   - 長い音声の場合は自動的に30秒ずつに分割されて処理されます
   - この仕組みは全てのWhisperモデル（tiny、base、small、medium、large-v1/v2/v3）で共通です

2. **モデルサイズによる違い**
   - **処理精度**: 大きいモデル（large-v3など）の方が長い音声でも高精度
   - **処理速度**: 小さいモデル（tiny、base）の方が高速
   - **メモリ使用量**: 大きいモデルの方が多くのメモリを消費

3. **実装上の制限**
   - プロジェクトのコードでは`sampleLength`パラメータで制御
   - `Constants.maxTokenContext`で最大トークン数が制限されています
   - 実際の制限はデバイスのメモリと処理能力に依存します

4. **推奨事項**
   - **短時間音声**: `tiny`や`base`モデルが効率的
   - **長時間音声**: `large-v3`モデルが高精度
   - **リアルタイム処理**: 量子化モデル（`-q5_0`など）が推奨

つまり、**モデルごとに音声の長さ制限が変わることはありません**が、処理の精度や速度、メモリ使用量はモデルサイズによって大きく異なります。


Source LanguageのAuto-detect機能について説明します。

## Auto-detect機能の概要

**Auto-detect（自動言語検出）**は、音声ファイルに含まれる言語を自動的に識別し、その言語で文字起こしを行う機能です。

## 仕組み

### 1. OpenAI APIの場合
- APIリクエストに`language`パラメータを**含めない**（`nil`）
- OpenAI Whisperモデルが音声を分析して言語を自動検出
- サポート言語: 99言語（Afrikaans, Arabic, Armenian, ...）

```swift
// language: nil → 自動検出
let result = try await openAIService.transcriptionAudio(
    audioData: audioData,
    language: nil,  // 自動検出
    model: "whisper-1"
)
```

### 2. WhisperKitの場合
- `DecodingOptions`の`language`を`nil`に設定
- ローカルのWhisperモデルが音声から言語を推定

```swift
let options = DecodingOptions(
    task: .transcribe,
    language: nil  // 自動検出
)
```

## 実装の流れ

1. **ユーザーがSource Languageで"Auto-detect"を選択**
   - UI表示: "Auto-detect"
   - 内部値: `selectedLanguage = "auto"`

2. **言語コード変換**
   ```swift
   let languageCode = Constants.languages["auto"] // → "auto"
   let finalLanguage = (languageCode == "auto") ? nil : languageCode
   ```

3. **APIへの渡し方**
   - OpenAI: `language: nil`
   - WhisperKit: `language: nil`

## メリット

✅ **多言語対応が容易**
- 事前に言語を指定する必要がない
- 会議や動画など複数言語が混在する場合に便利

✅ **ユーザー体験の向上**
- 言語を選択する手間が不要
- 言語を間違えるリスクがない

✅ **精度**
- WhisperモデルはOpenAIによる大規模トレーニングで高精度な言語検出が可能

## 制約事項

### OpenAI API
- **gpt-4o-transcribe** と **gpt-4o-mini-transcribe**: Auto-detectサポート
- **whisper-1**: Auto-detectサポート
- Translations（翻訳）: 常にAuto-detect（言語指定不可）

### WhisperKit
- モデルによって言語検出精度が異なる
- Multilingual モデル（`openai_whisper-tiny`, `openai_whisper-base`など）のみサポート
- English-only モデル（`openai_whisper-tiny.en`など）では使用不可

## 使用例

### 例1: 多言語会議の文字起こし
```
入力: 日本語、英語、中国語が混在する会議音声
設定: Source Language = "Auto-detect"
結果: 各言語を自動検出して正確に文字起こし
```

### 例2: 言語不明の音声ファイル
```
入力: 言語が分からない音声ファイル
設定: Source Language = "Auto-detect"
結果: Whisperが言語を検出して文字起こし実行
```

## ドキュメント参照

WhisperKitの公式ドキュメントによると:
- `language`パラメータを`nil`にすることで自動言語検出が有効化
- OpenAI Whisper APIと同様の挙動
- 99言語に対応

## 現在の実装状況

このアプリでは以下が実装済み:
- ✅ UI上で"Auto-detect"選択可能
- ✅ `"auto"` → `nil`への自動変換
- ✅ OpenAI APIとWhisperKit両方でサポート
- ✅ デフォルト言語として"Auto-detect"を設定

## 注意点

⚠️ **Translation（翻訳）モード**
- 翻訳モードでは常に言語自動検出が行われる
- 出力は常に英語

⚠️ **パフォーマンス**
- Auto-detectは若干処理時間が増える可能性がある
- 特定言語を指定した方が高速な場合もある