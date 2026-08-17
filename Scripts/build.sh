#!/bin/bash
# 建置並打包成 dist/Berth.app
set -euo pipefail
cd "$(dirname "$0")/.."

ARCH="${BERTH_ARCH:-arm64}"
VERSION="$(tr -d '\r\n' < version.txt)"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ version.txt 必須是 SemVer，目前為：$VERSION" >&2
    exit 1
fi

swift build -c release --arch "$ARCH"
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"

DIST=dist
APP="$DIST/Berth.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Berth" "$APP/Contents/MacOS/Berth"
cp Support/Info.plist "$APP/Contents/Info.plist"

SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")"
if [[ "$SHORT_VERSION" != "$VERSION" || "$BUNDLE_VERSION" != "$VERSION" ]]; then
    echo "❌ Info.plist 版本 ($SHORT_VERSION/$BUNDLE_VERSION) 與 version.txt ($VERSION) 不一致" >&2
    exit 1
fi

ICONSET="$DIST/icon.iconset"
rm -rf "$ICONSET"
if swift Scripts/make_icon.swift "$ICONSET" && iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"; then
    rm -rf "$ICONSET"
else
    echo "⚠️ icon 產生失敗，略過 (不影響功能)" >&2
fi

codesign --force --sign - "$APP"
echo "✅ 完成：$APP ($ARCH, $VERSION)"
echo "ℹ️  重新建置後簽章已改變：若先前授權過「輔助使用」，請到系統設定把 Berth 關掉再重新開啟一次"
