:: ==========================================================================================
:: FILE: RustDesk_peers___LOAD.bat
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
title RustDesk Config Backup - LOAD

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' RustDesk Configuration Restoration (Network Share)' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

set "DEST_DIR=%USERPROFILE%\AppData\Roaming\RustDesk\config"
set "NETWORK_ZIP=\\s.gincz.com\user\RustDesk_BackUp\RustDesk_config.zip"

echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Stops running RustDesk processes.
echo   * Extracts configuration archive from network share to local config folder (Overwrite).
echo   * Restarts the RustDesk application.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Network Archive  : %NETWORK_ZIP%
echo   Target Directory : %DEST_DIR%
echo ==========================================================================================
echo.

echo [+] Stopping RustDesk process...
taskkill /IM rustdesk.exe /F 2>nul
timeout /T 1 /NOBREAK >nul

echo [+] Extracting archive to configuration folder...
powershell -NoProfile -Command "Expand-Archive -Path '%NETWORK_ZIP%' -DestinationPath '%DEST_DIR%' -Force"

if errorlevel 1 (
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Failed to extract configuration archive.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo [+] Waiting for file operations to complete...
timeout /T 3 /NOBREAK >nul

echo [+] Starting RustDesk...
start "" "C:\Program Files\RustDesk\rustdesk.exe"

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' SUCCESS: RustDesk configuration successfully restored!' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"

timeout /t 3 >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
