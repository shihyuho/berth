#!/bin/bash
# 建置並打包成 dist/Berth.app
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

DIST=dist
APP="$DIST/Berth.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Berth "$APP/Contents/MacOS/Berth"
cp Support/Info.plist "$APP/Contents/Info.plist"

ICONSET="$DIST/icon.iconset"
rm -rf "$ICONSET"
if swift Scripts/make_icon.swift "$ICONSET" && iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"; then
    rm -rf "$ICONSET"
else
    echo "⚠️ icon 產生失敗,略過(不影響功能)" >&2
fi

codesign --force --sign - "$APP"
echo "✅ 完成:$APP"
echo "ℹ️  重新建置後簽章已改變:若先前授權過「輔助使用」,請到系統設定把 Berth 關掉再重新開啟一次"
