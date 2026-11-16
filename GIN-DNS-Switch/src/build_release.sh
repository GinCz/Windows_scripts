#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect version from version.json
VERSION=$(grep -o '"current_version": *"[^"]*"' "$ROOT_DIR/version.json" | cut -d'"' -f4)
if [ -z "$VERSION" ]; then
    VERSION="v012"
fi

SETUP_EXE="GIN-DNS-Switch_${VERSION}_Setup.exe"

echo "==> Building GIN-DNS-Switch version: $VERSION"

echo "==> [1/4] Compiling Uninstaller resource (uninstall.ico)..."
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/uninstaller/app.rc" -O coff -o "$SCRIPT_DIR/uninstaller/app.syso"

echo "==> [2/4] Building native Uninstall.exe with icon..."
(cd "$SCRIPT_DIR/uninstaller" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/Uninstall.exe" .)
cp "$SCRIPT_DIR/Uninstall.exe" "$ROOT_DIR/Uninstall.exe"

echo "==> [3/4] Compiling Windows resource (app.rc)..."
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app.rc" -O coff -o "$SCRIPT_DIR/app.syso"

echo "==> [4/4] Building $SETUP_EXE..."
(cd "$SCRIPT_DIR" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$ROOT_DIR/$SETUP_EXE" .)
cp "$ROOT_DIR/$SETUP_EXE" "$ROOT_DIR/GIN-DNS-Switch_Setup.exe"

echo "✅ Build Complete: $SETUP_EXE & Uninstall.exe"

# Automatic delivery to default MEGA cloud locations
MEGA_FLASH_PATH="/MEGA/WIN-FLASH/Util-WINDOWS/N E T/"
MEGA_DESKTOP_PATH="/MEGA/DOCS/desktop/"

if command -v mega-put >/dev/null 2>&1; then
    echo "==> Delivering to default MEGA cloud locations..."
    echo "  -> 1. $MEGA_FLASH_PATH"
    mega-put -c "$ROOT_DIR/$SETUP_EXE" "$MEGA_FLASH_PATH" || echo "⚠️ Warning: failed to upload to $MEGA_FLASH_PATH"
    echo "  -> 2. $MEGA_DESKTOP_PATH"
    mega-put -c "$ROOT_DIR/$SETUP_EXE" "$MEGA_DESKTOP_PATH" || echo "⚠️ Warning: failed to upload to $MEGA_DESKTOP_PATH"
fi

# Local Windows copy fallback if running under Git Bash / WSL on Vladimir's PC
LOCAL_FLASH="D:/MEGA/WIN-FLASH/Util-WINDOWS/N E T"
LOCAL_DESKTOP="D:/MEGA/DOCS/desktop"

if [ -d "$LOCAL_FLASH" ]; then
    echo "==> Copying to local $LOCAL_FLASH"
    cp "$ROOT_DIR/$SETUP_EXE" "$LOCAL_FLASH/$SETUP_EXE"
fi
if [ -d "$LOCAL_DESKTOP" ]; then
    echo "==> Copying to local $LOCAL_DESKTOP"
    cp "$ROOT_DIR/$SETUP_EXE" "$LOCAL_DESKTOP/$SETUP_EXE"
fi

echo "🚀 All target deliveries finished."
