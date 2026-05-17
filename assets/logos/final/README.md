# Clippa 公式ロゴ アセット

採用デザイン: **Glass Clipboard / Modern Yellow**

## ファイル一覧

| ファイル | 用途 | サイズ |
|---------|------|--------|
| `clippa-app-icon.svg` | macOS アプリアイコン（主用途） | 1024×1024 |
| `clippa-app-icon-light.svg` | ライト UI 補助バリエーション | 1024×1024 |
| `clippa-menubar.svg` | メニューバー用テンプレート（モノクロ） | 22×22 |
| `clippa-wordmark.svg` | Web ヘッダー / 名刺 / プレスキット | 340×80 |

## カラー定義（公式・確定）

| 役割 | HEX | 用途 |
|------|-----|------|
| **Primary** | `#FFD60A` | ブランドコア（ゴールド） |
| **Primary Dark** | `#B57E20` | ホバー・押し時・テキスト |
| **Primary Light** | `#FFE9A8` | 薄背景・無効状態 |
| **Ink (Contrast)** | `#0F1115` | 高コントラスト要素（黒） |
| **Brown** | `#5C3A00` / `#7A4B0A` | アクセシブルなテキスト色 |

## ブランド配色の使い分け

黄色は背景色として強いが、白上では視認性が落ちる。以下のルール：

- **アイコン背景** → Primary (`#FFD60A`) のグラデーション
- **本文・テキスト** → Ink (`#0F1115`) または Brown (`#5C3A00`)
- **CTA ボタン** → Ink 背景 + 白文字（黄色 + 黒の高コントラスト）
- **アクセント / ピン** → Ink (`#0F1115`)
- **薄背景・チップ** → Primary Light (`#FFE9A8`) + Brown 文字

## Mac 上での .icns 生成手順

```bash
brew install librsvg
cd assets/logos/final

mkdir -p AppIcon.iconset
for size in 16 32 128 256 512; do
  rsvg-convert -w $size clippa-app-icon.svg -o AppIcon.iconset/icon_${size}x${size}.png
  rsvg-convert -w $((size*2)) clippa-app-icon.svg -o AppIcon.iconset/icon_${size}x${size}@2x.png
done

iconutil -c icns AppIcon.iconset
mv AppIcon.icns ../../../Resources/AppIcon.icns
```

## メニューバーアイコンの実装

```bash
rsvg-convert -f pdf clippa-menubar.svg -o MenuBarIcon.pdf
```

Swift:
```swift
button.image = NSImage(named: "MenuBarIcon")
button.image?.isTemplate = true
```

## ブランドガイドライン

- 単色化する場合: Ink `#0F1115` または Primary Dark `#B57E20` を使用
- 暗背景では黄色をそのまま使う or 白に反転
- アイコン周囲に最低 20% の余白を確保
- ロゴの変形・回転禁止
- グラデーション色の改変禁止
- 黄色は **黒との組み合わせ** で最大効果（メリハリのあるブランド表現）
