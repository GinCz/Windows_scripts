@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b 1
)

:: Enable ANSI colors
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "Y=%ESC%[33m" & set "B=%ESC%[96m" & set "W=%ESC%[37m" & set "G=%ESC%[92m" & set "R=%ESC%[31m" & set "X=%ESC%[0m"

echo %Y%================================================================================%X%
echo %B%   7-Zip Universal Auto-Installer v2026-05-05  ^|  = Rooted by VladiMIR ^| AI =%X%
echo %Y%================================================================================%X%
echo.

:: Detect architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ARCH=x64"
    set "INSTALL_DIR=C:\Program Files\7-Zip"
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=arm64"
    set "INSTALL_DIR=C:\Program Files\7-Zip"
) else (
    set "ARCH=x86"
    set "INSTALL_DIR=C:\Program Files (x86)\7-Zip"
)
set "INSTALL_PATH=!INSTALL_DIR!\7z.exe"
echo %W%[-] Detected Architecture : %Y%!ARCH!%X%

:: Check if already installed
if exist "!INSTALL_PATH!" (
    for /f "tokens=*" %%v in ('"!INSTALL_PATH!" i 2^>nul ^| findstr /i "7-Zip"') do set "INSTALLED_VER=%%v"
    echo %G%[OK] 7-Zip already installed: !INSTALL_PATH!%X%
    echo %W%     Version: !INSTALLED_VER!%X%
    echo.
    set /p "REINSTALL=Reinstall / update? [Y/N]: "
    if /i "!REINSTALL!" neq "Y" (
        echo %G%[OK] Installation skipped.%X%
        goto :EOF
    )
)

:: Fetch latest version from 7-zip.org
echo %W%[-] Fetching latest version from 7-zip.org...%X%
set "TMPHTML=%TEMP%\7zip_dl.html"
curl -s -L -o "!TMPHTML!" "https://www.7-zip.org/download.html"
if not exist "!TMPHTML!" (
    echo %R%[!] Failed to fetch 7-zip.org. Check internet connection.%X%
    pause
    exit /b 1
)

:: Parse version number via PowerShell regex
set "VER="
for /f "tokens=*" %%L in ('findstr /i "7z[0-9][0-9][0-9][0-9]" "!TMPHTML!"') do (
    if not defined VER (
        for /f "delims=" %%V in ('powershell -NoProfile -Command "if ('%%L' -match '7z(\d{4})') { $matches[1] }"') do (
            if not defined VER set "VER=%%V"
        )
    )
)

if not defined VER (
    echo %R%[!] Could not auto-detect version. Using fallback: 2601%X%
    set "VER=2601"
)
echo %G%[OK] Latest 7-Zip version detected: %Y%7z!VER!%X%

:: Build download URL
if "!ARCH!"=="x64"   set "DL_URL=https://www.7-zip.org/a/7z!VER!-x64.exe"
if "!ARCH!"=="arm64" set "DL_URL=https://www.7-zip.org/a/7z!VER!-arm64.exe"
if "!ARCH!"=="x86"   set "DL_URL=https://www.7-zip.org/a/7z!VER!.exe"

echo %W%[-] Download URL : !DL_URL!%X%
echo.

:: Download
set "SETUP=%TEMP%\7z_setup.exe"
echo %W%[-] Downloading...%X%
curl -L --progress-bar -o "!SETUP!" "!DL_URL!"

if not exist "!SETUP!" (
    echo %R%[!] Download failed!%X%
    pause
    exit /b 1
)

:: Silent install
echo %W%[-] Installing silently...%X%
start /wait "" "!SETUP!" /S
del "!SETUP!" >nul 2>&1

:: Verify installation
if exist "!INSTALL_PATH!" (
    for /f "tokens=*" %%v in ('"!INSTALL_PATH!" i 2^>nul ^| findstr /i "7-Zip"') do set "NEW_VER=%%v"
    echo.
    echo %G%[OK] 7-Zip successfully installed!%X%
    echo %G%     Path    : !INSTALL_PATH!%X%
    echo %G%     Version : !NEW_VER!%X%
) else (
    echo %R%[!] Installation failed! Please install manually from https://www.7-zip.org%X%
    pause
    exit /b 1
)

del "!TMPHTML!" >nul 2>&1
echo.
echo %Y%================================================================================%X%
echo %G%  DONE  ^|  = Rooted by VladiMIR ^| AI =%X%
echo %Y%================================================================================%X%
echo.
pause
