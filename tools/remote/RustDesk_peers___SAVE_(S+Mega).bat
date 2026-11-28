:: ==========================================================================================
:: FILE: RustDesk_peers___SAVE_(S+Mega).bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (Robust syntax for special characters like & and spaces)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title RustDesk Config Backup - SAVE

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' RustDesk Configuration Backup (Local + Network)' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

set "SOURCE_DIR=%USERPROFILE%\AppData\Roaming\RustDesk\config\"
set "LOCAL_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\RustDesk\RustDesk_config.zip"
set "NETWORK_ZIP=\\s.gincz.com\user\RustDesk_BackUp\RustDesk_config.zip"

echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Backs up RustDesk configuration files (excluding RustDesk.toml).
echo   * Compresses data into a secure archive locally on MEGA storage.
echo   * Synchronizes backup copy to the remote corporate network share.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Source Directory : %SOURCE_DIR%
echo   Local Archive    : %LOCAL_ZIP%
echo   Network Share    : %NETWORK_ZIP%
echo ==========================================================================================
echo.

echo [+] Creating local archive backup...
powershell -NoProfile -Command "Get-ChildItem -Path '%SOURCE_DIR%' -Exclude 'RustDesk.toml' | Compress-Archive -DestinationPath '%LOCAL_ZIP%' -Force"

if errorlevel 1 (
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Local archive creation failed.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo [+] Copying archive to network storage share...
powershell -NoProfile -Command "Copy-Item -Path '%LOCAL_ZIP%' -Destination '%NETWORK_ZIP%' -Force"

if errorlevel 1 (
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Copy to network share failed.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' SUCCESS: Backup completed successfully to both local and network locations!' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"

timeout /t 3 >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
