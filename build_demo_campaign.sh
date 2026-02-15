#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAMPAIGN_SRC="$SCRIPT_DIR/campaigns/demo"
TARGET_DIR="$SCRIPT_DIR/releases/campaigns/"

mkdir -p "$TARGET_DIR"

echo "Packaging demo campaign..."
cd "$CAMPAIGN_SRC/.."
zip -r "$TARGET_DIR/demo.zip" demo/ -x "*.DS_Store"
echo "Demo campaign built: $TARGET_DIR/demo.zip"
