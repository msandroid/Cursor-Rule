# Xcode Project Setup for New Localization

## 手順1: Xcodeプロジェクトに新しい.xcstringsファイルを追加

### 1.1 ファイルをプロジェクトに追加
1. XcodeでWhisperAX.xcodeprojを開く
2. プロジェクトナビゲーターで`Resources`フォルダを右クリック
3. "Add Files to 'WhisperAX'"を選択
4. 以下のファイルを選択して追加：
   - `Localizable.xcstrings`
   - `InfoPlist.xcstrings`
5. "Add to target"でWhisperAXターゲットにチェックを入れる
6. "Add"をクリック

### 1.2 プロジェクト設定でローカライゼーションを有効化
1. プロジェクトナビゲーターでWhisperAXプロジェクトを選択
2. WhisperAXターゲットを選択
3. "Info"タブをクリック
4. "Localizations"セクションで"+"ボタンをクリック
5. 必要な言語を追加（例：Japanese, Chinese, Korean等）

### 1.3 ビルド設定の確認
1. WhisperAXターゲットを選択
2. "Build Settings"タブをクリック
3. "Localization"で検索
4. 以下の設定を確認：
   - `LOCALIZATION_PREFERS_STRING_CATALOGS` = YES
   - `LOCALIZATION_USE_STRING_CATALOGS` = YES

## 手順2: 既存のLocalizedStringsの参照を更新

### 2.1 インポート文の追加
各Viewファイルの先頭に以下を追加：
```swift
import SwiftUI
```

### 2.2 古いLocalizedStringsの参照を削除
以下のような古い参照を削除：
```swift
// 古い形式（削除）
LocalizedStrings.Settings.title
LocalizedStrings.localized("key", value: "value", comment: "comment")
```

### 2.3 新しいLocalizedStringResourceの使用
以下のように更新：
```swift
// 新しい形式
String(localized: LocalizedStringsNew.Settings.title)
Text(LocalizedStringsNew.Common.cancel)
```

## 手順3: ビルドとテスト

### 3.1 クリーンビルド
1. Product → Clean Build Folder
2. Product → Build

### 3.2 各言語でのテスト
1. シミュレーターでアプリを起動
2. 設定で言語を変更
3. 各画面でローカライゼーションが正しく表示されることを確認

## 手順4: トラブルシューティング

### 4.1 ビルドエラーの場合
- `LocalizedStringsNew`が見つからない場合：
  - `LocalizedStringsNew.swift`がプロジェクトに追加されているか確認
  - ターゲットに含まれているか確認

### 4.2 翻訳が表示されない場合
- `.xcstrings`ファイルが正しく追加されているか確認
- プロジェクトのローカライゼーション設定を確認
- デバイスの言語設定を確認

### 4.3 古い翻訳が残っている場合
- 古い`.strings`ファイルが残っていないか確認
- プロジェクトから古いローカライゼーションファイルを削除

## 完了確認

✅ 新しい.xcstringsファイルがプロジェクトに追加されている
✅ プロジェクトのローカライゼーション設定が有効になっている
✅ 既存のLocalizedStringの参照が新しい形式に更新されている
✅ アプリが正常にビルドされる
✅ 各言語でローカライゼーションが正しく表示される

---

**注意**: この手順を実行する前に、必ずプロジェクトのバックアップを作成してください。
