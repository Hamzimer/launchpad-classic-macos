const translations = {
  en: {},
  ja: {
    skip: "本文へ移動", navFeatures: "機能", navInstall: "インストール", navPrivacy: "プライバシー", star: "☆ GitHubでStar",
    eyebrow: "無料で使える、オープンソースのmacOS Launchpad代替アプリ", heroTitle: "あのLaunchpadの使いやすさを、", heroAccent: "新しいmacOSでも。",
    heroLead: "Macにあるすべてのアプリを、見慣れた全画面グリッドで起動・検索・整理できます。フォルダー、リアルタイム検索、滑らかなページ移動、背景のカスタマイズ、新しいアプリの自動検出にも対応しています。",
    download: "macOS版を無料ダウンロード", watchDemo: "24秒のデモを見る", universal: "Appleシリコン + Intel", mit: "無料 · MITライセンス",
    reasonKicker: "Macアプリの、もっと使いやすいホーム", reasonTitle: "すべてのアプリを、見つけやすく、美しく整理。", reasonBody: "Launchpad Classicは、macOS Launchpadに代わる無料アプリです。アカウント、クラウド、広告、サブスクリプションなしで、アプリを直感的に探して整理できます。",
    signalOneTitle: "無料・オープンソース", signalOneBody: "利用料も広告もありません", signalTwoTitle: "いつも最新", signalTwoBody: "新しいアプリを自動で追加", signalThreeTitle: "プライバシー重視", signalThreeBody: "解析やテレメトリーなし",
    featuresKicker: "Launchpadの良さを、ひとつに", featuresTitle: "操作は馴染みやすく。自分好みに、もっと柔軟に。",
    featureFoldersTitle: "Launchpadらしいフォルダー整理", featureFoldersBody: "アプリを別のアプリに重ねるだけでフォルダーを作成。名前変更、並べ替え、フォルダー外への移動も自由です。",
    featureSearchTitle: "リアルタイム検索", featureSearchBody: "数文字入力するだけで、たくさんのアプリの中から目的のアプリをすぐに見つけられます。",
    featurePagingTitle: "滑らかなページ移動", featurePagingBody: "ドラッグ、ホイール、スワイプ、ページドットに対応。Macらしい滑らかなアニメーションで軽快に移動できます。",
    featureDiscoveryTitle: "自動で更新されるアプリ一覧", featureDiscoveryBody: "新しくインストールしたアプリは自動で追加され、削除したアプリも自動で消えます。更新ボタンは必要ありません。",
    featureUtilitiesTitle: "標準ユーティリティを自動整理", featureUtilitiesBody: "macOS標準のユーティリティは見慣れたフォルダーへ自動で整理。自分で作ったフォルダーはそのまま保たれます。",
    featureWallpaperTitle: "背景も表示も、自分好みに", featureWallpaperBody: "Desktop、macOSの壁紙、内蔵背景から選択し、使いやすいアイコンサイズに調整できます。",
    featureLanguageTitle: "3言語に対応", featureLanguageBody: "英語、日本語、繁体字中国語に対応し、システム言語に合わせた自動選択も利用できます。",
    showcaseKicker: "シンプルだから、迷わない", showcaseTitle: "画面の主役は、いつもアプリ。", showcaseBody: "表示サイズ、背景、言語、アップデート、終了は検索欄の横にすっきり収納。余計なものに邪魔されず、アプリ選びに集中できます。",
    showcaseOne: "Retina品質のアイコンと省メモリキャッシュ", showcaseTwo: "macOS 26のLiquid Glassコントロール", showcaseThree: "VoiceOverと「視差効果を減らす」に対応", settingsAlt: "検索欄の横に表示されたLaunchpad Classicの設定ポップオーバー",
    privacyKicker: "プライバシーを最初から重視", privacyTitle: "アプリ一覧はMacの外へ出ません。", privacyBody: "解析、広告、アカウント、テレメトリーはありません。ローカルのアプリフォルダーを読み取り、安全な更新確認のため公式GitHubリリースフィードだけへ接続します。",
    installKicker: "1分で準備完了", installTitle: "ダウンロード。インストール。すぐに使える。", installLead: "無料・オープンソース。AppleシリコンとIntel Macの両方に対応するUniversal 2ビルドです。",
    stepOneTitle: "インストーラを取得", stepOneBody: "GitHub Releasesから最新のPKGをダウンロードします。", stepTwoTitle: "PKGを開く", stepTwoBody: "古いバージョンを終了し、macOSのインストーラに従います。", stepThreeTitle: "整理状態を引き継ぐ", stepThreeBody: "今後の更新でもフォルダーと設定はそのまま保持されます。",
    getLatest: "Launchpad Classic 3.14.0を入手", readGuide: "インストールガイドを読む →", gatekeeper: "現在のコミュニティビルドはローカル署名済みですが、Appleの公証はありません。初回起動が止められた場合は、FinderでアプリをControl＋クリックし、「開く」を選んで一度だけ確認してください。",
    faqKicker: "よくある確認事項", faqTitle: "よくある質問", faqAppleQuestion: "Apple公式アプリですか？", faqAppleAnswer: "いいえ。Launchpad Classicは独立したオープンソースプロジェクトで、Apple Inc.との提携や承認はありません。",
    faqUpdatesQuestion: "アップデートはどのように行われますか？", faqUpdatesAnswer: "公式GitHubフィードを確認し、Sparkleが更新ファイルの署名を検証してからダウンロード・インストールします。",
    faqDataQuestion: "個人データを収集しますか？", faqDataAnswer: "いいえ。整理、検索、設定はローカルに保存され、解析、広告、アカウント、テレメトリーはありません。", faqSystemQuestion: "どのMacで使えますか？", faqSystemAnswer: "macOS 14 Sonoma以降、AppleシリコンとIntel Macの両方に対応します。",
    ctaKicker: "すべてのアプリを、美しくひとつの場所へ", ctaTitle: "無料のLaunchpad代替アプリを、今日から。", downloadFree: "無料でダウンロード", starHelpful: "☆ 気に入ったらStarを", footerTagline: "macOS Launchpadに代わる、無料・オープンソースのアプリ。", footerReleases: "リリース", footerIssues: "問題報告", footerRoadmap: "ロードマップ", footerSecurity: "セキュリティ", legal: "独立したオープンソースソフトウェアです。Apple、macOS、LaunchpadはApple Inc.の商標です。"
  },
  "zh-Hant": {
    skip: "跳至主要內容", navFeatures: "功能", navInstall: "安裝", navPrivacy: "隱私權", star: "☆ 在 GitHub 加星",
    eyebrow: "免費、開放原始碼的 macOS Launchpad 替代方案", heroTitle: "熟悉的 Launchpad 體驗，", heroAccent: "為現代 macOS 重新打造。", heroLead: "透過熟悉的全螢幕網格，輕鬆啟動、尋找與整理 Mac 上的所有應用程式。支援資料夾、即時搜尋、滑順翻頁、自訂桌布，以及自動偵測新應用程式。",
    download: "免費下載 macOS 版", watchDemo: "觀看 24 秒示範", universal: "Apple 晶片 + Intel", mit: "免費 · MIT 授權",
    reasonKicker: "更好用的 Mac 應用程式首頁", reasonTitle: "每個應用程式都更容易找到，也更整齊。", reasonBody: "Launchpad Classic 是免費的 macOS Launchpad 替代方案。不需要帳號、雲端、廣告或訂閱，就能直覺地瀏覽與整理所有應用程式。",
    signalOneTitle: "免費且開放原始碼", signalOneBody: "無訂閱、無廣告", signalTwoTitle: "自動保持最新", signalTwoBody: "自動顯示新安裝的應用程式", signalThreeTitle: "隱私優先", signalThreeBody: "無分析、無遙測",
    featuresKicker: "保留你喜歡的 Launchpad 體驗", featuresTitle: "操作依然熟悉，自訂方式更加彈性。",
    featureFoldersTitle: "熟悉的 Launchpad 資料夾", featureFoldersBody: "把一個應用程式拖到另一個上方即可建立資料夾，並可隨時重新命名、調整順序或把應用程式移出。",
    featureSearchTitle: "即時搜尋", featureSearchBody: "只要輸入幾個字母，就能從再多的應用程式中立即找到需要的項目。", featurePagingTitle: "滑順翻頁", featurePagingBody: "支援拖移、捲動、滑動與頁面圓點；原生動畫讓每次切換都流暢俐落。",
    featureDiscoveryTitle: "自動更新的應用程式清單", featureDiscoveryBody: "新安裝的應用程式會自動出現，移除後也會自動消失，完全不需要手動重新整理。", featureUtilitiesTitle: "自動整理工具程式", featureUtilitiesBody: "內建的 macOS 工具會自動收進熟悉的工具程式資料夾，而你建立的資料夾則會完整保留。",
    featureWallpaperTitle: "桌布與顯示由你決定", featureWallpaperBody: "可使用目前桌面、選擇 macOS 桌布或內建背景，再調整成最舒服的圖示大小。", featureLanguageTitle: "支援三種語言", featureLanguageBody: "支援英文、日文與繁體中文，也可依照系統語言自動選擇。",
    showcaseKicker: "簡單，才真正好用", showcaseTitle: "讓應用程式成為畫面主角。", showcaseBody: "顯示大小、背景、語言、更新與結束功能整齊收在搜尋欄旁，其他空間保持清爽，讓你專心挑選應用程式。",
    showcaseOne: "Retina 品質圖示與節省記憶體的快取", showcaseTwo: "macOS 26 Liquid Glass 控制項", showcaseThree: "支援 VoiceOver 與減少動態效果", settingsAlt: "Launchpad Classic 搜尋欄旁的設定彈出式選單",
    privacyKicker: "從設計開始保護隱私", privacyTitle: "你的應用程式庫只留在 Mac。", privacyBody: "沒有分析、廣告、帳號或遙測。Launchpad Classic 只掃描本機應用程式資料夾，並連線至官方 GitHub 發佈來源進行安全更新檢查。",
    installKicker: "一分鐘內完成", installTitle: "下載、安裝，立即使用。", installLead: "免費且開放原始碼。Universal 2 版本同時支援 Apple 晶片與 Intel Mac。",
    stepOneTitle: "下載安裝程式", stepOneBody: "從 GitHub Releases 取得最新 PKG。", stepTwoTitle: "開啟 PKG", stepTwoBody: "結束舊版本，然後依照 macOS 安裝程式操作。", stepThreeTitle: "保留你的整理方式", stepThreeBody: "日後安裝新版時，資料夾和偏好設定都會保留。",
    getLatest: "取得 Launchpad Classic 3.14.0", readGuide: "閱讀安裝指南 →", gatekeeper: "目前的社群版本已在本機簽署，但尚未經 Apple 公證。若 macOS 阻擋首次開啟，請在 Finder 中按住 Control 鍵並按一下應用程式，選擇「打開」並確認一次。",
    faqKicker: "使用前須知", faqTitle: "常見問題", faqAppleQuestion: "這是 Apple 官方應用程式嗎？", faqAppleAnswer: "不是。Launchpad Classic 是獨立的開放原始碼專案，與 Apple Inc. 沒有從屬或認可關係。",
    faqUpdatesQuestion: "如何更新？", faqUpdatesAnswer: "應用程式會檢查官方 GitHub 來源，Sparkle 在下載與安裝前會驗證更新簽章。", faqDataQuestion: "會收集個人資料嗎？", faqDataAnswer: "不會。整理、搜尋與偏好設定都保留在本機，沒有分析、廣告、帳號或遙測。", faqSystemQuestion: "支援哪些 Mac？", faqSystemAnswer: "支援 macOS 14 Sonoma 或更新版本，適用於 Apple 晶片和 Intel Mac。",
    ctaKicker: "把所有應用程式，漂亮地放在同一個地方", ctaTitle: "今天就試試免費的 Launchpad 替代方案。", downloadFree: "免費下載", starHelpful: "☆ 喜歡的話請加星", footerTagline: "免費、開放原始碼的 macOS Launchpad 替代方案。", footerReleases: "版本", footerIssues: "問題", footerRoadmap: "開發藍圖", footerSecurity: "安全性", legal: "獨立的開放原始碼軟體。Apple、macOS 與 Launchpad 是 Apple Inc. 的商標。"
  }
};

const defaultEnglish = new Map();
document.querySelectorAll("[data-i18n]").forEach((element) => {
  defaultEnglish.set(element, element.textContent);
});
document.querySelectorAll("[data-i18n-alt]").forEach((element) => {
  defaultEnglish.set(element, element.getAttribute("alt") || "");
});

function supportedLanguage(value) {
  if (value === "ja" || value.startsWith("ja-")) return "ja";
  if (value === "zh-Hant" || value.startsWith("zh-TW") || value.startsWith("zh-HK") || value.startsWith("zh-MO")) return "zh-Hant";
  return "en";
}

function applyLanguage(language) {
  const selected = supportedLanguage(language);
  const dictionary = translations[selected] || {};
  document.documentElement.lang = selected;
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const key = element.dataset.i18n;
    const value = selected === "en" ? defaultEnglish.get(element) : dictionary[key];
    if (typeof value === "string") element.textContent = value;
  });
  document.querySelectorAll("[data-i18n-alt]").forEach((element) => {
    const key = element.dataset.i18nAlt;
    const value = selected === "en" ? defaultEnglish.get(element) : dictionary[key];
    if (typeof value === "string") element.setAttribute("alt", value);
  });
  document.querySelectorAll("[data-language]").forEach((button) => {
    button.setAttribute("aria-pressed", String(button.dataset.language === selected));
  });
  try { localStorage.setItem("launchpad-classic-language", selected); } catch (_) { /* Storage may be unavailable in private contexts. */ }
}

let storedLanguage = "";
try { storedLanguage = localStorage.getItem("launchpad-classic-language") || ""; } catch (_) { /* Use the browser language. */ }
applyLanguage(storedLanguage || navigator.language || "en");

document.querySelectorAll("[data-language]").forEach((button) => {
  button.addEventListener("click", () => applyLanguage(button.dataset.language || "en"));
});

const demoVideo = document.querySelector("#demo video");
const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
if (demoVideo instanceof HTMLVideoElement && !reducedMotion.matches) {
  demoVideo.play().catch(() => { /* Browsers may require the visitor to press Play. */ });
}
