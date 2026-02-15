#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/Apps/Godot/Godot.x86_64}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/releases"

mkdir -p "$BUILD_DIR"

echo "Building Isometry for Windows..."
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Windows" "$BUILD_DIR/isometry_windows.exe"

echo "Build complete: $BUILD_DIR/isometry_windows.exe"
