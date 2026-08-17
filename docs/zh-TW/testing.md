# 測試

[English](../testing.md) · 繁體中文

Berth 將作業系統整合留在 `Berth` executable，並把可測試的決策放在 `BerthCore`。自動化基線保護螢幕邊緣幾何與攔截狀態對帳，不模擬 Accessibility、AppKit 或 Core Graphics 事件傳遞。

## 自動化基線

執行與 GitHub Actions `Test baseline` job 相同的檢查：

```sh
swift build
swift test --enable-code-coverage
./Scripts/check_coverage.sh 90
./Scripts/build.sh
```

`BerthCore` 的 line coverage 必須維持在 90% 以上。Executable 與作業系統 adapter 必須成功編譯，但不計入百分比門檻。每項行為變更與 bug 修正，都應透過 `BerthCore` 的 public interface 新增或更新測試。

Workflow 會在每個 pull request 與每次 push 到 `main` 時執行。第一次成功執行後，再於 repository ruleset 將 `Test baseline` 設為 required check。

## 發布 smoke test

自動化 coverage 無法證明真實的 Accessibility、螢幕與 Dock 行為。發布前，請在 Apple Silicon Mac 執行以下檢查：

- 啟動封裝後的 App，並授予 Accessibility 權限。
- 依序固定每一顆已連接的螢幕，確認選單顯示所選螢幕。
- 驗證 Dock 位於下方、左側與右側的情況。
- 嘗試從非固定螢幕召喚 Dock，確認 Dock 仍留在固定螢幕。
- 確認游標可以通過相鄰螢幕之間的每一條共用邊界。
- 開啟螢幕鏡像，確認 Berth 不會將鏡像副本誤判為獨立邊界。
- 中斷再重新連接固定螢幕，確認螢幕恢復後 Berth 也會恢復運作。
- 撤銷 Accessibility 權限，確認攔截停止；重新授權後，確認 Berth 恢復運作。
- 使用「立刻把 Dock 帶回固定螢幕」，確認游標回到原始位置。
- 切換「登入時自動啟動」、重新登入，確認 Berth 自動啟動。
