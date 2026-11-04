@echo off
setlocal
cd /d "%~dp0"

echo === Compressing Engine Script ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "$src = 'engine.ps1'; $dst = 'engine.ps1.gz'; $b = [System.IO.File]::ReadAllBytes($src); $fs = [System.IO.File]::Create($dst); $gz = New-Object System.IO.Compression.GZipStream($fs, [System.IO.Compression.CompressionMode]::Compress, $false); $gz.Write($b, 0, $b.Length); $gz.Close(); $fs.Close()"

echo === Compiling Ultralight Universal Native Win32 GUI Launcher via csc.exe (32-bit x86 PE32 compatible with both 32-bit & 64-bit Windows) ===
set CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
"%CSC%" /target:winexe /optimize+ /platform:x86 /win32icon:app.ico /win32manifest:app.manifest /resource:engine.ps1.gz /resource:app.ico /out:GIN-Win-Optimizer.exe Program.cs

echo === Done! Binary size: ===
dir GIN-Win-Optimizer.exe | findstr GIN-Win-Optimizer.exe
