#!/bin/bash
# 建置並打包成 dist/Berth.app
set -euo pipefail
cd "$(dirname "$0")/.."

ARCH="${BERTH_ARCH:-arm64}"
VERSION="$(tr -d '\r\n' < version.txt)"
CATALOG="Resources/Localizable.xcstrings"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ version.txt 必須是 SemVer，目前為：$VERSION" >&2
    exit 1
fi

DEVELOPER_DIR_PATH="$(xcode-select -p 2>/dev/null || true)"
if [[ "$DEVELOPER_DIR_PATH" != *.app/Contents/Developer ]]; then
    echo "❌ 在地化建置需要完整 Xcode；目前選用的 Developer 目錄為：${DEVELOPER_DIR_PATH:-未設定}" >&2
    echo "   請安裝 Xcode，並以 xcode-select 選用其 Contents/Developer 目錄。" >&2
    exit 1
fi

if ! XCSTRINGSTOOL="$(xcrun --find xcstringstool 2>/dev/null)"; then
    echo "❌ 找不到 String Catalog 編譯器 xcstringstool；請確認已安裝並選用完整 Xcode。" >&2
    exit 1
fi

swift Scripts/check_localizations.swift catalog "$CATALOG"

swift build -c release --arch "$ARCH"
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"

DIST=dist
APP="$DIST/Berth.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/Berth" "$APP/Contents/MacOS/Berth"
cp Support/Info.plist "$APP/Contents/Info.plist"
"$XCSTRINGSTOOL" compile "$CATALOG" --output-directory "$APP/Contents/Resources"

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

swift Scripts/check_localizations.swift bundle "$APP"

CHECK_ROOT="$(mktemp -d "$DIST/localization-check.XXXXXX")"
trap 'rm -rf "$CHECK_ROOT"' EXIT
CHECK_APP="$CHECK_ROOT/Berth.app"
LOCALIZATION_CHECK_EXECUTABLE="BerthLocalizationCheck"
EFFECTIVE_LANGUAGE_CHECK_EXECUTABLE="BerthEffectiveLanguageCheck"
cp -R "$APP" "$CHECK_APP"
swiftc Scripts/check_localizations.swift -o "$CHECK_APP/Contents/MacOS/$LOCALIZATION_CHECK_EXECUTABLE"
cp Scripts/check_effective_language.swift "$CHECK_ROOT/main.swift"
swiftc \
    "$CHECK_ROOT/main.swift" \
    Sources/Berth/AppLanguage.swift \
    Sources/Berth/AppStrings.swift \
    -o "$CHECK_APP/Contents/MacOS/$EFFECTIVE_LANGUAGE_CHECK_EXECUTABLE"
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleExecutable $EFFECTIVE_LANGUAGE_CHECK_EXECUTABLE" \
    "$CHECK_APP/Contents/Info.plist"
"$CHECK_APP/Contents/MacOS/$EFFECTIVE_LANGUAGE_CHECK_EXECUTABLE" \
    -AppleLanguages '(en)' en 'Currently using: English' Quit
"$CHECK_APP/Contents/MacOS/$EFFECTIVE_LANGUAGE_CHECK_EXECUTABLE" \
    -AppleLanguages '(zh-TW)' zh-TW '目前使用：繁體中文（台灣）' '結束'
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleExecutable $LOCALIZATION_CHECK_EXECUTABLE" \
    "$CHECK_APP/Contents/Info.plist"
"$CHECK_APP/Contents/MacOS/$LOCALIZATION_CHECK_EXECUTABLE" \
    -AppleLanguages '(fr)' --main-bundle-fallback
rm -rf "$CHECK_ROOT"
trap - EXIT

codesign --force --sign - "$APP"
echo "✅ 完成：$APP ($ARCH, $VERSION)"
echo "ℹ️  重新建置後簽章已改變：若先前授權過「輔助使用」，請到系統設定把 Berth 關掉再重新開啟一次"
