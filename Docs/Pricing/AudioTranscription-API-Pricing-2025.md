サービス：

* OpenAI gpt-4o-transcribe
* OpenAI gpt-4o-mini-transcribe
* OpenAI Whisper-1
* Google Cloud Speech-to-Text API (v2)
* Fireworks.ai Streaming ASR v2
* Fireworks.ai Streaming ASR v1 (Large)
* Fireworks.ai Whisper V3 Large
* Fireworks.ai Whisper V3 Turbo

---

概要比較：

OpenAI gpt-4o-transcribe

* モデル：GPT-4o ベース音声認識
* 料金：0.006 USD／分
* 対応言語：約100言語以上
* 精度：非常に高い（Whisper上位互換）
* リアルタイム対応：あり
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：高精度で低価格、Whisper技術を継承
* 弱点：ノイズ環境下で弱い場合あり
* 公式ページ：[https://platform.openai.com/docs/models/gpt-4o-transcribe](https://platform.openai.com/docs/models/gpt-4o-transcribe)

OpenAI gpt-4o-mini-transcribe

* モデル：GPT-4o mini（軽量版）
* 料金：0.003 USD／分
* 対応言語：約100言語以上
* 精度：高速だがやや精度控えめ
* リアルタイム対応：あり
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：最安・軽量・高速
* 弱点：多話者処理や精度は限定的
* 公式ページ：[https://platform.openai.com/docs/models/gpt-4o-mini-transcribe](https://platform.openai.com/docs/models/gpt-4o-mini-transcribe)

OpenAI Whisper-1

* モデル：Whisper-1（従来版）
* 料金：0.006 USD／分
* 対応言語：約100言語以上
* 精度：高精度（多言語対応）
* リアルタイム対応：なし（バッチ処理）
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：安定した高精度、多言語対応
* 弱点：リアルタイム処理不可、処理時間が長い
* 公式ページ：[https://platform.openai.com/docs/guides/speech-to-text](https://platform.openai.com/docs/guides/speech-to-text)

Google Cloud Speech-to-Text API (v2)

* モデル：Speech-to-Text v2
* 料金：0〜500,000分は0.016 USD／分、500,000〜1,000,000分は0.010 USD／分、1,000,000〜2,000,000分は0.008 USD／分、2,000,000分以上は0.004 USD／分
* Dynamic Batch モード（非リアルタイム処理）：0.003 USD／分
* 医療モデル：0.078 USD／分
* 対応言語：約125言語以上
* 精度：高精度（英語・主要言語に強い）
* リアルタイム対応：あり（Streaming API）
* カスタム語彙対応：あり（Custom Class）
* 出力形式：テキスト／JSON
* 特徴：安定性が高く、大規模運用向け
* 弱点：標準モデルは価格がやや高め
* 公式ページ：[https://cloud.google.com/speech-to-text/pricing?hl=en](https://cloud.google.com/speech-to-text/pricing?hl=en)

Fireworks.ai Streaming ASR v2

* モデル：Fireworks Streaming ASR v2（プレビュー版）
* 料金：0.0035 USD／分
* 対応言語：多言語対応
* 精度：高精度、低レイテンシー
* リアルタイム対応：あり（WebSocket）
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：次世代ストリーミング、クロスリージョン対応
* 弱点：プレビュー版のため安定性要確認
* 公式ページ：[https://fireworks.ai/](https://fireworks.ai/)

Fireworks.ai Streaming ASR v1 (Large)

* モデル：Fireworks Streaming ASR v1 Large
* 料金：0.0032 USD／分
* 対応言語：多言語対応
* 精度：高精度、実証済み
* リアルタイム対応：あり（WebSocket）
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：本番環境で実証済み、コスト効率良好
* 弱点：新機能の対応が限定的
* 公式ページ：[https://fireworks.ai/](https://fireworks.ai/)

Fireworks.ai Whisper V3 Large

* モデル：Whisper V3 Large（完全版）
* 料金：0.0018 USD／分
* 対応言語：約100言語以上
* 精度：高精度音声認識
* リアルタイム対応：なし（バッチ処理）
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：高精度、完全版、強制アライメント機能
* 弱点：リアルタイム処理不可、処理時間が長い
* 公式ページ：[https://fireworks.ai/](https://fireworks.ai/)

Fireworks.ai Whisper V3 Turbo

* モデル：Whisper V3 Turbo（最適化版）
* 料金：0.0009 USD／分
* 対応言語：約100言語以上
* 精度：高速だがやや精度控えめ
* リアルタイム対応：なし（バッチ処理）
* カスタム語彙対応：なし
* 出力形式：テキスト／JSON
* 特徴：最安価格、高速処理、強制アライメント機能
* 弱点：品質は若干低下、リアルタイム処理不可
* 公式ページ：[https://fireworks.ai/](https://fireworks.ai/)

---

技術比較メモ：

* 多言語検出：OpenAIは自動検出可、Googleは明示指定型
* ノイズ耐性：OpenAIは高い、Googleは音声品質に依存
* 話者分離：OpenAIは未対応、Googleは対応可能
* 句読点自動挿入：両者対応
* 出力形式：両者ともJSONまたはテキスト出力可能

---

推奨用途：

* コスト重視：Fireworks.ai Whisper V3 Turbo（0.0009 USD／分）
* 精度重視：OpenAI gpt-4o-transcribe
* バッチ処理・高精度：OpenAI Whisper-1
* 大規模商用運用：Google Cloud Speech-to-Text（割引後0.004 USD／分まで）
* リアルタイム会話アプリ：Fireworks.ai Streaming ASR v1 または OpenAI gpt-4o-mini-transcribe
* 最新ストリーミング技術：Fireworks.ai Streaming ASR v2（プレビュー）

---


開発者向けコスト計算（音声認識API）

料金（USD/分）：

| モデル | 料金(USD/分) |
| --- | --- |
| Fireworks.ai Whisper V3 Turbo | 0.0009 |
| Fireworks.ai Whisper V3 Large | 0.0018 |
| OpenAI gpt-4o-mini-transcribe | 0.003 |
| Google Cloud Speech-to-Text (Dynamic Batch) | 0.003 |
| Fireworks.ai Streaming ASR v1 | 0.0032 |
| Fireworks.ai Streaming ASR v2 | 0.0035 |
| OpenAI gpt-4o-transcribe | 0.006 |
| OpenAI Whisper-1 | 0.006 |
| Google Cloud Speech-to-Text (標準) | 0.016 |

計算式：

- 単一音声：コスト(USD) = 料金(USD/分) × (音声長[秒] ÷ 60)
- 月間合計：総コスト(USD) = 料金 × Σ(各音声の秒 ÷ 60)

サンプル試算：

- 30秒（0.5分）：
  - Fireworks Whisper V3 Turbo: 0.00045
  - Fireworks Whisper V3 Large: 0.0009
  - OpenAI gpt-4o-mini-transcribe: 0.0015
  - Fireworks ASR v1: 0.0016
  - Fireworks ASR v2: 0.00175
  - OpenAI gpt-4o-transcribe: 0.003
  - OpenAI Whisper-1: 0.003

- 5分：
  - Fireworks Whisper V3 Turbo: 0.0045
  - Fireworks Whisper V3 Large: 0.009
  - OpenAI gpt-4o-mini-transcribe: 0.015
  - Fireworks ASR v1: 0.016
  - Fireworks ASR v2: 0.0175
  - OpenAI gpt-4o-transcribe: 0.03
  - OpenAI Whisper-1: 0.03

- 1時間（60分）：
  - Fireworks Whisper V3 Turbo: 0.054
  - Fireworks Whisper V3 Large: 0.108
  - OpenAI gpt-4o-mini-transcribe: 0.18
  - Fireworks ASR v1: 0.192
  - Fireworks ASR v2: 0.21
  - OpenAI gpt-4o-transcribe: 0.36
  - OpenAI Whisper-1: 0.36

- 月10時間（600分）：
  - Fireworks Whisper V3 Turbo: 0.54
  - Fireworks Whisper V3 Large: 1.08
  - OpenAI gpt-4o-mini-transcribe: 1.8
  - Fireworks ASR v1: 1.92
  - Fireworks ASR v2: 2.1
  - OpenAI gpt-4o-transcribe: 3.6
  - OpenAI Whisper-1: 3.6

注記：

- OpenAIは分単価を秒按分で計算される前提。最新の仕様と価格は公式を参照。
- Fireworks.aiは音声の長さに基づいて課金される。
- Fireworks.ai Whisper V3 Turboが最安価格（0.0009 USD/分）で、コスト重視の用途に最適。
- Fireworks.ai Streaming ASRはWebSocket経由でのリアルタイム転写に対応。

