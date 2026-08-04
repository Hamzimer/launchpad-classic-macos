# Launchpad Classic for macOS

[![Quality Tests](https://github.com/Hamzimer/launchpad-classic-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/Hamzimer/launchpad-classic-macos/actions/workflows/ci.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)](https://support.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A native SwiftUI application launcher that brings the classic macOS Launchpad experience to current macOS releases.

日本語の説明は[こちら](#日本語)です。

> [!NOTE]
> This is an independent open-source project. It is not affiliated with or endorsed by Apple Inc. Apple, macOS, and Launchpad are trademarks of Apple Inc.

## Highlights

- Full-screen, borderless launcher with blurred desktop wallpaper
- Automatic paging based on the number of installed applications
- Smooth mouse-drag, mouse-wheel, trackpad, and page-dot navigation
- Adjustable application icon sizes from 60 to 112 points
- Drag one application onto another to create a folder
- Rename folders, rearrange their contents, and drag applications back out
- Adaptive folder canvas that prevents icons from overflowing
- Automatic Utilities grouping and App Store game grouping
- Search, application refresh, wallpaper selection, and display settings
- English, Japanese, and automatic system-language modes
- Native Liquid Glass controls on macOS 26 and later
- Reduce Motion and VoiceOver support
- 0.25-second fade-and-zoom closing motion modeled after classic Launchpad behavior
- Local-only operation with no analytics or network service

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- Swift 6 command-line tools when building from source

## Install

1. Download `LaunchpadClassic-3.10.zip` from the [latest release](../../releases/latest).
2. Extract the ZIP archive.
3. Move `LaunchpadClassic-3.10.app` to `/Applications`.
4. Open the application.

The downloadable build is locally signed. If macOS blocks the first launch, Control-click the application in Finder, choose **Open**, and confirm once.

## Build from source

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
open dist/LauncherX.app
```

The release build is Universal 2 and runs natively on Apple Silicon and Intel Macs.

## Tests

```sh
./run-quality-tests.sh
```

The standalone quality suite covers preference sanitization, duplicate data, invalid drag input, folder creation and removal, folder-name persistence, modal interaction, dismissal motion, page boundaries, compact layout geometry, inaccessible scan roots, and unsafe deletion paths.

## Privacy

Launchpad Classic scans local application folders and macOS wallpaper locations to build its launcher. It does not contain analytics, advertising, online accounts, API keys, or telemetry.

## License

Released under the [MIT License](LICENSE).

---

## 日本語

Launchpad Classicは、従来のmacOS Launchpadに近い操作感を、現在のmacOSで再現するSwiftUI製アプリケーションランチャーです。

### 主な機能

- インストール済みアプリ数に応じた自動ページ作成
- マウスドラッグ、ホイール、トラックパッド、ページドットによる移動
- アプリアイコンサイズの変更
- アプリ同士のドラッグによるフォルダー作成
- フォルダー名の変更、並べ替え、フォルダー外への移動
- アイコン数に応じて変化するフォルダー表示領域
- ユーティリティとApp Storeゲームの自動グループ化
- アプリ検索、一覧更新、背景選択、表示設定
- 日本語、英語、システム言語の自動選択
- macOS 26以降のLiquid Glass対応
- VoiceOverと「視差効果を減らす」設定への対応
- クラシックなLaunchpadに近い終了アニメーション
- 外部通信、広告、解析、テレメトリーなし

### インストール

1. [最新リリース](../../releases/latest)から`LaunchpadClassic-3.10.zip`をダウンロードします。
2. ZIPを展開し、APPを「アプリケーション」フォルダーへ移動します。
3. APPを起動します。

初回起動がmacOSにより止められた場合は、FinderでAPPをControl＋クリックし、「開く」を選択してください。

### ソースからビルド

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
```

テストは`./run-quality-tests.sh`で実行できます。
