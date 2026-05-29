@echo off
chcp 65001 >nul
cls
setlocal

:: ==========================================================================================
:: FILE    : Telegram_Setup.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Downloads and launches the latest Telegram Desktop (x64) installer.
::   Uses BITS (Background Intelligent Transfer Service) for downloading,
::   which provides live progress output directly in the CMD window.
::   Always fetches the latest release from the official Telegram CDN
::   (telegram.org/dl/desktop/win64), so no manual URL updates are needed.
::   Creates a timestamped temporary folder in C:\Windows\Temp for the download.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11 (x64)
::   - Active internet connection
::   - No administrator rights required
::
:: USAGE:
::   1. Double-click Telegram_Setup.bat
::   2. Live BITS download progress is shown in the CMD window
::   3. TelegramSetup.exe launches automatically after download
:: ==========================================================================================

set "download_url=https://telegram.org/dl/desktop/win64"

set "temp_dir=C:\Windows\Temp\"
set "date_time=%date:~0,2%-%date:~3,2%-%date:~6,4%__%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "date_time=%date_time: =0%"
set "new_dir=%temp_dir%%date_time%"

mkdir "%new_dir%" 2>nul
if errorlevel 1 (
    echo Failed to create temporary folder "%new_dir%".
    pause
    exit /b 1
)

set "download_path=%new_dir%\TelegramSetup.exe"

color 0B
cls
echo =====================================================================
echo.
color 0E
echo  D O W N L O A D I N G   T E L E G R A M   D E S K T O P
color 0B
echo.
echo   Latest x64 version - live BITS progress below
echo.
echo =====================================================================
echo.

powershell -NoProfile -WindowStyle Normal -Command "Start-BitsTransfer -Source '%download_url%' -Destination '%download_path%' -DisplayName 'Telegram Desktop Setup' -Description 'Downloading latest version...' -Priority High"

if errorlevel 1 (
    color 0C
    echo.
    echo [!] Failed to download Telegram installer.
    pause
    exit /b 1
)

color 0A
echo.
echo [OK] Download completed. Launching installer...
echo.
echo = Rooted by VladiMIR ^| AI =

start "" "%download_path%"
endlocal
