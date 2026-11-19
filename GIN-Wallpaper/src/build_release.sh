#!/usr/bin/env bash
# ==============================================================================
# GIN-Wallpaper-Calend - Universal 32/64-bit Windows Build Engine (v030)
# Builds:
#   1. Uninstall.exe (Universal 32-bit PE uninstaller with embedded .rsrc icon)
#   2. GIN-Wallpaper-Calend.exe (Universal 32-bit PE runner with embedded font & icon)
#   3. ../GIN-Wallpaper-Calend_v030_Setup.exe (Compressed Universal 32-bit Installer)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_TMP="/tmp/gin_wall_build"
rm -rf "$BUILD_TMP"
mkdir -p "$BUILD_TMP"

echo "==> [1/3] Building Universal 32-bit Uninstall.exe..."
mkdir -p "$BUILD_TMP/uninstaller"
cp "$SCRIPT_DIR/uninstaller_native.go" "$BUILD_TMP/uninstaller/main.go"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/uninstaller/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/uninstaller/"
i686-w64-mingw32-windres -i "$SCRIPT_DIR/app_uninst.rc" -O coff -F pe-i386 -o "$BUILD_TMP/uninstaller/app.syso"
(cd "$BUILD_TMP/uninstaller" && GOOS=windows GOARCH=386 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/Uninstall.exe" .)

echo "==> [2/3] Building Universal 32-bit GIN-Wallpaper-Calend.exe..."
mkdir -p "$BUILD_TMP/runner"
cp "$SCRIPT_DIR/wallpaper_native.go" "$BUILD_TMP/runner/main.go"
cp "$SCRIPT_DIR/font.ttf" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/app.ico" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/runner/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/runner/"
i686-w64-mingw32-windres -i "$SCRIPT_DIR/app_runner.rc" -O coff -F pe-i386 -o "$BUILD_TMP/runner/app.syso"
(cd "$BUILD_TMP/runner" && GOOS=windows GOARCH=386 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/GIN-Wallpaper-Calend.exe" .)

echo "==> [3/3] Compressing payloads and building GIN-Wallpaper-Calend_v030_Setup.exe..."
mkdir -p "$BUILD_TMP/installer"
gzip -9 -c "$SCRIPT_DIR/GIN-Wallpaper-Calend.exe" > "$BUILD_TMP/installer/GIN-Wallpaper-Calend.exe.gz"
gzip -9 -c "$SCRIPT_DIR/Uninstall.exe" > "$BUILD_TMP/installer/Uninstall.exe.gz"
cp "$SCRIPT_DIR/installer_native.go" "$BUILD_TMP/installer/main.go"
cp "$SCRIPT_DIR/app.ico" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/go.mod" "$BUILD_TMP/installer/"
cp "$SCRIPT_DIR/go.sum" "$BUILD_TMP/installer/"
i686-w64-mingw32-windres -i "$SCRIPT_DIR/app.rc" -O coff -F pe-i386 -o "$BUILD_TMP/installer/app.syso"
(cd "$BUILD_TMP/installer" && GOOS=windows GOARCH=386 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$ROOT_DIR/GIN-Wallpaper-Calend_v030_Setup.exe" .)

# Cleanup previous versions from root
rm -f "$ROOT_DIR/GIN-Wallpaper-Calend_v029_Setup.exe" "$ROOT_DIR/GIN-Wallpaper-Calend_v028_Setup.exe"

rm -rf "$BUILD_TMP"
echo "✅ Universal Build Complete: $ROOT_DIR/GIN-Wallpaper-Calend_v030_Setup.exe"
