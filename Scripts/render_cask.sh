#!/bin/bash
# 依 GitHub Release 版本與 checksum 產生 Homebrew Cask。
set -euo pipefail

VERSION="${1:?用法：$0 <version> <sha256> <output>}"
SHA256="${2:?用法：$0 <version> <sha256> <output>}"
OUTPUT="${3:?用法：$0 <version> <sha256> <output>}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ 無效版本：$VERSION" >&2
    exit 1
fi
if [[ ! "$SHA256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "❌ 無效 SHA-256：$SHA256" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" <<EOF
cask "berth" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/shihyuho/berth/releases/download/#{version}/Berth-arm64.zip"
  name "Berth"
  desc "Keep your macOS Dock on the display you choose"
  homepage "https://github.com/shihyuho/berth"

  depends_on macos: :ventura
  depends_on arch: :arm64

  app "Berth.app"

  caveats do
    unsigned_accessibility
  end
end
EOF

echo "✅ Cask：$OUTPUT"
