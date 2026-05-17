<p align="center">
  <img src="docs/assets/clippa-app-icon.svg" width="112" height="112" alt="Clippa app icon">
</p>

<h1 align="center">Clippa</h1>

<p align="center">
  Mac のためのクリップボード履歴アプリ。<strong>Cmd+Shift+V</strong> で過去のコピーを呼び出して、すぐ貼り付けできます。
</p>

<p align="center">
  <a href="./README.md">English</a>
  ·
  <a href="./docs/index.html">Website</a>
  ·
  <a href="https://github.com/nagahara-naoki/Clippa/releases/latest">Download</a>
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-12%2B-111215?style=flat-square">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square">
  <img alt="Local first" src="https://img.shields.io/badge/Local--first-100%25-2EA86B?style=flat-square">
  <img alt="Free" src="https://img.shields.io/badge/Free-GitHub%20Releases-FFD60A?style=flat-square&labelColor=111215">
</p>

![Clippa website preview](docs/assets/history.svg)

## Clippa について

macOS のクリップボードは、コピーするたびに前の内容が上書きされます。Clippa は、さっきコピーしたテキスト、URL、画像、スクリーンショットをあとから呼び出せる小さな Mac アプリです。

Windows の `Win+V` に近い感覚で、`Cmd+Shift+V` から素早く開き、検索して、そのまま貼り付けられます。

## 主な機能

- **グローバルショートカット**: `Cmd+Shift+V` で Clippa を開く
- **クリップボード履歴**: テキスト、URL、リッチテキスト、HTML、ファイルURL、画像、スクリーンショットを保存
- **検索**: 数文字入力するだけで履歴を絞り込み
- **キーボード操作**: `↑` / `↓`、`Return`、`Space`、`Esc`、`1`-`9`、`←` / `→` に対応
- **プレビュー**: `Space` で長いテキストや画像を貼り付け前に確認
- **ピン留め**: よく使う履歴を残しやすくする
- **保存テキスト**: よく使う文言やテンプレートを登録
- **テンプレート変数**: `{date}`、`{time}`、`{datetime}`、`{clipboard}`、`{cursor}` を展開
- **Paste Queue**: 複数の項目を順番に貼り付け
- **メニューバー常駐**: Dock に出さず、上部メニューバーから使える
- **ローカル保存**: 履歴データは Mac 内に保存

## 画面

<p align="center">
  <img src="docs/assets/history.svg" width="31%" alt="History window">
  <img src="docs/assets/text.svg" width="31%" alt="Saved text window">
  <img src="docs/assets/preview.svg" width="31%" alt="Preview window">
</p>

## インストール

1. [GitHub Releases](https://github.com/nagahara-naoki/Clippa/releases/latest) から最新版をダウンロード
2. `Clippa.app` を `Applications` フォルダへ移動
3. `Applications` から Clippa を起動
4. macOS に求められたらアクセシビリティ権限を許可
5. `Cmd+Shift+V` で履歴ポップアップを開く

アクセシビリティ権限は、選択した履歴を元のアプリへ自動貼り付けするために必要です。

## 使い方

| 操作 | ショートカット |
| --- | --- |
| Clippa を開く | `Cmd+Shift+V` |
| 選択を移動 | `↑` / `↓` |
| 選択中の項目を貼り付け | `Return` |
| プレビュー | `Space` |
| 1〜9番目を直接貼り付け | `1` ... `9` |
| タブ切り替え | `←` / `→` |
| 閉じる | `Esc` |

## プライバシー

Clippa はローカルファーストです。履歴データは以下に保存されます。

```text
~/Library/Application Support/Clippa/
```

クリップボード履歴の保存にサーバーは必要ありません。パスワードマネージャーなどが付ける concealed pasteboard item は、検出できる場合は履歴に残しません。

## ソースからビルド

必要環境:

- 開発環境として macOS 13 以降
- Xcode 15 以降
- Xcode command line tools

コマンドラインでビルド:

```bash
xcodebuild build \
  -project Clippa.xcodeproj \
  -scheme Clippa \
  -configuration Release \
  -destination 'platform=macOS'
```

テスト実行:

```bash
xcodebuild test \
  -project Clippa.xcodeproj \
  -scheme Clippa \
  -destination 'platform=macOS'
```

詳しくは [BUILD.md](./BUILD.md) を見てください。

## リリース用パイプライン

Clippa は GitHub Releases から公開する前提で設定しています。`v1.0.0` のようなタグを push すると、GitHub Actions が次を自動で行います。

1. テストを実行
2. macOS 上でアプリをビルド
3. `Clippa.app` を ZIP と DMG にまとめる
4. GitHub Release に成果物をアップロード

ワークフローは [`.github/workflows/release.yml`](./.github/workflows/release.yml) です。

## プロジェクト構成

```text
Sources/Clippa/
├── App/          アプリ起動とライフサイクル
├── MenuBar/      macOS メニューバー連携
├── Models/       履歴と保存テキストのモデル
├── Services/     監視、保存、貼り付け、ホットキー処理
├── UI/           SwiftUI / AppKit のポップアップUI
└── Utils/        パス、ログ、権限、ブランド補助
```

## Web サイト

GitHub Pages 用の静的サイトは [docs/index.html](./docs/index.html) にあります。Repository Settings の Pages で `docs` フォルダを公開元にしてください。

## ライセンス

Copyright © 2026 Clippa. All rights reserved.
