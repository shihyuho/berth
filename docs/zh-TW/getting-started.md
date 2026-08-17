# 開始使用

[English](../getting-started.md) · 繁體中文

Berth 需要 Apple Silicon 與 macOS 13 Ventura 以上版本。請先開啟「系統設定」→「桌面與 Dock」，並確認 Mission Control 下的「顯示器有獨立的空間」已啟用。

## 直接下載 App

下載 [Berth Apple Silicon 版本](https://github.com/shihyuho/berth/releases/latest/download/Berth-arm64.zip)，解壓縮後將 `Berth.app` 移至「應用程式」。

Berth 目前使用 ad-hoc 簽章。第一次開啟時，macOS 可能因無法驗證開發者而阻擋 App。請前往「系統設定」→「隱私權與安全性」，找到 Berth 的阻擋訊息並選擇「仍要打開」。

## 使用 Homebrew 安裝

```sh
brew tap shihyuho/tap
brew install --cask shihyuho/tap/berth
```

如果先前曾手動將 Berth 放進「應用程式」，請先結束並移除該版本，再透過 Homebrew 安裝。

## 選擇螢幕

1. 開啟 Berth，點選選單列上的錨點。
2. 選擇 Dock 要停留的螢幕。
3. macOS 詢問時，前往「隱私權與安全性」→「輔助使用」，並啟用 Berth。
4. 回到 Berth，它會開始將 Dock 固定在所選螢幕。

你也可以從 Berth 選單啟用「登入時自動啟動」。

## 更新

```sh
brew update
brew upgrade --cask shihyuho/tap/berth
```

由於 App 使用 ad-hoc 簽章，更新後可能需要在「隱私權與安全性」→「輔助使用」中將 Berth 關閉後重新啟用。
