<h1 align="center">Berth ⚓</h1>

<p align="center"><strong>讓 Dock 停在它該停的螢幕。</strong></p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black.svg" alt="macOS 13 or later">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138.svg" alt="Swift 5.9">
</p>

在多螢幕的 macOS 桌面上，Dock 會跟著游標跑到別顆螢幕。Berth 是一個安靜待在選單列的小工具：選好泊位後，它會阻止 Dock 被其他螢幕召走，必要時再自動把 Dock 帶回來。

不修改 Dock 偏好設定，不妨礙游標穿越螢幕，也不需要你反覆把 Dock 推回原位。

> Berth 目前提供 Apple Silicon 版本，可透過 Homebrew 安裝或從原始碼建置。

## 為什麼用 Berth？

- **固定想要的螢幕**：從選單列直接選擇 Dock 的泊位。
- **自動維持位置**：Dock 跑錯螢幕時會被帶回；螢幕配置改變後也會重新對帳。
- **配合你的 Dock**：支援下方、左側與右側停靠位置。
- **不打擾工作流程**：只攔住非固定螢幕的 Dock 召喚手勢，螢幕交界仍可正常通行。
- **開機後就定位**：可從選單列啟用「登入時自動啟動」。

## 快速開始

### 1. 使用 Homebrew 安裝

先確認「系統設定」→「桌面與 Dock」→「Mission Control」中的「顯示器有獨立的空間」已開啟，再執行：

如果先前曾手動把 `Berth.app` 放進「應用程式」，請先結束並移除舊 App，避免與 Homebrew 管理的版本衝突。

```sh
brew tap shihyuho/tap
brew install --cask shihyuho/tap/berth
```

Berth 使用 ad-hoc 簽章。第一次開啟時，macOS 可能顯示無法驗證開發者；請前往「系統設定」→「隱私權與安全性」，找到 Berth 的阻擋訊息並選擇「仍要打開」，再依提示確認。

Homebrew 會把 `Berth.app` 安裝至「應用程式」資料夾。

### 2. 選擇 Dock 的泊位

1. 點選選單列上的 ⚓。
2. 選擇要固定 Dock 的螢幕。
3. macOS 詢問時，前往「系統設定」→「隱私權與安全性」→「輔助使用」，啟用 Berth。
4. 回到選單列；Berth 會開始固定 Dock，並在需要時把它帶回來。

想讓設定重開機後自動生效，可在 ⚓ 選單中開啟「登入時自動啟動」。

## 更新

先更新 Homebrew 的套件資訊，再升級 Berth：

```sh
brew update
brew upgrade --cask shihyuho/tap/berth
```

由於 Berth 使用 ad-hoc 簽章，每次更新後可能需要重新開啟 App，並前往「系統設定」→「隱私權與安全性」→「輔助使用」，將 Berth 關閉後再重新啟用。

## 輔助使用權限用在哪裡？

Berth 會全域接收滑鼠移動與拖曳事件，在非固定螢幕的特定邊緣調整游標位置，並合成滑鼠移動手勢把 Dock 帶回來。這些操作都在本機完成；Berth 不監看鍵盤、不保存輸入內容，也沒有網路功能。

撤銷權限後，Berth 會自動停止攔截，避免影響系統操作。

## 運作原理

當 macOS 啟用「顯示器有獨立空間」時，把游標持續推向某顆螢幕的 Dock 邊緣，便能把 Dock 召喚過去。Berth 在這個手勢成立前介入：

1. 使用 `CGEventTap` 接收滑鼠移動與拖曳事件。
2. 在非固定螢幕的 Dock 外側邊緣，讓游標保持至少 2 px 的距離；若該邊是螢幕交界則完全放行。
3. 發現 Dock 位於錯誤螢幕時，在固定螢幕合成相同的持續推壓手勢，把 Dock 帶回泊位。

Berth 會即時攔住其他螢幕上的召喚手勢；若 Dock 仍因其他原因移動，最多約 10 秒後會在下一次位置檢查時被帶回。Berth 也會在螢幕配置或輔助使用權限改變時自動調整狀態。

## 常見問題

### 已授權，但 Berth 沒有生效

確認「顯示器有獨立的空間」已開啟，且 `Berth.app` 已放在「應用程式」資料夾。也可以依序嘗試：

1. 從 ⚓ 選單先「取消固定」，再重新選擇螢幕。
2. 結束 Berth 後重新開啟。
3. 在「輔助使用」設定中將 Berth 關閉後再重新開啟。

問題仍未解決時，請到 [GitHub Issues](https://github.com/shihyuho/berth/issues) 回報你的 macOS 版本、螢幕排列方式與 Dock 停靠位置。

### 重新建置或更新後，原本的授權失效

ad-hoc 簽章會在重新建置或 Homebrew 更新後改變。請前往「系統設定」→「隱私權與安全性」→「輔助使用」，將 Berth 關閉後再重新開啟。

### 拔掉固定的螢幕後會怎樣？

Berth 會安全地停止攔截。接回螢幕，或從 ⚓ 選單選擇新的泊位即可。

## 從原始碼建置

需要 Swift 5.9 與 Xcode Command Line Tools：

```sh
git clone https://github.com/shihyuho/berth.git
cd berth
./Scripts/build.sh
```

建置完成後會產生 `dist/Berth.app`。把它拖到「應用程式」資料夾，並從那裡開啟。本機建置的 App 不帶 quarantine 屬性，但重新建置後仍需重新啟用輔助使用權限。

## 系統需求

- macOS 13 Ventura 或更新版本
- Apple Silicon Mac
- 已開啟「顯示器有獨立的空間」

## License

[MIT](LICENSE) © Shihyu
