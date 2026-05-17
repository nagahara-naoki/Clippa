# Clippa ビルド手順

## 必要環境

- macOS 13 (Ventura) 以降の開発機（ビルド側）
- Xcode 15 以降
- GitHub Releases へ公開するための GitHub Actions
- 署名と公証を追加する場合のみ Apple Developer Program

このリポジトリは `Clippa.xcodeproj` を直接使います。`project.yml` からの生成は不要です。

## ビルド

### 開発ビルド（署名なし、ローカル実行用）

```bash
xcodebuild -project Clippa.xcodeproj -scheme Clippa -configuration Debug
```

成果物は `~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/Clippa.app` です。

### Release ビルド（配布用、要 Developer ID）

```bash
xcodebuild -project Clippa.xcodeproj -scheme Clippa \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath ./build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM=""
```

GitHub Releases に載せる配布物は、まずはこの状態で `Clippa.app` を ZIP / DMG にまとめる運用で十分です。

## タグから自動公開する流れ

1. `git tag v1.0.0`
2. `git push origin v1.0.0`
3. GitHub Actions が macOS 上でテストとビルドを実行
4. `Clippa-1.0.0.zip` と `Clippa-1.0.0.dmg` を GitHub Release に添付

Actions の本体は [`.github/workflows/release.yml`](./.github/workflows/release.yml) です。

## 署名と公証を足す場合

公開後に Gatekeeper 警告を減らしたいなら、Apple Developer ID の署名と notarization を追加します。

必要なもの:

- `APPLE_TEAM_ID`
- Developer ID Application 証明書
- `notarytool` 用の App-Specific Password か App Store Connect API キー

いまのワークフローは、まず GitHub Releases で配布を始めるための最短構成にしています。

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
