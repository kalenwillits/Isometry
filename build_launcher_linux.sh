#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT:-$HOME/Apps/Godot/Godot.x86_64}"
PROJECT_DIR="$(cd "$(dirname "$0")/app" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

mkdir -p "$BUILD_DIR"

echo "Building Isometry Launcher for Linux..."
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Launcher Linux" "$BUILD_DIR/isometry_launcher_linux.x86_64"

echo "Build complete: $BUILD_DIR/isometry_launcher_linux.x86_64"
