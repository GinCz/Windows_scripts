#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> [1/2] Compiling Windows resource (app.rc)..."
x86_64-w64-mingw32-windres -i "$SCRIPT_DIR/app.rc" -O coff -o "$SCRIPT_DIR/app.syso"

echo "==> [2/2] Building GIN-DNS-Switch_Setup.exe..."
(cd "$SCRIPT_DIR" && GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H=windowsgui -s -w" -o "$ROOT_DIR/GIN-DNS-Switch_Setup.exe" .)
cp "$ROOT_DIR/GIN-DNS-Switch_Setup.exe" "$ROOT_DIR/GIN-DNS-Switch_v001_Setup.exe"

echo "✅ Build Complete: GIN-DNS-Switch_Setup.exe"
