# Fireworks.ai API 価格体系

## 概要
Fireworks.aiのAPI価格体系は、モデルタイプと使用量に基づいて課金されます。主に音声認識（ASR）とテキスト処理モデルが提供されています。

## 音声認識（ASR）モデル

### 1. Fireworks Streaming ASR v2
- **モデルID**: `accounts/fireworks/models/fireworks-asr-v2`
- **価格**: $0.0035 per unit
- **特徴**:
  - 次世代ストリーミング音声認識モデル（プレビュー版）
  - WebSocket経由でのリアルタイム転写
  - 低レイテンシー
  - クロスリージョン、クロスクラウド対応
  - 音声の長さに基づいて課金

### 2. Fireworks Streaming ASR v1 (Large)
- **モデルID**: `accounts/fireworks/models/fireworks-asr-large`
- **価格**: $0.0032 per unit
- **特徴**:
  - デフォルトのストリーミング音声認識モデル
  - 本番環境で実証済み
  - コスト効率の良いストリーミング転写
  - 音声の長さに基づいて課金

### 3. Whisper V3 Large
- **モデルID**: `accounts/fireworks/models/whisper-v3-large`
- **価格**: $0.0018 per unit
- **特徴**:
  - OpenAI Whisper large-v3の完全版
  - 高精度音声認識
  - 多言語対応
  - 強制アライメント機能
  - バッチ処理対応
  - 音声の長さに基づいて課金

### 4. Whisper V3 Turbo
- **モデルID**: `accounts/fireworks/models/whisper-v3-turbo`
- **価格**: $0.0009 per unit
- **特徴**:
  - OpenAI Whisper large-v3の最適化版
  - デコーディング層を32から4に削減
  - 高速処理（品質は若干低下）
  - 多言語対応
  - 強制アライメント機能
  - 音声の長さに基づいて課金

## 課金方式

### Serverless API
- **即座に実行可能**: 使用量に応じてのみ課金
- **音声認識**: 転写された音声の長さに基づいて課金
- **単位**: 音声の秒数または分単位

### 価格比較表

| モデル | 価格/Unit | 特徴 | 推奨用途 |
|--------|-----------|------|----------|
| Fireworks ASR v2 | $0.0035 | 最新、低レイテンシー | リアルタイム転写（プレビュー） |
| Fireworks ASR v1 | $0.0032 | 安定、実証済み | 本番環境でのストリーミング |
| Whisper V3 Large | $0.0018 | 高精度、完全版 | バッチ処理、精度重視 |
| Whisper V3 Turbo | $0.0009 | 高速、コスト効率 | バッチ処理、コスト重視 |

## 使用例

### 音声認識API使用例
```python
import requests

# Whisper V3 Large使用例
with open("audio.mp3", "rb") as f:
    response = requests.post(
        "https://audio-turbo.us-virginia-1.direct.fireworks.ai/v1/audio/transcriptions",
        headers={"Authorization": f"Bearer <YOUR_API_KEY>"},
        files={"file": f},
        data={
            "model": "whisper-v3-large",
            "temperature": "0",
            "vad_model": "silero"
        },
    )

# Whisper V3 Turbo使用例
with open("audio.mp3", "rb") as f:
    response = requests.post(
        "https://audio-turbo.us-virginia-1.direct.fireworks.ai/v1/audio/transcriptions",
        headers={"Authorization": f"Bearer <YOUR_API_KEY>"},
        files={"file": f},
        data={
            "model": "whisper-v3-turbo",
            "temperature": "0",
            "vad_model": "silero"
        },
    )
```

### ストリーミングASR使用例
```python
# WebSocket経由でのストリーミング転写
ENDPOINT_URL_BASE = "wss://audio-streaming-v2.api.fireworks.ai/v1"
ENDPOINT_PATH = "/audio/transcriptions/streaming"
```

## 注意事項

1. **API キー**: 環境変数 `FIREWORKS_API_KEY` の設定が必要
2. **エンドポイント**: モデルによって異なるエンドポイントを使用
3. **音声形式**: 16kHz、モノラル、PCM形式を推奨
4. **リアルタイム処理**: WebSocket接続が必要
5. **課金**: 実際の音声長に基づいて課金される

## 更新履歴
- 2024年: 初版作成
- Fireworks ASR v2がプレビュー版として追加
- Whisper V3 Turboの価格が最も低価格に設定

---
*このドキュメントは2024年時点の情報に基づいています。最新の価格情報は公式サイトでご確認ください。*
