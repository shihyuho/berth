# HANDOFF — 交接筆記

> 給接手這個 repo 的 agent/開發者。讀完這份 + README.md 就有完整脈絡,交接完成後這份文件可刪除。

## 專案是什麼

Berth ⚓:把 macOS Dock 固定在指定螢幕的選單列小工具。功能重新實作自 Gumroad 產品「Dock 乖乖鴨 v1.0」的公開描述(<https://tonyonier99.gumroad.com/l/Duck-Good-Good>),未使用原作者任何程式碼。原理與使用方式見 README.md。

命名歷程:DockDuck →(去鴨子化)DockPin →(定案)**Berth**(泊位;航海雙關:船在 dock 的 berth 停泊)。GitHub description 用:*Keep your macOS Dock at its berth*。

## 目前狀態(2026-07-19)

- 開發於 macOS 26 Tahoe(Darwin 25)/ Apple Silicon / Swift 6.3,`swift build -c release` 通過
- `./Scripts/build.sh` 產出 `dist/Berth.app`(arm64、ad-hoc 簽名、icns 圖示),bundle id `com.shihyuho.berth`
- Smoke test 通過(app 啟動 3 秒不 crash;啟動時不會觸發權限彈窗,選擇螢幕時才 prompt)
- **尚未 commit**:repo 只有 initial commit(LICENSE + stub README),本次搬入的程式碼還沒進版控
- 程式碼原開發於 playground repo,已整個搬過來,playground 那邊不再保留

## 架構(Sources/Berth/)

| 檔案 | 職責 |
|---|---|
| `main.swift` | NSApplication 進入點,accessory activation policy |
| `AppDelegate.swift` | 選單列 UI(⚓)、`reconcile()` 冪等狀態機(權限 × 螢幕存在 × 固定設定,3 秒輪詢收斂)、10 秒 Dock 位置巡檢 |
| `DockGuard.swift` | CGEventTap(cghidEventTap、modifying):在非固定螢幕的 Dock 邊緣把游標 clamp 在 2px 外;螢幕交界不擋;鏡像螢幕已排除 |
| `DockMover.swift` | AX 偵測 Dock 目前所在螢幕;合成「邊緣持續下壓」事件召回 Dock(跑在背景 queue,詳下) |
| `DisplayInfo.swift` | 螢幕列舉/UUID 持久化(displayID 會變,UUID 不會)、Dock orientation 讀取 |

關鍵設計決定:

- **召喚必須離開主執行緒**:event tap 掛在主 run loop,在主執行緒睡眠會堵住自己的 tap(游標凍結、合成事件 burst 化)。`DockMover.summonQueue` 就是為此存在,不要搬回主執行緒。
- **clamp 前先檢查交界**:`hasDisplay(at:)` 判斷該邊是否為螢幕間交界,是就放行,否則游標會過不了螢幕邊界。
- **鏡像螢幕**:與被鏡像者共享 bounds,已在 `refreshDisplays()` 過濾 + `handle()` 中固定螢幕優先放行,避免誤 clamp 固定螢幕自己的邊緣。

## 已審查並修正的問題

三視角 review(CoreGraphics/AppKit/打包)找到 8 個問題,全部修畢:主執行緒堵塞 tap(major)、鏡像螢幕誤 clamp(major)、螢幕重配置後 bounds 快取過期、左側 Dock 召喚座標差 1px、中鍵拖曳未檢查、剛授權後首次召喚延遲 13 秒、ad-hoc 重簽讓 TCC 授權失效(已在 build.sh 與 README 註明)。

## 待辦/待驗證

1. **多螢幕實測**(最重要,無法自動化):授權「輔助使用」後,驗證 (a) 游標在非固定螢幕推邊緣,Dock 不會跳過去 (b)「立刻把 Dock 帶回固定螢幕」會動 (c) Dock 放左/右側也正常。若召喚手勢沒觸發,調 `DockMover.performSummon` 的參數(delta 30/次數 20/間隔 6ms)。
2. 初始 commit + push(程式碼還沒進版控)。
3. 可選:universal binary(build.sh 加 `--arch x86_64`)、正式簽名(解 TCC 重授權問題)、Sparkle 自動更新。

## 建置/測試指令

```sh
./Scripts/build.sh                          # 建置 + 打包 + 簽名
dist/Berth.app/Contents/MacOS/Berth         # 直接跑(前景,Ctrl-C 結束)
```
