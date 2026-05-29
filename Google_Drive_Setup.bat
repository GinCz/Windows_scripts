@echo off
chcp 65001 >nul
cls
setlocal

:: ==========================================================================================
:: FILE    : Google_Drive_Setup.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Downloads and launches the Google Drive for Desktop installer.
::   Fetches the official installer from Google's CDN (dl.google.com).
::   Creates a timestamped temporary folder in C:\Windows\Temp,
::   downloads GoogleDriveSetup.exe, then launches it automatically.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11
::   - Active internet connection
::   - No administrator rights required
::
:: USAGE:
::   1. Double-click Google_Drive_Setup.bat
::   2. Wait for the download to complete
::   3. The installer launches automatically
:: ==========================================================================================

set "download_url=https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"

set "temp_dir=C:\Windows\Temp\"
set "date_time=%date:~0,2%-%date:~3,2%-%date:~6,4%__%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "new_dir=%temp_dir%%date_time%"

mkdir "%new_dir%"
if errorlevel 1 (
    echo Failed to create temporary folder.
    pause
    exit /b 1
)

set "download_path=%new_dir%\GoogleDriveSetup.exe"

color 09
cls
echo +------------------+
echo ^|  L O A D I N G  ^|
echo +------------------+
echo.
echo Downloading Google Drive for Desktop...
echo.

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%download_url%', '%download_path%')"
if errorlevel 1 (
    echo [!] Download failed.
    pause
    exit /b 1
)

echo [OK] Launching Google Drive installer...
echo.
echo = Rooted by VladiMIR ^| AI =
start "" "%download_path%"
endlocal
