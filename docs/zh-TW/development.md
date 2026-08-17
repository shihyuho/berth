# 開發

[English](../development.md) · 繁體中文

## 需求

- Apple Silicon Mac
- macOS 13 以上版本
- Swift 5.9
- Xcode Command Line Tools

## 建置

```sh
git clone https://github.com/shihyuho/berth.git
cd berth
./Scripts/build.sh
```

建置會產生使用 ad-hoc 簽章的 `dist/Berth.app`。啟用「登入時自動啟動」前，請先將 App 移至「應用程式」。重新建置後可能需要再次授予「輔助使用」權限。

## 版本檔案

`version.txt` 是發布版本來源。Release Please 會同時更新它與 `Support/Info.plist` 中的 `CFBundleShortVersionString`、`CFBundleVersion`。

## 發布封裝

`Scripts/package_release.sh <version>` 會建置 arm64 App、驗證簽章與架構，並產生 GitHub Release ZIP。`Scripts/render_cask.sh` 會依發布版本與 SHA-256 checksum 產生對應的 Homebrew Cask。
