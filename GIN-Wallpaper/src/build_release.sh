#!/usr/bin/env bash
# ==============================================================================
# GIN-Wallpaper-Calend - Native Windows Build Engine
# Builds:
#   1. Uninstall.exe (Native Windows uninstaller with embedded .rsrc icon)
#   2. GIN-Wallpaper-Calend.exe (Portable Runner with embedded .rsrc icon)
#   3. ../GIN-Wallpaper-Calend_v028_Setup.exe (Standalone Installer with .rsrc icon)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_TMP="/tmp/gin_wall_build"
rm -rf "$BUILD_TMP"
mkdir -p "$BUILD_TMP"

echo "==> [1/3] Building Uninstall.exe..."
mkdir -p "$BUILD_TMP/uninstaller"
cp "$SCRIPT_DIR/uninstaller_native.go" "$BUILD_TMP/uninstaller/main.go"
cp "$SCRIPT_DIR/app.ico" "$BUILD_TMP/uninstaller/"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/uninstaller/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/uninstaller/"
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app_uninst.rc" -O coff -o "$BUILD_TMP/uninstaller/app.syso"
(cd "$BUILD_TMP/uninstaller" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/Uninstall.exe" .)

echo "==> [2/3] Building GIN-Wallpaper-Calend.exe..."
mkdir -p "$BUILD_TMP/runner"
cp "$SCRIPT_DIR/wallpaper_native.go" "$BUILD_TMP/runner/main.go"
cp "$SCRIPT_DIR/font.ttf" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/app.ico" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/runner/"
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app_runner.rc" -O coff -o "$BUILD_TMP/runner/app.syso"
(cd "$BUILD_TMP/runner" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/GIN-Wallpaper-Calend.exe" .)

echo "==> [3/3] Building GIN-Wallpaper-Calend_v028_Setup.exe..."
mkdir -p "$BUILD_TMP/installer"
cp "$SCRIPT_DIR/installer_native.go" "$BUILD_TMP/installer/main.go"
cp "$SCRIPT_DIR/GIN-Wallpaper-Calend.exe" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/Uninstall.exe" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/app.ico" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/installer/"
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app.rc" -O coff -o "$BUILD_TMP/installer/app.syso"
(cd "$BUILD_TMP/installer" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$ROOT_DIR/GIN-Wallpaper-Calend_v028_Setup.exe" .)

rm -rf "$BUILD_TMP"
echo "✅ Build Complete!"
