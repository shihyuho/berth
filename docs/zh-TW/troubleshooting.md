# 疑難排解

[English](../troubleshooting.md) · 繁體中文

## 已授權，但 Berth 沒有生效

1. 確認「桌面與 Dock」設定中的「顯示器有獨立的空間」已啟用。
2. 確認 `Berth.app` 位於「應用程式」。
3. 從 Berth 選單先取消固定，再重新選擇螢幕。
4. 結束並重新開啟 Berth。
5. 在「隱私權與安全性」→「輔助使用」中將 Berth 關閉後重新啟用。

## 更新後權限失效

Berth 目前使用 ad-hoc 簽章，重新建置或更新時簽章可能改變。請在「隱私權與安全性」→「輔助使用」中將 Berth 關閉後重新啟用。

## 固定的螢幕被拔除

Berth 找不到指定螢幕時會停止攔截。重新連接螢幕，或從選單選擇另一個螢幕即可。

## 問題仍未解決

請建立 [GitHub issue](https://github.com/shihyuho/berth/issues)，並提供 macOS 版本、螢幕排列、Dock 位置與已嘗試的處理方式。
