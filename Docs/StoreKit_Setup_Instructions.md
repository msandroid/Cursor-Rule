# StoreKit Configuration File セットアップ手順

## 概要
このドキュメントでは、CriptionアプリのStoreKit Configuration Fileのセットアップ手順を説明します。

## 完了済みの作業

### 1. StoreKit Configuration File の作成
- `Cription.storekit` ファイルをプロジェクトルートに配置
- 4つのクレジットパッケージを定義：
  - 10 Credits ($9.99)
  - 25 Credits ($24.99) 
  - 50 Credits ($49.99)
  - 100 Credits ($99.99)

### 2. Xcodeスキームの設定
- `WhisperAX.xcscheme` にStoreKit Configuration File参照を追加
- StoreKit Testingが有効化される

### 3. UI実装
- `CreditPurchaseView.swift`: クレジット購入画面
- `CreditHistoryView.swift`: クレジット履歴画面

## 手動で完了する必要がある作業

### 1. XcodeプロジェクトにStoreKit Configuration Fileを追加

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターで `Cription.storekit` を右クリック
3. "Add Files to 'Cription'" を選択
4. ファイルをプロジェクトに追加

### 2. StoreKit Testingの有効化

1. Xcodeでスキームを選択（WhisperAX）
2. "Edit Scheme..." をクリック
3. "Run" セクションを選択
4. "Options" タブをクリック
5. "StoreKit Configuration" で `Cription.storekit` を選択

### 3. プロダクトIDの設定

App Store Connectで以下のプロダクトIDを設定：

```
Cription.credits.10
Cription.credits.25
Cription.credits.50
Cription.credits.100
```

### 4. テスト用の設定

#### サンドボックステスト
1. デバイスでサンドボックスアカウントを作成
2. アプリでクレジット購入をテスト
3. 購入履歴を確認

#### StoreKit Testing
1. Xcodeでアプリを実行
2. クレジット購入画面で購入をテスト
3. 購入が成功することを確認

## クレジットシステムの仕様

### クレジットレート
- 1$ = 1.1クレジット

### 料金体系
- whisper-1: $0.006/分
- gpt-4o-transcribe: $0.006/分
- gpt-4o-mini-transcribe: $0.003/分
- gpt-4o-mini (翻訳): $0.000075/1Kトークン

### 制限システム
- **Free**: クレジットのみでAPI利用可能
- **Pro**: サブスクリプション使用量 + クレジットでAPI利用可能
- **Unlimited**: 無制限でAPI利用可能

## トラブルシューティング

### よくある問題

1. **StoreKit Configuration Fileが認識されない**
   - ファイルがプロジェクトに正しく追加されているか確認
   - スキームの設定を再確認

2. **購入が失敗する**
   - プロダクトIDが正しく設定されているか確認
   - サンドボックスアカウントが有効か確認

3. **クレジットが反映されない**
   - `CreditManager`の実装を確認
   - 購入完了後の処理を確認

## 次のステップ

1. 実際のApp Store Connectでプロダクトを設定
2. 本番環境でのテスト
3. ユーザーフィードバックの収集
4. 必要に応じて料金体系の調整
