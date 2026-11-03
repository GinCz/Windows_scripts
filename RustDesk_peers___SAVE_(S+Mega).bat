:: ==========================================================================================
:: FILE    : RustDesk_peers___SAVE_(S+Mega).bat
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
title RustDesk Config Backup - SAVE (v2026.11.03)

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
echo %YELLOW% RustDesk Configuration Backup (Local + Network) — v2026.11.03%RESET%
echo %YELLOW%==========================================================================================%RESET%
echo.

:: Ensure Windows Workstation service (LanmanWorkstation) is running for SMB network access
sc query LanmanWorkstation | findstr /i "RUNNING" >nul
if errorlevel 1 (
    echo %CYAN%[+] Starting Windows Workstation service (LanmanWorkstation)...%RESET%
    net start LanmanWorkstation >nul 2>&1
    timeout /t 1 /nobreak >nul
)

set "SOURCE_DIR=%USERPROFILE%\AppData\Roaming\RustDesk\config\"
set "LOCAL_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\RustDesk\RustDesk_config.zip"
set "NETWORK_DIR=\\s.gincz.com\user\RustDesk_BackUp"
set "NETWORK_ZIP=%NETWORK_DIR%\RustDesk_config.zip"

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

if not exist "%SOURCE_DIR%" (
    echo.
    echo %RED%==========================================================================================%RESET%
    echo %RED% ERROR: Source directory not found: %SOURCE_DIR%%RESET%
    echo %RED%==========================================================================================%RESET%
    pause
    exit /b 1
)

echo [+] Creating local archive backup...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Get-ChildItem -Path '%SOURCE_DIR%' -Exclude 'RustDesk.toml' | Compress-Archive -DestinationPath '%LOCAL_ZIP%' -Force"

if errorlevel 1 (
    echo.
    echo %RED%==========================================================================================%RESET%
    echo %RED% ERROR: Local archive creation failed.%RESET%
    echo %RED%==========================================================================================%RESET%
    pause
    exit /b 1
)
echo %GREEN%[✓] Local archive created successfully.%RESET%

echo [+] Checking network connection to s.gincz.com...
ping -n 1 -w 1500 s.gincz.com >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[!] Host s.gincz.com ping check failed, attempting SMB direct connect...%RESET%
)

:: Ensure network destination directory exists
if not exist "%NETWORK_DIR%" (
    net use "\\s.gincz.com\user" >nul 2>&1
    mkdir "%NETWORK_DIR%" >nul 2>&1
)

echo [+] Copying archive to network storage share...
copy /y "%LOCAL_ZIP%" "%NETWORK_ZIP%" >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Copy-Item -Path '%LOCAL_ZIP%' -Destination '%NETWORK_ZIP%' -Force"
)

if errorlevel 1 (
    echo.
    echo %RED%==========================================================================================%RESET%
    echo %RED% ERROR: Copy to network share failed.%RESET%
    echo %RED% Check network connectivity, credentials, and Samba share availability.%RESET%
    echo %RED%==========================================================================================%RESET%
    pause
    exit /b 1
)
echo %GREEN%[✓] Network backup synchronized successfully.%RESET%

echo.
echo %YELLOW%==========================================================================================%RESET%
echo %YELLOW% SUCCESS: Backup completed successfully to both local and network locations!%RESET%
echo %YELLOW%==========================================================================================%RESET%

timeout /t 3 >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.11.03 | github.com/GinCz =
