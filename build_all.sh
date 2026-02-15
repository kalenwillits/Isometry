#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED=0

for script in \
    "$SCRIPT_DIR/build_linux.sh" \
    "$SCRIPT_DIR/build_windows.sh" \
    "$SCRIPT_DIR/build_macos.sh" \
    "$SCRIPT_DIR/build_launcher_linux.sh" \
    "$SCRIPT_DIR/build_launcher_windows.sh" \
    "$SCRIPT_DIR/build_launcher_macos.sh" \
    "$SCRIPT_DIR/build_demo_campaign.sh"; do
    echo "=== Running $(basename "$script") ==="
    if bash "$script"; then
        echo "=== $(basename "$script") succeeded ==="
    else
        echo "=== $(basename "$script") FAILED ==="
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

if [ "$FAILED" -gt 0 ]; then
    echo "$FAILED build(s) failed."
    exit 1
else
    echo "All builds succeeded."
fi
