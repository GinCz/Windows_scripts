@echo off
:: Execution Context : Windows Command Prompt / CMD (Standard User or Administrator)
:: Target OS         : Windows 10 / Windows 11 / Windows Server / Windows 7 / Windows 8
:: Description       : Resilient Downloader & Launcher for GIN-VPN Windows Client (Bypasses Russian ISP & RKN blocks)
cls
chcp 65001 >nul
setlocal EnableDelayedExpansion

title GIN-VPN Downloader & Launcher [RU Bypass Edition]
color 0b

echo ===============================================================================
echo                GIN-VPN Windows Client Downloader & Launcher                   
echo                   Optimized for Russian Network Resilience                    
echo ===============================================================================
echo.

:: -----------------------------------------------------------------------------
:: Step 0: Elevation Check (Optional Request for Administrator Privileges)
:: -----------------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    if "%~1"=="--no-elevate" goto SkipElevation
    echo [*] Checking permissions...
    echo [*] Requesting Administrator privileges for clean process management...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"%~f0\"\" --elevated' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        exit /b 0
    )
    echo [!] Administrator privilege prompt skipped or declined. Continuing in standard mode...
    echo.
)
:SkipElevation

:: -----------------------------------------------------------------------------
:: Step 1: Determine Target Destination Directory and Executable Path
:: -----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
set "TEST_FILE=%SCRIPT_DIR%.write_test_%RANDOM%.tmp"
echo test > "%TEST_FILE%" 2>nul
if exist "%TEST_FILE%" (
    del /f /q "%TEST_FILE%" >nul 2>&1
    set "TARGET_EXE=%SCRIPT_DIR%GIN-VPN.exe"
) else (
    if exist "%USERPROFILE%\Desktop" (
        set "TARGET_EXE=%USERPROFILE%\Desktop\GIN-VPN.exe"
    ) else (
        set "TARGET_EXE=%TEMP%\GIN-VPN.exe"
    )
)

echo [*] Target executable path: "%TARGET_EXE%"
echo.

set "URL_RU_HTTPS=https://4at.gincz.com/download/GIN-VPN.exe"
set "URL_RU_HTTP=http://31.59.126.191/download/GIN-VPN.exe"
set "URL_GITHUB=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"

set "MIN_SIZE=10000000"
set "SUCCESS=0"

:: -----------------------------------------------------------------------------
:: Step 2: Download from Primary Russian Mirror (CloudCore_191 HTTPS)
:: -----------------------------------------------------------------------------
echo [*] Mirror 1: Connecting to Russian Node via HTTPS (4at.gincz.com)...
call :DownloadFile "%URL_RU_HTTPS%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!SUCCESS!"=="1" goto LaunchApp

:: -----------------------------------------------------------------------------
:: Step 3: Download from Secondary Russian Mirror (Direct IP HTTP - DNS bypass)
:: -----------------------------------------------------------------------------
echo [!] HTTPS mirror unavailable or filtered. Switching to Direct IP...
echo [*] Mirror 2: Connecting to Russian Node via Direct IP (31.59.126.191)...
call :DownloadFile "%URL_RU_HTTP%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!SUCCESS!"=="1" goto LaunchApp

:: -----------------------------------------------------------------------------
:: Step 4: Download from Global Fallback Mirror (GitHub Raw)
:: -----------------------------------------------------------------------------
echo [!] Russian node direct access failed. Trying Global GitHub fallback...
echo [*] Mirror 3: Connecting to GitHub Repository...
call :DownloadFile "%URL_GITHUB%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!SUCCESS!"=="1" goto LaunchApp

:: -----------------------------------------------------------------------------
:: Error Handler: All mirrors failed
:: -----------------------------------------------------------------------------
color 0c
echo.
echo ===============================================================================
echo  [ERROR] Failed to download GIN-VPN from all available mirrors.
echo  Please check your internet connection or firewall settings.
echo ===============================================================================
echo.
pause
exit /b 1

:: -----------------------------------------------------------------------------
:: Download Function: Tries curl.exe -> PowerShell -> certutil.exe
:: -----------------------------------------------------------------------------
:DownloadFile
set "DL_URL=%~1"
set "DL_DEST=%~2"
if exist "%DL_DEST%" del /f /q "%DL_DEST%" >nul 2>&1

:: Attempt A: Built-in Windows curl.exe with progress bar
where curl.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via curl.exe (please wait)...
    curl.exe -f -L -k --connect-timeout 15 --max-time 180 --retry 2 --progress-bar -o "%DL_DEST%" "%DL_URL%"
    if exist "%DL_DEST%" exit /b 0
)

:: Attempt B: PowerShell WebClient
where powershell.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via PowerShell WebClient (please wait)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent','Mozilla/5.0'); $wc.DownloadFile('%DL_URL%','%DL_DEST%')"
    if exist "%DL_DEST%" exit /b 0
)

:: Attempt C: Certutil URL Cache
where certutil.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via certutil.exe (please wait)...
    certutil.exe -urlcache -split -f "%DL_URL%" "%DL_DEST%" >nul 2>&1
    if exist "%DL_DEST%" exit /b 0
)
exit /b 0

:: -----------------------------------------------------------------------------
:: Verification Function: Checks file existence and minimum size (~10MB+)
:: -----------------------------------------------------------------------------
:VerifyDownload
set "V_FILE=%~1"
if not exist "%V_FILE%" (
    set "SUCCESS=0"
    exit /b 0
)
for %%F in ("%V_FILE%") do set "F_SIZE=%%~zF"
if %F_SIZE% GEQ %MIN_SIZE% (
    echo     [+] Download validated successfully (%F_SIZE% bytes).
    set "SUCCESS=1"
) else (
    echo     [-] Incomplete or corrupted file (%F_SIZE% bytes). Removing...
    del /f /q "%V_FILE%" >nul 2>&1
    set "SUCCESS=0"
)
exit /b 0

:: -----------------------------------------------------------------------------
:: Launch Application
:: -----------------------------------------------------------------------------
:LaunchApp
color 0a
echo.
echo ===============================================================================
echo  [+] GIN-VPN has been downloaded successfully!
echo ===============================================================================
echo.

:: 1. Unblock downloaded executable from Windows SmartScreen
echo [*] Removing Windows SmartScreen zone identifier...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -LiteralPath '%TARGET_EXE%' -ErrorAction SilentlyContinue" >nul 2>&1

:: 2. Terminate any hanging or previous instances to prevent mutex conflict
echo [*] Closing previous GIN-VPN and Xray instances...
taskkill /F /T /IM GIN-VPN.exe >nul 2>&1
taskkill /F /T /IM xray.exe >nul 2>&1
timeout /t 1 >nul 2>&1

:: 3. Update Program Files directory if installed
if exist "%ProgramFiles%\GIN-VPN" (
    echo [*] Updating installed executable in %ProgramFiles%\GIN-VPN...
    copy /y "%TARGET_EXE%" "%ProgramFiles%\GIN-VPN\GIN-VPN.exe" >nul 2>&1
)

:: 4. Launch GIN-VPN
echo [*] Launching GIN-VPN Client...
pushd "%~dp0"
start "" "%TARGET_EXE%"
popd

:: 5. Process verification check
timeout /t 2 >nul 2>&1
tasklist /FI "IMAGENAME eq GIN-VPN.exe" 2>nul | find /i "GIN-VPN.exe" >nul
if %errorlevel% equ 0 (
    echo [+] Status: GIN-VPN.exe process is ACTIVE in memory!
) else (
    echo [!] Status: Process launched detached.
)

echo.
echo ===============================================================================
echo  [+] SUCCESS: GIN-VPN is downloaded and running!
echo.
echo  📁 File Location: %TARGET_EXE%
echo.
echo  -----------------------------------------------------------------------------
echo  IMPORTANT: WHY YOU MIGHT NOT SEE A WINDOW IN THE CENTER OF YOUR SCREEN:
echo  1. GIN-VPN auto-connects and starts MINIMIZED directly into the SYSTEM TRAY!
echo  2. Look at the bottom-right corner of your screen (near the Windows clock).
echo  3. Find the green shield icon of GIN-VPN.
echo     (If hidden, click the '^' arrow icon to show collapsed tray icons).
echo  4. Left-click or double-click the GIN-VPN icon to open the main window!
echo ===============================================================================
echo.
echo Press any key to exit this installer...
pause >nul
exit /b 0
