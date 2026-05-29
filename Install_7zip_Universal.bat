@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: ==========================================================================================
:: FILE    : Install_7zip_Universal.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Universal 7-Zip auto-installer for Windows.
::   Automatically detects the CPU architecture (x64, ARM64, or x86),
::   fetches the latest 7-Zip version number directly from 7-zip.org,
::   constructs the correct download URL, downloads the installer,
::   and performs a silent installation without user interaction.
::   Supports all modern Windows platforms including ARM64 laptops.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11 (x64, ARM64, or x86)
::   - Active internet connection
::   - Must be run as Administrator
::
:: USAGE:
::   1. Right-click Install_7zip_Universal.bat -> Run as administrator
::   2. Architecture is detected automatically
::   3. Latest 7-Zip version is fetched from 7-zip.org
::   4. Silent installation completes without prompts
:: ==========================================================================================

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
echo %B%   7-Zip Universal Auto-Installer v2026.05.29 ^|  = Rooted by VladiMIR ^| AI =%X%
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

echo %W% Detected architecture: %G%%ARCH%%X%
echo.

:: Fetch latest version from 7-zip.org
echo %W% Fetching latest 7-Zip version from 7-zip.org...%X%
for /f "tokens=*" %%i in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri 'https://www.7-zip.org/download.html' -UseBasicParsing).Content -match '7-Zip ([0-9]+\.[0-9]+)' | Out-Null; $Matches[1]"') do set "VER=%%i"

if "%VER%"=="" (
    echo %R% [!] Failed to fetch version. Check internet connection.%X%
    pause
    exit /b 1
)

set "VER_NODOT=%VER:.=%"
set "DL_URL=https://www.7-zip.org/a/7z%VER_NODOT%-%ARCH%.exe"

echo %W% Latest version: %G%%VER%%X%
echo %W% Download URL:   %B%%DL_URL%%X%
echo.

:: Download installer
set "TMP_FILE=%TEMP%\7z_setup_%ARCH%.exe"
echo %W% Downloading installer...%X%
powershell -NoProfile -Command "(New-Object System.Net.WebClient).DownloadFile('%DL_URL%', '%TMP_FILE%')"

if not exist "%TMP_FILE%" (
    echo %R% [!] Download failed.%X%
    pause
    exit /b 1
)

:: Silent install
echo %W% Installing 7-Zip %VER% silently...%X%
start /wait "" "%TMP_FILE%" /S

if exist "%INSTALL_DIR%\7z.exe" (
    echo.
    echo %G% [OK] 7-Zip %VER% installed successfully!%X%
    echo %W%       Location: %INSTALL_DIR%%X%
) else (
    echo %R% [!] Installation may have failed. Check manually.%X%
)

del /f /q "%TMP_FILE%" 2>nul
echo.
echo %Y% = Rooted by VladiMIR ^| AI =%X%
echo.
pause
endlocal
