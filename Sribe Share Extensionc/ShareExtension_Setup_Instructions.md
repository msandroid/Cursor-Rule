# Share Extension セットアップ手順

## 1. XcodeでShare Extensionターゲットを追加

1. XcodeでWhisperAX.xcodeprojを開く
2. プロジェクトナビゲーターでプロジェクトを選択
3. ターゲット一覧の下部にある「+」ボタンをクリック
4. 「Share Extension」を選択
5. 以下の設定で作成：
   - Product Name: Sribe Share Extensionc
   - Bundle Identifier: scribe.ai.ShareExtension
   - Language: Swift
   - Use Core Data: チェックしない

## 2. ファイルをプロジェクトに追加

以下のファイルをShare Extensionターゲットに追加：

### ソースファイル
- `WhisperAX/ShareExtension/ShareViewController.swift`
- `WhisperAX/Views/SharedTextsView.swift`

### リソースファイル
- `WhisperAX/ShareExtension/Info.plist`
- `WhisperAX/ShareExtension/MainInterface.storyboard`

## 3. App Groupsの設定

### メインアプリの設定
1. WhisperAXターゲットを選択
2. 「Signing & Capabilities」タブを開く
3. 「+ Capability」をクリック
4. 「App Groups」を追加
5. グループ名: `group.scribe.ai`

### Share Extensionの設定
1. Scribe Share Extensionターゲットを選択
2. 「Signing & Capabilities」タブを開く
3. 「+ Capability」をクリック
4. 「App Groups」を追加
5. 同じグループ名: `group.scribe.ai`

## 4. Info.plistの設定

Share ExtensionのInfo.plistに以下を追加：

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

## 5. ビルド設定

Share Extensionターゲットのビルド設定：
- iOS Deployment Target: 17.0以上
- Swift Language Version: Swift 5
- Bundle Identifier: scribe.ai.ShareExtension

## 6. テスト方法

1. アプリをビルドして実行
2. 他のアプリ（Safari、メモなど）でテキストを選択
3. 共有ボタンをタップ
4. 「Scribeに追加」を選択
5. テキストがScribeアプリに保存されることを確認

## 7. トラブルシューティング

### 共有ボタンが表示されない場合
- Bundle Identifierが正しく設定されているか確認
- Info.plistの設定が正しいか確認
- アプリを一度アンインストールして再インストール

### データが共有されない場合
- App Groupsの設定が正しいか確認
- UserDefaultsのsuiteNameが一致しているか確認
- デバッグログでデータの保存・読み込みを確認
