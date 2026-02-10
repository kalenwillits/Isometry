#!/usr/bin/env bash
set -euo pipefail

# PLACEHOLDER: macOS builds require a macOS host machine or CI pipeline.
# This script cannot produce a working macOS build on this Linux machine.
# To build for macOS:
#   1. Install Godot 4.4+ on a macOS machine
#   2. Install the macOS export template
#   3. Run: godot --headless --path app --export-release "macOS" app/build/isometry_macos.zip

echo "ERROR: macOS builds are not supported on this machine."
echo "macOS builds require a macOS host with Xcode and codesigning configured."
echo ""
echo "To build on macOS, run:"
echo "  godot --headless --path app --export-release \"macOS\" app/build/isometry_macos.zip"
exit 1
