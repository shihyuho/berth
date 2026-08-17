#!/bin/bash
# 建置版本化的 Homebrew Cask 發布 ZIP。
set -euo pipefail
cd "$(dirname "$0")/.."

EXPECTED_VERSION="${1:?用法：$0 <version>}"
VERSION="$(tr -d '\r\n' < version.txt)"

if [[ "$VERSION" != "$EXPECTED_VERSION" ]]; then
    echo "❌ version.txt ($VERSION) 與預期發布版本 ($EXPECTED_VERSION) 不一致" >&2
    exit 1
fi

BERTH_ARCH=arm64 ./Scripts/build.sh

ASSET="dist/Berth-${VERSION}-arm64.zip"
rm -f "$ASSET"
ditto --norsrc -c -k --keepParent dist/Berth.app "$ASSET"

codesign --verify --deep --strict dist/Berth.app
file dist/Berth.app/Contents/MacOS/Berth | grep -q 'arm64'
shasum -a 256 "$ASSET"
echo "✅ 發布產物：$ASSET"
