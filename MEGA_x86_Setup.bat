@echo off
chcp 65001 >nul
cls
setlocal

:: ==========================================================================================
:: FILE    : MEGA_x86_Setup.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Downloads and launches the MEGAsync x86 (32-bit) client installer.
::   MEGAsync is the official desktop sync client for the MEGA cloud storage service.
::   Uses the x86 (32-bit) build which runs on both 32-bit and 64-bit Windows systems.
::   Fetches the installer directly from mega.nz, saves to a timestamped
::   temporary folder in C:\Windows\Temp, then launches the installer automatically.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11 (x86 or x64)
::   - Active internet connection
::   - No administrator rights required
::
:: USAGE:
::   1. Double-click MEGA_x86_Setup.bat
::   2. Wait for the download to complete
::   3. MEGAsync installer launches automatically
:: ==========================================================================================

set "download_url=https://mega.nz/MEGAsyncSetup32.exe"

set "temp_dir=C:\Windows\Temp\"
set "date_time=%date:~0,2%-%date:~3,2%-%date:~6,4%__%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "new_dir=%temp_dir%%date_time%"

mkdir "%new_dir%"
if errorlevel 1 (
    echo Failed to create temporary folder.
    pause
    exit /b 1
)

set "download_path=%new_dir%\MEGAsyncSetup32.exe"

color 09
cls
echo +------------------+
echo ^|  L O A D I N G  ^|
echo +------------------+
echo.
echo Downloading MEGAsync x86...
echo.

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%download_url%', '%download_path%')"
if errorlevel 1 (
    echo [!] Download failed.
    pause
    exit /b 1
)

echo [OK] Launching MEGAsync installer...
echo.
echo = Rooted by VladiMIR ^| AI =
start "" "%download_path%"
endlocal
