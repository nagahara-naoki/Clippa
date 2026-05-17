# Clippa ビルド手順

## 必要環境

- macOS 13 (Ventura) 以降の開発機（ビルド側）
- Xcode 15 以降
- Apple Developer Program（公証・配布に必要、年 ¥12,800）
- Homebrew

## 推奨：XcodeGen でプロジェクトを生成

`.xcodeproj` ファイルは差分管理が困難なので、`project.yml` から生成する方式を採用しています。

```bash
brew install xcodegen
cd <repo-root>
xcodegen generate
open Clippa.xcodeproj
```

これで `Clippa.xcodeproj` が生成され、Xcode で開けます。

## ビルド

### 開発ビルド（署名なし、ローカル実行用）

```bash
xcodebuild -project Clippa.xcodeproj -scheme Clippa -configuration Debug
```

成果物は `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/Clippa.app`

### Release ビルド（配布用、要 Developer ID）

```bash
xcodebuild -project Clippa.xcodeproj -scheme Clippa \
  -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  -derivedDataPath ./build
```

## 公証（Notarization）

直接配布版は Apple 公証が必須。

```bash
# .app を zip 化
ditto -c -k --keepParent build/Build/Products/Release/Clippa.app Clippa.zip

# 公証提出（Apple ID と App-Specific Password が必要）
xcrun notarytool submit Clippa.zip \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

# ステープル（公証チケットを .app に埋め込む）
xcrun stapler staple build/Build/Products/Release/Clippa.app
```

## DMG 作成

```bash
brew install create-dmg
create-dmg \
  --volname "Clippa" \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 400 200 \
  Clippa.dmg \
  build/Build/Products/Release/Clippa.app
```

## 初回実行時の権限

アプリ起動後、以下の権限を許可：

1. **アクセシビリティ権限**（`Cmd+V` 自動送信のため）
   - システム設定 → プライバシーとセキュリティ → アクセシビリティ → Clippa を許可

## 自動アップデート（Sparkle）

Sparkle 用 appcast.xml をホスティングする場合：

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <item>
      <sparkle:version>1.0.0</sparkle:version>
      <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
      <enclosure url="https://example.com/Clippa-1.0.0.dmg" />
    </item>
  </channel>
</rss>
```

## トラブルシュート

| 症状 | 対処 |
|------|------|
| 起動直後にクラッシュ | Console.app で `Clippa` を絞り込み、ログ確認 |
| ホットキーが効かない | アクセシビリティ権限の許可確認 |
| 履歴が保存されない | `~/Library/Application Support/Clippa/` のパーミッション確認 |
| Cmd+V 自動貼付が効かない | アクセシビリティ権限の許可確認 |
