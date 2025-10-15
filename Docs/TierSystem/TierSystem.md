# Tier System - Spending Limits PRD (OpenAI Tier System参考)

## 1. 概要

### 1.1 目的
OpenAIのTier Systemを参考に、API利用を制限するための段階的支出制限システムを提供し、ユーザーの予算管理とコスト制御を実現する。

### 1.2 スコープ
- API利用のみを計測対象とする（Fireworks API、OpenAI API）
- ローカルモデルの利用は制限対象外
- 支出制限は月次でリセットされる
- 履歴支出に基づく自動ティアアップグレード
- 支払い実績と経過日数による段階的制限緩和

## 2. ティアシステム仕様

### 2.1 ティア構成（OpenAI Tier System準拠）

| ティア | 月次制限 | 履歴支出要件 | 経過日数要件 | クレジット購入 |
|--------|----------|--------------|--------------|----------------|
| **Tier 1** | $50.00/月 | デフォルト（有効な支払い方法追加済み） | 即座 | 利用可能 |
| **Tier 2** | $500.00/月 | 総履歴支出 $50.00+ | 初回支払いから7日経過 | 利用可能 |
| **Tier 3** | $5,000.00/月 | 総履歴支出 $500.00+ | 初回支払いから14日経過 | 利用可能 |
| **Tier 4** | $50,000.00/月 | 総履歴支出 $5,000.00+ | 初回支払いから30日経過 | 利用可能 |
| **Custom** | カスタム設定 | サポート連絡必要 | - | 利用不可 |

### 2.2 現在のティア表示
- ユーザーの現在のティアを「Current Tier」として表示
- ティアアップグレードに必要な履歴支出額と経過日数を表示
- 次のティアへの進歩状況をプログレスバーで表示
- 経過日数のカウントダウン表示（要件未達成の場合）

## 3. 機能要件

### 3.1 支出追跡
- **API利用のみ計測**: Fireworks API、OpenAI APIの利用料金のみ
- **リアルタイム更新**: 利用と同時に支出額を更新
- **月次リセット**: 毎月1日に月次支出をリセット
- **履歴保持**: 総履歴支出は永続的に保持

### 3.2 制限管理
- **自動制限**: 月次制限に達した場合、API利用を自動停止
- **警告通知**: 制限の80%、90%、95%に達した時点で通知
- **制限超過防止**: 制限超過を防ぐための事前チェック

### 3.3 ティア管理
- **自動アップグレード**: 履歴支出要件と経過日数要件を満たした場合、自動でティアアップグレード
- **ダウングレードなし**: 一度達成したティアは維持される
- **経過日数チェック**: 初回支払いからの経過日数を追跡
- **カスタムティア**: サポート経由での個別設定

## 4. ユーザーインターフェース

### 4.1 ダッシュボード表示
```
Spending Limits
┌─────────────────────────────────────┐
│ Current Tier: Tier 1               │
│ This Month: $12.50 / $50.00        │
│ ████████░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ Total Historical Spend: $12.50     │
│ Days since first payment: 3/7      │
│ Next tier: $37.50 + 4 days needed  │
└─────────────────────────────────────┘
```

### 4.2 ティア情報表示
- 各ティアの制限額と要件を一覧表示
- 現在のティアをハイライト表示
- 次のティアへの進歩状況を表示
- 経過日数の進捗表示
- クレジット購入ボタン（利用可能な場合）

### 4.3 クレジット購入
- ティア1以上でクレジット購入可能
- 購入したクレジットは履歴支出に加算
- 初回支払い日を記録（初回購入時）
- 即座にティアアップグレードの可能性を評価

## 5. 技術仕様

### 5.1 データ管理
- **月次支出**: UserDefaultsで管理、月次リセット
- **履歴支出**: Keychainで永続保存
- **現在ティア**: UserDefaultsで管理
- **初回支払い日**: Keychainで永続保存
- **経過日数**: 初回支払い日から自動計算
- **カスタム制限**: UserDefaultsで管理

### 5.2 計測対象API
- **Fireworks API**: 
  - `fireworks-asr-large`: $0.0032/分
  - `fireworks-asr-v2`: $0.0032/分
- **OpenAI API**:
  - `whisper-1`: $0.006/分
  - `gpt-4o-transcribe`: $2.50/1M tokens
  - `gpt-4o-mini-transcribe`: $0.15/1M tokens

### 5.3 制限チェック
```swift
func canSpend(_ amount: Double) -> Bool {
    let limit = getCurrentLimit()
    return (currentMonthlySpend + amount) <= limit
}
```

## 6. ビジネスロジック

### 6.1 ティア判定（OpenAI Tier System参考）
```swift
private func determineTierFromHistoricalSpend() -> SpendingTier {
    let daysSinceFirstPayment = getDaysSinceFirstPayment()
    
    if historicalSpend >= 5000.00 && daysSinceFirstPayment >= 30 {
        return .tier4
    } else if historicalSpend >= 500.00 && daysSinceFirstPayment >= 14 {
        return .tier3
    } else if historicalSpend >= 50.00 && daysSinceFirstPayment >= 7 {
        return .tier2
    } else {
        return .tier1
    }
}

private func getDaysSinceFirstPayment() -> Int {
    guard let firstPaymentDate = getFirstPaymentDate() else { return 0 }
    return Calendar.current.dateComponents([.day], from: firstPaymentDate, to: Date()).day ?? 0
}
```

### 6.2 支出追加
```swift
func addSpending(_ amount: Double) {
    currentMonthlySpend += amount
    historicalSpend += amount
    updateCurrentTier()
    saveData()
}
```

### 6.3 クレジット購入
```swift
func purchaseCredits(_ amount: Double) {
    historicalSpend += amount
    
    // 初回支払い日を記録
    if getFirstPaymentDate() == nil {
        setFirstPaymentDate(Date())
    }
    
    updateCurrentTier()
    saveData()
}
```

## 7. 表示仕様

### 7.1 金額表示
- **単位**: ドル（$）
- **小数点**: 第二位まで表示（例: $12.50）
- **フォーマット**: `String(format: "%.2f", amount)`

### 7.2 プログレスバー
- 月次制限に対する現在の支出を視覚的に表示
- 色分け: 緑（0-80%）、黄（80-95%）、赤（95-100%）

### 7.3 通知
- **80%到達**: 黄色の警告
- **90%到達**: オレンジの注意
- **95%到達**: 赤色の緊急警告
- **100%到達**: 制限超過、API利用停止

## 8. エラーハンドリング

### 8.1 制限超過時
- API利用を即座に停止
- ユーザーに制限超過を通知
- クレジット購入または翌月まで待機を案内

### 8.2 データ不整合時
- 履歴支出の整合性チェック
- 必要に応じてティアを再計算
- ユーザーに状況を通知

## 9. セキュリティ

### 9.1 データ保護
- 履歴支出データはKeychainで暗号化保存
- 月次支出データはUserDefaultsで管理
- 機密情報の漏洩防止

### 9.2 不正防止
- クライアントサイドでの制限チェック
- サーバーサイドでの追加検証（将来実装）
- 異常な支出パターンの監視

## 10. 将来の拡張

### 10.1 機能拡張
- 年次制限の追加
- カテゴリ別制限（API種別）
- チーム・組織向け制限管理
- レート制限の追加（OpenAI Tier System参考）
- 地域別制限の実装

### 10.2 分析機能
- 支出傾向の分析
- 予算予測機能
- コスト最適化の提案

---

**文書バージョン**: 1.0  
**最終更新日**: 2025年1月  
**作成者**: Cription開発チーム
