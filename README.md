# Launchpad Classic for macOS

[![Quality Tests](https://github.com/Hamzimer/launchpad-classic-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/Hamzimer/launchpad-classic-macos/actions/workflows/ci.yml)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)](https://support.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A native SwiftUI application launcher that brings the classic macOS Launchpad experience to current macOS releases.

[日本語](#日本語) | [繁體中文](#繁體中文)

> [!NOTE]
> This is an independent open-source project. It is not affiliated with or endorsed by Apple Inc. Apple, macOS, and Launchpad are trademarks of Apple Inc.

## Introduction

Launchpad Classic is a native macOS application launcher for people who want the familiar, direct experience of the classic Launchpad on newer macOS releases. Open it to see every installed application in a clean full-screen grid over your Desktop wallpaper, then launch an app with one click. There is no account, cloud service, analytics system, or network dependency: application discovery, organization, search, and preferences all remain on your Mac.

The launcher automatically scans the standard macOS application locations and watches them for changes. Newly installed apps appear without a manual refresh, removed apps disappear automatically, and the number of pages adapts to the size of the library. Pages can be changed with a mouse drag, scroll wheel, trackpad gesture, or the page indicators at the bottom of the screen. The search field filters the library immediately, while the adjacent settings control provides quick access without relying on the macOS menu bar.

Organization works like the classic Launchpad. Drag one app onto the center of another to create a folder, edit the folder name directly, rearrange its contents, or drag an app back out. Folder panels grow according to their contents so icons remain visible and begin at the top row. Common macOS Utilities and App Store games can be grouped automatically, and every custom folder, name, order, page arrangement, icon size, language choice, and background preference is restored after relaunching or installing a newer version.

The interface is designed to feel at home on macOS: a borderless full-screen presentation, Desktop-wallpaper background and blur options, Retina-density icons, responsive animations, keyboard dismissal with Escape, and background-click dismissal. It supports English, Japanese, Traditional Chinese, and automatic system-language selection, respects Reduce Motion, includes VoiceOver labels, and adopts native Liquid Glass controls on macOS 26 or later. First-page assets are prepared before presentation to avoid an empty startup frame, while bounded caches and automatic memory-pressure eviction keep repeated launches fast without allowing image memory to grow indefinitely.

## Highlights

- Full-screen, borderless launcher with blurred desktop wallpaper
- Preloaded first presentation without an empty full-screen frame
- Automatic paging based on the number of installed applications
- Automatic refresh when applications are installed or removed
- Smooth mouse-drag, mouse-wheel, trackpad, and page-dot navigation
- Adjustable application icon sizes from 60 to 112 points
- Retina-density application icons with high-quality scaling
- Drag one application onto another to create a folder
- Rename folders, rearrange their contents, and drag applications back out
- Adaptive folder canvas that prevents icons from overflowing
- Automatic Utilities grouping and App Store game grouping
- Search, automatic application detection, wallpaper selection, and display settings
- English by default, with Japanese, Traditional Chinese, and automatic system-language modes
- Native Liquid Glass controls on macOS 26 and later
- Reduce Motion and VoiceOver support
- 0.25-second fade-and-zoom closing motion modeled after classic Launchpad behavior
- Bounded, pressure-evictable image caches for predictable memory use and instant reopening
- Local-only operation with no analytics or network service

## Screenshot

![Launchpad Classic showing the full-screen application grid](Screenshots/launchpad-classic-3.10.2.png)

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- Swift 6 command-line tools when building from source

## Install

1. Download `LaunchpadClassic-3.13.0.pkg` from the [latest release](../../releases/latest).
2. Quit a running older version, then open the installer.
3. The installer replaces `/Applications/Launchpad Classic.app` while preserving folders and settings stored in your user account.

The ZIP release remains available for manual installation. Every release contains the same `Launchpad Classic.app` name so it can replace the existing copy.

The downloadable build is locally signed. If macOS blocks the first launch, Control-click the application in Finder, choose **Open**, and confirm once.

## Build from source

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
open "dist/Launchpad Classic.app"
```

The release build is Universal 2 and runs natively on Apple Silicon and Intel Macs.

## Tests

```sh
./run-quality-tests.sh
```

The standalone quality suite covers preference sanitization, duplicate data, invalid drag input, folder creation and removal, folder-name persistence, modal interaction, dismissal motion, page boundaries, compact layout geometry, inaccessible scan roots, automatic application-directory monitoring, bounded image caches, and unsafe deletion paths.

## Privacy

Launchpad Classic scans and locally monitors application folders, and scans macOS wallpaper locations, to build its launcher. It does not contain analytics, advertising, online accounts, API keys, or telemetry.

## License

Released under the [MIT License](LICENSE).

---

## 日本語

Launchpad Classicは、従来のmacOS Launchpadに近い操作感を、現在のmacOSで再現するSwiftUI製アプリケーションランチャーです。

### はじめに

Launchpad Classicは、従来のLaunchpadが持っていた「開けばすぐにすべてのアプリが見つかる」という分かりやすさを、現在のmacOSで利用するためのネイティブアプリです。起動するとDesktopの壁紙を背景に、インストール済みアプリを全画面のグリッドで表示します。アカウント登録、クラウドサービス、解析、広告、外部通信を必要とせず、アプリの検出、検索、並べ替え、設定の保存はすべてMac内で完結します。

標準のアプリケーションフォルダーを自動監視するため、新しいアプリをインストールすると手動更新なしで一覧に加わり、削除されたアプリも自動的に取り除かれます。アプリ数に応じてページ数が増減し、マウスで左右にドラッグする操作、ホイール、トラックパッド、画面下部のページドットで滑らかに移動できます。検索欄では入力と同時にアプリを絞り込み、その横の設定ボタンから表示や背景をすぐに変更できます。

アプリを別のアプリの中央へドラッグするとフォルダーを作成でき、フォルダー名の直接編集、中の並べ替え、フォルダー外への取り出しに対応します。フォルダーの表示領域はアプリ数に合わせて変化し、アイコンは上段から整列します。macOS標準のユーティリティやApp Storeのゲームも自動的にグループ化できます。作成したフォルダー、名称、並び順、ページ構成、アイコンサイズ、言語、背景は、アプリを終了した後や新しいバージョンを上書きインストールした後も引き継がれます。

UIは、枠のない全画面表示、Desktop壁紙とぼかし、Retina解像度のアイコン、滑らかなページアニメーション、Escキーと背景クリックによる終了など、macOSらしい操作感を重視しています。英語、日本語、繁体字中国語、システム言語の自動選択に対応し、VoiceOverと「視差効果を減らす」を尊重します。macOS 26以降ではネイティブのLiquid Glassコントロールを使用します。初期ページの素材を表示前に準備することで空の起動画面を抑え、上限付きキャッシュとメモリプレッシャー時の自動解放によって、高速な再表示と省メモリを両立しています。

### 主な機能

- インストール済みアプリ数に応じた自動ページ作成
- 空の全画面を表示しない初期ページの事前読込
- アプリのインストール／削除を検知した一覧の自動更新
- マウスドラッグ、ホイール、トラックパッド、ページドットによる移動
- アプリアイコンサイズの変更
- Retina解像度と高品質補間による滑らかなアイコン表示
- アプリ同士のドラッグによるフォルダー作成
- フォルダー名の変更、並べ替え、フォルダー外への移動
- アイコン数に応じて変化するフォルダー表示領域
- ユーティリティとApp Storeゲームの自動グループ化
- アプリ検索、新規アプリの自動検出、背景選択、表示設定
- 英語を初期設定とし、日本語、繁体字中国語、システム言語の自動選択にも対応
- macOS 26以降のLiquid Glass対応
- VoiceOverと「視差効果を減らす」設定への対応
- クラシックなLaunchpadに近い終了アニメーション
- 上限付きでメモリ負荷に応じて解放される画像キャッシュによる省メモリ設計と高速な再表示
- 外部通信、広告、解析、テレメトリーなし

### インストール

1. [最新リリース](../../releases/latest)から`LaunchpadClassic-3.13.0.pkg`をダウンロードします。
2. 実行中の旧バージョンを終了し、インストーラを開きます。
3. `/Applications/Launchpad Classic.app`が上書きされ、ユーザー領域に保存されたフォルダー構成と設定は引き継がれます。

手動インストール用のZIP版も利用できます。今後のリリースは常に同じ`Launchpad Classic.app`名を使用します。

初回起動がmacOSにより止められた場合は、FinderでAPPをControl＋クリックし、「開く」を選択してください。

### ソースからビルド

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
```

テストは`./run-quality-tests.sh`で実行できます。

---

## 繁體中文

Launchpad Classic 是一款以 SwiftUI 製作的原生 macOS 應用程式啟動器，讓新版 macOS 也能保有經典 Launchpad 熟悉、直覺的操作體驗。

### 介紹

Launchpad Classic 專為希望「開啟後立即看見所有應用程式」的使用者而設計。啟動後，它會以桌面背景顯示全螢幕應用程式網格，只要按一下圖示即可開啟應用程式。不需要註冊帳號，也不依賴雲端服務、分析工具、廣告或外部網路；應用程式偵測、搜尋、排列和偏好設定都只在您的 Mac 上處理。

啟動器會自動掃描並監控 macOS 的標準應用程式檔案夾。安裝新應用程式後，不必手動更新便會自動顯示；移除應用程式後，也會自動從清單中消失。頁數會依應用程式數量自動調整，並可使用滑鼠左右拖移、滾輪、觸控式軌跡板手勢或畫面底部的頁面指示點切換。搜尋欄會在輸入時立即篩選應用程式，旁邊的設定按鈕則可快速調整顯示與背景。

整理方式延續經典 Launchpad 的邏輯。將一個應用程式拖到另一個圖示中央即可建立資料夾，並可直接重新命名、調整資料夾內的排列，或把應用程式拖回資料夾外。資料夾面板會依內容數量調整大小，圖示會從最上排開始排列。macOS 工具程式與 App Store 遊戲也能自動分組。自訂資料夾、名稱、順序、頁面配置、圖示大小、語言和背景設定，都會在重新啟動或安裝新版本後保留。

介面採用符合 macOS 使用習慣的設計，包括無邊框全螢幕顯示、桌面背景與模糊效果、Retina 圖示、流暢動畫、Esc 鍵關閉及按一下背景返回桌面。支援英文、日文、繁體中文及自動系統語言模式；系統語言偵測包含台灣、香港、澳門和`zh-Hant`環境。它也支援 VoiceOver、「減少動態效果」，並在 macOS 26 或更新版本使用原生 Liquid Glass 控制項。第一頁內容會在顯示前預先準備，減少空白啟動畫面；有限制的快取和記憶體壓力自動釋放機制，則兼顧快速重新開啟與較低的記憶體用量。

### 主要功能

- 依已安裝應用程式數量自動建立頁面
- 自動偵測應用程式安裝與移除，不需要手動更新
- 支援滑鼠拖移、滾輪、觸控式軌跡板與頁面指示點
- 可調整應用程式圖示大小，並使用 Retina 解析度平滑顯示
- 將應用程式拖到另一個圖示中央即可建立資料夾
- 可重新命名資料夾、調整內容順序及將應用程式移出資料夾
- 資料夾顯示範圍會依圖示數量自動調整
- 自動整理 macOS 工具程式與 App Store 遊戲
- 應用程式搜尋、桌布選擇與顯示設定
- 英文為預設語言，並支援日文、繁體中文及系統語言自動選擇
- 支援 macOS 26 或更新版本的 Liquid Glass
- 支援 VoiceOver 與「減少動態效果」
- 使用有限制並可因應記憶體壓力釋放的圖像快取
- 不含外部通訊、廣告、分析或遙測

### 安裝

1. 從[最新版本](../../releases/latest)下載`LaunchpadClassic-3.13.0.pkg`。
2. 結束正在執行的舊版本，然後開啟安裝程式。
3. 安裝程式會取代`/Applications/Launchpad Classic.app`，並保留使用者帳號中的資料夾配置和設定。

也提供 ZIP 版本供手動安裝。後續版本會維持相同的`Launchpad Classic.app`名稱，方便直接取代舊版本。

如果 macOS 阻止第一次啟動，請在 Finder 中按住 Control 鍵並按一下應用程式，選擇「打開」，然後確認。

### 從原始碼建置

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
```

可執行`./run-quality-tests.sh`進行測試。
