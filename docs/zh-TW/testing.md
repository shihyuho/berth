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

`BerthCore` 的 line coverage 必須維持在 90% 以上。Executable 與作業系統 adapter 必須成功編譯，但不計入百分比門檻。每項 `BerthCore` 行為變更與 bug 修正，都應透過 `BerthCore` 的 public interface 新增或更新測試。

`Scripts/build.sh` 也會在編譯 String Catalog 前拒絕缺少 key 或翻譯不完整的已宣告語系。接著，它會檢查組裝完成的 App bundle 是否包含英文與台灣繁體中文資源、正確 lookup 與格式化值，並驗證不支援的語系會 fallback 至英文。這項 finished-bundle 檢查涵蓋「登入時自動啟動」所使用的同一條主 bundle 資源路徑。

Workflow 會在每個 pull request 與每次 push 到 `main` 時執行。第一次成功執行後，再於 repository ruleset 將 `Test baseline` 設為 required check。

## 在地化驗證

請分別在 macOS 選用 App 語言 `English` 與 `繁體中文（台灣）`，每次重新啟動 Berth 後驗證以下選單狀態：

- 未固定 Pinned Display。
- 已固定於連接中的螢幕。
- Pinned Display 已中斷連接。
- 尚未授予「輔助使用」權限。

兩種語言都必須保留 macOS 提供的螢幕名稱。也請啟用「登入時自動啟動」、重新登入，並確認 Berth 以 macOS 選用的語言啟動。若有任何狀態無法實際操作，請在 pull request 記錄為待驗證項目；自動 bundle lookup 不能取代這些 UI 證據。

## 首次設定驗證

發布設定流程變更前，請使用可拋棄的 user defaults domain 或新的 macOS 帳號驗證：

- 首次啟動會開啟單一設定視窗，其中包含獨立空間說明、固定螢幕選擇器與「輔助使用」區段。
- 完成前關閉視窗後，Berth 選單仍可使用、會顯示「繼續設定…」，而且 Dock 控制保持停止。
- 「桌面與 Dock」及「輔助使用」動作會開啟對應的「系統設定」區域。
- 授予「輔助使用」權限後，開啟中的設定視窗會自動更新，不需要手動重新檢查。
- 舊版安裝若已有有效的固定螢幕與「輔助使用」信任，會記錄為設定完成且不重新開啟 onboarding。
- 完成後撤銷「輔助使用」權限，Dock 控制會停止並顯示復原動作，但不重新開啟 onboarding。
- 完成後中斷固定螢幕，Dock 控制會停止並允許選擇其他螢幕，但不重新開啟 onboarding。
- 英文與台灣繁體中文都能完成完整流程並使用復原狀態。

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
