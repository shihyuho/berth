#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

MINIMUM="${1:-90}"
COVERAGE_JSON="$(swift test --show-codecov-path)"

swift Scripts/check_coverage.swift "$COVERAGE_JSON" "$MINIMUM"
