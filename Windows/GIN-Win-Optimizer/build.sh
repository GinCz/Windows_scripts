#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Compressing Engine Script ==="
gzip -9 -k -f engine.ps1

echo "=== Compiling Win32 Resources (PE32 x86) ==="
x86_64-w64-mingw32-windres -O res app.rc -o app.res

echo "=== Compiling GIN-Win-Optimizer.exe via mcs (PE32 x86 Ultralight ~172 KB) ==="
mcs /target:winexe /platform:x86 -win32res:app.res /resource:engine.ps1.gz /resource:app.ico -r:System.Windows.Forms.dll -r:System.Drawing.dll /out:GIN-Win-Optimizer.exe Program.cs

rm -f app.res
ls -lh GIN-Win-Optimizer.exe
file GIN-Win-Optimizer.exe
echo "=== Build Successful ==="
