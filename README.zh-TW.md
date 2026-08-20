<p align="center">
  <a href="https://shihyuho.github.io/berth/zh-TW/">
    <img src="site/assets/app-icon.png" alt="Berth" width="112" />
  </a>
</p>

<h1 align="center">Berth</h1>

<p align="center"><strong>讓 Dock 停在它該停的螢幕。</strong></p>

<p align="center">
  <a href="README.md">English</a> ·
  <b>繁體中文</b>
</p>

<p align="center">
  <a href="https://shihyuho.github.io/berth/zh-TW/"><img src="https://img.shields.io/badge/website-2678a6" alt="網站" /></a>
  <a href="https://github.com/shihyuho/berth/releases/latest"><img src="https://img.shields.io/github/v/release/shihyuho/berth?label=release" alt="最新版本" /></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-14212b" alt="macOS 13 以上版本" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License" /></a>
</p>

在多螢幕 Mac 上，Dock 可能跟著游標跑到你不想要的螢幕。Berth 是一個小巧的選單列 App，讓你替 Dock 選好泊位，並讓它安穩留在那裡。

它不會修改 Dock 偏好設定，也不會阻止游標穿越螢幕。選擇一次螢幕，剩下的交給 Berth 安靜處理。

## 為什麼使用 Berth？

- **從選單列選擇螢幕**，操作簡單直接。
- **Dock 跑掉時自動帶回**，不必反覆手動召回。
- **保持游標自然移動**，螢幕之間的共用邊界仍然暢通。
- **配合你的設定**，支援位於下方、左側與右側的 Dock。
- **活動只留在本機**，不監看鍵盤、不收集分析資料、不保存輸入內容；選用的更新檢查只會連線至 GitHub Releases。
- **登入後自動啟動**，不必每次重新開啟 App。

## 開始使用

### 直接下載

下載 [Berth Apple Silicon 版本](https://github.com/shihyuho/berth/releases/latest/download/Berth-arm64.zip)，解壓縮後將 `Berth.app` 移至「應用程式」。

### Homebrew

```sh
brew tap shihyuho/tap
brew install --cask shihyuho/tap/berth
```

### 安裝後

開啟 Berth，點選選單列上的錨點、選擇螢幕，並在 macOS 詢問時授予「輔助使用」權限。第一次開啟與更新細節請參考[開始使用](docs/zh-TW/getting-started.md)。

Berth 需要 Apple Silicon 與 macOS 13 以上版本。

## 深入了解

| 指南 | 內容 |
| --- | --- |
| [開始使用](docs/zh-TW/getting-started.md) | 安裝、Gatekeeper、輔助使用權限與更新 |
| [運作原理](docs/zh-TW/how-it-works.md) | Dock 行為、螢幕變更與隱私邊界 |
| [疑難排解](docs/zh-TW/troubleshooting.md) | 常見設定與權限問題 |
| [開發](docs/zh-TW/development.md) | 從原始碼建置、版本與發布封裝 |
| [測試](docs/zh-TW/testing.md) | 自動驗證、coverage 政策與發布前 smoke test |

## License

[MIT](LICENSE) © Shihyu
