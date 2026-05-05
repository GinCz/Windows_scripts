@echo off
chcp 65001 >nul
cls
setlocal

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =
:: Downloads and launches UNIGINE Heaven Benchmark 4.0 GPU stress test installer

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
