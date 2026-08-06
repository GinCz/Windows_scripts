:: ==========================================================================================
:: FILE: RustDesk_Downloader.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title RustDesk Installer Downloader - LOAD

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Universal RustDesk Stable Installer Downloader (Latest Release)' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

echo [+] Resolving latest version from official GitHub API...

set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

:: Determine architecture
set "is_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "is_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "is_64=1"

:: Get URL safely via PowerShell and handle errors explicitly
powershell -NoProfile -Command "%ps_tls%; try { $r = Invoke-RestMethod 'https://api.github.com/repos/rustdesk/rustdesk/releases/latest'; if (%is_64% -eq 1) { $asset = $r.assets | Where-Object { $_.name -like '*x86_64.exe' -and $_.name -notlike '*uv.exe' } } else { $asset = $r.assets | Where-Object { $_.name -like '*x86.exe' } }; if ($asset) { $asset.browser_download_url | Out-File -Encoding utf8 '%TEMP%\rustdesk_url.tmp' } else { throw 'Asset not found' } } catch { 'https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.4.5-x86_64.exe' | Out-File -Encoding utf8 '%TEMP%\rustdesk_url.tmp' }"

set /p download_url=<"%TEMP%\rustdesk_url.tmp"
del /f /q "%TEMP%\rustdesk_url.tmp" >nul 2>&1

:: Extract filename from URL
for %%I in ("%download_url%") do set "filename=%%~nxI"
if "%is_64%"=="1" (set "arch_type=x64 (64-bit)") else (set "arch_type=x86 (32-bit)")

echo.
echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Automatically queries GitHub API for the absolute LATEST stable version.
echo   * Detects host OS architecture (%arch_type%).
echo   * Securely downloads and launches the installer.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Detected OS Architecture : %arch_type%
echo   Target File Name         : %filename%
echo   Target Download URL      : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...
set "new_dir=C:\Windows\Temp\rustdesk_dynamic_session_%RANDOM%"
mkdir "%new_dir%" 2>nul
set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest installer version from official GitHub servers...
echo.

powershell -NoProfile -Command "%ps_tls%; $ProgressPreference='SilentlyContinue'; Write-Host 'Downloading... [ ' -NoNewline; Invoke-WebRequest -Uri '%download_url%' -OutFile '%download_path%'; Write-Host 'DONE ]' -ForegroundColor Green"

if errorlevel 1 (
    echo.
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Download failed. Check connection or URL.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo.
echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' SUCCESS: Download completed successfully! Launching installer execution...' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"

start "" "%download_path%"

timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
