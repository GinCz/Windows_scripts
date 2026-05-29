@echo off
chcp 65001 >nul
cls
setlocal

:: ==========================================================================================
:: FILE    : Heaven_Benchmark_Setup.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Downloads and launches the UNIGINE Heaven Benchmark 4.0 installer.
::   Heaven Benchmark is a GPU stress test tool used to assess graphics card
::   stability, performance, and temperature under heavy rendering load.
::   Fetches the official installer from assets.unigine.com.
::   Creates a timestamped temporary folder and launches the installer automatically.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11
::   - Active internet connection
::   - Dedicated GPU recommended (AMD / NVIDIA / Intel Arc)
::   - No administrator rights required
::
:: USAGE:
::   1. Double-click Heaven_Benchmark_Setup.bat
::   2. Wait for the download to complete
::   3. The UNIGINE Heaven 4.0 installer launches automatically
:: ==========================================================================================

set "download_url=https://assets.unigine.com/d/Unigine_Heaven-4.0.exe"

set "temp_dir=C:\Windows\Temp\"
set "date_time=%date:~0,2%-%date:~3,2%-%date:~6,4%__%time:~0,2%-%time:~3,2%-%time:~6,2%"
set "new_dir=%temp_dir%%date_time%"

mkdir "%new_dir%"
if errorlevel 1 (
    echo Failed to create temporary folder.
    pause
    exit /b 1
)

set "download_path=%new_dir%\Unigine_Heaven-4.0.exe"

color 09
cls
echo +------------------+
echo ^|  L O A D I N G  ^|
echo +------------------+
echo.
echo Downloading UNIGINE Heaven Benchmark 4.0...
echo.

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%download_url%', '%download_path%')"
if errorlevel 1 (
    echo [!] Download failed.
    pause
    exit /b 1
)

echo [OK] Launching Heaven Benchmark installer...
echo.
echo = Rooted by VladiMIR ^| AI =
start "" "%download_path%"
endlocal
