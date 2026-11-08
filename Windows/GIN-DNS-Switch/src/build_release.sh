#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> [1/3] Building native Uninstall.exe..."
(cd "$SCRIPT_DIR/uninstaller" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$SCRIPT_DIR/Uninstall.exe" main.go)
cp "$SCRIPT_DIR/Uninstall.exe" "$ROOT_DIR/Uninstall.exe"

echo "==> [2/3] Compiling Windows resource (app.rc)..."
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app.rc" -O coff -o "$SCRIPT_DIR/app.syso"

echo "==> [3/3] Building GIN-DNS-Switch_v005_Setup.exe..."
(cd "$SCRIPT_DIR" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$ROOT_DIR/GIN-DNS-Switch_v005_Setup.exe" .)
cp "$ROOT_DIR/GIN-DNS-Switch_v005_Setup.exe" "$ROOT_DIR/GIN-DNS-Switch_Setup.exe"

echo "✅ Build Complete: GIN-DNS-Switch_v005_Setup.exe & Uninstall.exe"
