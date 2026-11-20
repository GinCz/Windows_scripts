#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> [1/3] Compiling Uninstall.exe..."
mcs -target:winexe -optimize+ -platform:anycpu \
  -win32icon:"$SCRIPT_DIR/app.ico" \
  -r:System.dll,System.Windows.Forms.dll \
  -out:"$SCRIPT_DIR/Uninstall.exe" \
  "$SCRIPT_DIR/Uninstall.cs"

echo "==> [2/3] Compiling GIN-Dock-Wallpaper.exe..."
mcs -target:winexe -optimize+ -platform:anycpu \
  -win32icon:"$SCRIPT_DIR/app.ico" \
  -r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll \
  -out:"$SCRIPT_DIR/GIN-Dock-Wallpaper.exe" \
  "$SCRIPT_DIR/GIN-Dock-Wallpaper.cs"

echo "==> [3/3] Compiling GIN-Dock-Wallpaper_v032_Setup.exe..."
mcs -target:winexe -optimize+ -platform:anycpu \
  -win32icon:"$SCRIPT_DIR/app.ico" \
  -r:System.dll,System.Windows.Forms.dll,Microsoft.CSharp.dll,System.Core.dll \
  -out:"$ROOT_DIR/GIN-Dock-Wallpaper_v032_Setup.exe" \
  "$SCRIPT_DIR/installer_setup.cs"

echo "✅ Build Complete!"
