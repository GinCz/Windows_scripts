:: ==========================================================================================
:: FILE    : RustDesk_peers___LOAD.bat
:: VERSION : v2026.11.03
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
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
title RustDesk Config Backup - LOAD (v2026.11.03)

:: ANSI Colors (Windows 10/11 native, no powershell overhead)
set "ESC="
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "YELLOW=%ESC%[93m"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "GRAY=%ESC%[90m"
set "WHITE=%ESC%[97m"
set "CYAN=%ESC%[96m"

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
echo %GRAY% ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░%RESET%
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
echo %YELLOW%==========================================================================================%RESET%
echo %YELLOW% RustDesk Configuration Restoration (Network Share / Local Fallback) — v2026.11.03%RESET%
echo %YELLOW%==========================================================================================%RESET%
echo.

:: Ensure Windows Workstation service (LanmanWorkstation) is running for SMB network access
sc query LanmanWorkstation | findstr /i "RUNNING" >nul
if errorlevel 1 (
    echo %CYAN%[+] Starting Windows Workstation service (LanmanWorkstation)...%RESET%
    net start LanmanWorkstation >nul 2>&1
    timeout /t 1 /nobreak >nul
)

set "DEST_DIR=%USERPROFILE%\AppData\Roaming\RustDesk\config"
set "LOCAL_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\RustDesk\RustDesk_config.zip"
set "NETWORK_ZIP=\\s.gincz.com\user\RustDesk_BackUp\RustDesk_config.zip"
set "RESTORE_ZIP=%NETWORK_ZIP%"

echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Stops running RustDesk processes.
echo   * Extracts configuration archive from network share (or local MEGA fallback).
echo   * Restarts the RustDesk application.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Network Archive  : %NETWORK_ZIP%
echo   Local Fallback   : %LOCAL_ZIP%
echo   Target Directory : %DEST_DIR%
echo ==========================================================================================
echo.

:: Check source availability
if exist "%NETWORK_ZIP%" (
    set "RESTORE_ZIP=%NETWORK_ZIP%"
    echo %GREEN%[✓] Network archive found: %NETWORK_ZIP%%RESET%
) else if exist "%LOCAL_ZIP%" (
    set "RESTORE_ZIP=%LOCAL_ZIP%"
    echo %YELLOW%[!] Network archive unreachable. Using local MEGA backup: %LOCAL_ZIP%%RESET%
) else (
    echo.
    echo %RED%==========================================================================================%RESET%
    echo %RED% ERROR: Neither network nor local configuration archive was found!%RESET%
    echo %RED%==========================================================================================%RESET%
    pause
    exit /b 1
)

echo [+] Stopping RustDesk process...
taskkill /IM rustdesk.exe /F 2>nul
timeout /T 1 /NOBREAK >nul

echo [+] Extracting archive to configuration folder...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Expand-Archive -Path '%RESTORE_ZIP%' -DestinationPath '%DEST_DIR%' -Force"

if errorlevel 1 (
    echo.
    echo %RED%==========================================================================================%RESET%
    echo %RED% ERROR: Failed to extract configuration archive.%RESET%
    echo %RED%==========================================================================================%RESET%
    pause
    exit /b 1
)

echo [+] Waiting for file operations to complete...
timeout /T 2 /NOBREAK >nul

echo [+] Starting RustDesk...
if exist "C:\Program Files\RustDesk\rustdesk.exe" (
    start "" "C:\Program Files\RustDesk\rustdesk.exe"
)

echo.
echo %YELLOW%==========================================================================================%RESET%
echo %YELLOW% SUCCESS: RustDesk configuration successfully restored!%RESET%
echo %YELLOW%==========================================================================================%RESET%

timeout /t 3 >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.11.03 | github.com/GinCz =
