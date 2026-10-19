@echo off
:: Execution Context : Windows Command Prompt / CMD (Standard User or Administrator)
:: Target OS         : Windows 10 / Windows 11 / Windows Server / Windows 7 / Windows 8
:: Description       : Resilient Downloader & Launcher for GIN-VPN Windows Client (Bypasses Russian ISP & RKN blocks)
cls
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

title GIN-VPN Downloader & Launcher [RU Bypass Edition]
color 0b

echo ===============================================================================
echo                GIN-VPN Windows Client Downloader & Launcher                   
echo                   Optimized for Russian Network Resilience                    
echo ===============================================================================
echo.

:: -----------------------------------------------------------------------------
:: Step 1: Set Target File Location
:: -----------------------------------------------------------------------------
set "TARGET_DIR=%~dp0"
set "TARGET_EXE=%TARGET_DIR%GIN-VPN.exe"

:: Test write permissions in target folder
set "TEST_FILE=%TARGET_DIR%.write_test_%RANDOM%.tmp"
echo test > "%TEST_FILE%" 2>nul
if exist "%TEST_FILE%" (
    del /f /q "%TEST_FILE%" >nul 2>&1
) else (
    if exist "%USERPROFILE%\Desktop" (
        set "TARGET_DIR=%USERPROFILE%\Desktop\"
        set "TARGET_EXE=%USERPROFILE%\Desktop\GIN-VPN.exe"
    ) else (
        set "TARGET_DIR=%TEMP%\"
        set "TARGET_EXE=%TEMP%\GIN-VPN.exe"
    )
)

echo [*] Target destination: "%TARGET_EXE%"
echo.

:: -----------------------------------------------------------------------------
:: Step 2: Stop any running instance before download to avoid Windows file locks
:: -----------------------------------------------------------------------------
tasklist /FI "IMAGENAME eq GIN-VPN.exe" 2>nul | find /i "GIN-VPN.exe" >nul
if !errorlevel! equ 0 (
    echo [*] Detected running GIN-VPN instance. Closing for update...
    taskkill /F /T /IM GIN-VPN.exe >nul 2>&1
    taskkill /F /T /IM xray.exe >nul 2>&1
    timeout /t 1 >nul 2>&1
)

:: If target file exists and is locked, fallback to alternative filename
if exist "%TARGET_EXE%" (
    del /f /q "%TARGET_EXE%" >nul 2>&1
    if exist "%TARGET_EXE%" (
        echo [!] Existing GIN-VPN.exe is in use. Using GIN-VPN_New.exe...
        set "TARGET_EXE=%TARGET_DIR%GIN-VPN_New.exe"
    )
)

:: -----------------------------------------------------------------------------
:: Step 3: Define Download Mirrors
:: -----------------------------------------------------------------------------
set "URL_RU_HTTPS=https://4at.gincz.com/download/GIN-VPN.exe"
set "URL_RU_HTTP=http://31.59.126.191/download/GIN-VPN.exe"
set "URL_GITHUB=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"

set "MIN_SIZE=10000000"
set "DOWNLOAD_SUCCESS=0"

:: Mirror 1: Russian Node HTTPS
echo [*] Mirror 1: Connecting to Russian Node via HTTPS (4at.gincz.com)...
call :DownloadFile "%URL_RU_HTTPS%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!DOWNLOAD_SUCCESS!"=="1" goto LaunchApp

:: Mirror 2: Russian Node Direct IP
echo.
echo [!] Mirror 1 failed or filtered. Switching to Direct IP...
echo [*] Mirror 2: Connecting to Russian Node via Direct IP (31.59.126.191)...
call :DownloadFile "%URL_RU_HTTP%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!DOWNLOAD_SUCCESS!"=="1" goto LaunchApp

:: Mirror 3: GitHub Raw Fallback
echo.
echo [!] Russian node direct access failed. Trying Global GitHub fallback...
echo [*] Mirror 3: Connecting to GitHub Repository...
call :DownloadFile "%URL_GITHUB%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!DOWNLOAD_SUCCESS!"=="1" goto LaunchApp

:: All mirrors failed
color 0c
echo.
echo ===============================================================================
echo  [ERROR] Failed to download GIN-VPN from all available mirrors.
echo  Please check your internet connection or firewall settings.
echo ===============================================================================
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:: -----------------------------------------------------------------------------
:: Subroutine: DownloadFile
:: -----------------------------------------------------------------------------
:DownloadFile
set "SRC_URL=%~1"
set "DST_FILE=%~2"
if exist "%DST_FILE%" del /f /q "%DST_FILE%" >nul 2>&1

:: Attempt A: Built-in Windows curl.exe with progress bar
where curl.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo     [-] Downloading via curl.exe (please wait)...
    curl.exe -f -L -k --connect-timeout 15 --max-time 180 --retry 2 -# -o "%DST_FILE%" "%SRC_URL%"
    if exist "%DST_FILE%" exit /b 0
)

:: Attempt B: PowerShell WebClient
where powershell.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo     [-] Downloading via PowerShell WebClient (please wait)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent','Mozilla/5.0'); $wc.DownloadFile('%SRC_URL%','%DST_FILE%')" >nul 2>&1
    if exist "%DST_FILE%" exit /b 0
)

:: Attempt C: Certutil URL Cache
where certutil.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo     [-] Downloading via certutil.exe (please wait)...
    certutil.exe -urlcache -split -f "%SRC_URL%" "%DST_FILE%" >nul 2>&1
    if exist "%DST_FILE%" exit /b 0
)
exit /b 0

:: -----------------------------------------------------------------------------
:: Subroutine: VerifyDownload
:: -----------------------------------------------------------------------------
:VerifyDownload
set "CHECK_FILE=%~1"
if not exist "%CHECK_FILE%" (
    set "DOWNLOAD_SUCCESS=0"
    exit /b 0
)
for %%F in ("%CHECK_FILE%") do set "FILE_SIZE=%%~zF"
if !FILE_SIZE! GEQ %MIN_SIZE% (
    echo     [+] Download verified successfully (!FILE_SIZE! bytes).
    set "DOWNLOAD_SUCCESS=1"
) else (
    echo     [-] File is incomplete (!FILE_SIZE! bytes). Removing...
    del /f /q "%CHECK_FILE%" >nul 2>&1
    set "DOWNLOAD_SUCCESS=0"
)
exit /b 0

:: -----------------------------------------------------------------------------
:: Step 4: Launch Application
:: -----------------------------------------------------------------------------
:LaunchApp
color 0a
echo.
echo ===============================================================================
echo  [+] GIN-VPN has been downloaded successfully!
echo ===============================================================================
echo.

:: Unblock file from Windows SmartScreen protection
echo [*] Unblocking Windows SmartScreen protection...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -LiteralPath '%TARGET_EXE%' -ErrorAction SilentlyContinue" >nul 2>&1

:: Update Program Files if installed
if exist "%ProgramFiles%\GIN-VPN" (
    echo [*] Updating installed executable in %ProgramFiles%\GIN-VPN...
    copy /y "%TARGET_EXE%" "%ProgramFiles%\GIN-VPN\GIN-VPN.exe" >nul 2>&1
)

:: Launch GIN-VPN
echo [*] Launching GIN-VPN Client...
cd /d "%TARGET_DIR%"
start "" "%TARGET_EXE%"

:: Check process status
timeout /t 2 >nul 2>&1
tasklist /FI "IMAGENAME eq GIN-VPN.exe" 2>nul | find /i "GIN-VPN.exe" >nul
if !errorlevel! equ 0 (
    echo [+] Process status: GIN-VPN.exe is ACTIVE and running in memory!
) else (
    echo [!] Process status: Process started detached.
)

echo.
echo ===============================================================================
echo  [+] SUCCESS: GIN-VPN is downloaded and running!
echo.
echo  📁 Saved Location: %TARGET_EXE%
echo.
echo  -----------------------------------------------------------------------------
echo  IMPORTANT NOTICE (SYSTEM TRAY):
echo  1. If the main window did NOT open in the center of your screen:
echo     GIN-VPN has auto-connected and started MINIMIZED into the SYSTEM TRAY!
echo  2. Look at the bottom-right corner of your screen (near the Windows clock).
echo  3. Find the green shield icon of GIN-VPN.
echo     (If hidden, click the '^' arrow icon to show collapsed tray icons).
echo  4. Left-click or double-click the green GIN-VPN icon to open the main window!
echo ===============================================================================
echo.
echo Press any key to exit this installer...
pause >nul
exit /b 0
