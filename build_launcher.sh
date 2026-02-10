#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/Apps/Godot/Godot.x86_64}"
PROJECT_DIR="$(cd "$(dirname "$0")/app" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

mkdir -p "$BUILD_DIR"

PLATFORM="${1:-linux}"

case "$PLATFORM" in
    linux)
        echo "Building Isometry Launcher for Linux..."
        "$GODOT" --headless --path "$PROJECT_DIR" --export-release "Launcher Linux" "$BUILD_DIR/isometry_launcher_linux.x86_64"
        echo "Build complete: $BUILD_DIR/isometry_launcher_linux.x86_64"
        ;;
    windows)
        echo "Building Isometry Launcher for Windows..."
        "$GODOT" --headless --path "$PROJECT_DIR" --export-release "Launcher Windows" "$BUILD_DIR/isometry_launcher_windows.exe"
        echo "Build complete: $BUILD_DIR/isometry_launcher_windows.exe"
        ;;
    *)
        echo "Usage: $0 [linux|windows]"
        exit 1
        ;;
esac
