@echo off
:: Execution Context : Windows Command Prompt / CMD (Standard User or Administrator)
:: Target OS         : Windows 10 / Windows 11 / Windows Server / Windows 7 / Windows 8
:: Description       : Resilient Downloader & Launcher for GIN-VPN Windows Client (Bypasses Russian Censorship & ISP blocks)
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

set "TARGET_DIR=%TEMP%\GIN-VPN"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >nul 2>&1
set "TARGET_EXE=%TARGET_DIR%\GIN-VPN.exe"

set "URL_RU_HTTPS=https://4at.gincz.com/download/GIN-VPN.exe"
set "URL_RU_HTTP=http://31.59.126.191/download/GIN-VPN.exe"
set "URL_GITHUB=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"

set "MIN_SIZE=10000000"
set "SUCCESS=0"

:: -----------------------------------------------------------------------------
:: Step 1: Download from Primary Russian Mirror (CloudCore_191 HTTPS)
:: -----------------------------------------------------------------------------
echo [*] Mirror 1: Connecting to Russian Node via HTTPS (4at.gincz.com)...
call :DownloadFile "%URL_RU_HTTPS%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!SUCCESS!"=="1" goto LaunchApp

:: -----------------------------------------------------------------------------
:: Step 2: Download from Secondary Russian Mirror (Direct IP HTTP - DNS bypass)
:: -----------------------------------------------------------------------------
echo [!] HTTPS connection failed or filtered. Switching to Direct IP...
echo [*] Mirror 2: Connecting to Russian Node via Direct IP (31.59.126.191)...
call :DownloadFile "%URL_RU_HTTP%" "%TARGET_EXE%"
call :VerifyDownload "%TARGET_EXE%"
if "!SUCCESS!"=="1" goto LaunchApp

:: -----------------------------------------------------------------------------
:: Step 3: Download from Global Fallback Mirror (GitHub Raw)
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

:: Attempt A: Built-in Windows curl.exe
where curl.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via curl.exe...
    curl.exe -f -L -k --connect-timeout 10 --max-time 120 --retry 1 -o "%DL_DEST%" "%DL_URL%"
    if exist "%DL_DEST%" exit /b 0
)

:: Attempt B: PowerShell WebClient
where powershell.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via PowerShell...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent','Mozilla/5.0'); $wc.DownloadFile('%DL_URL%','%DL_DEST%')" >nul 2>&1
    if exist "%DL_DEST%" exit /b 0
)

:: Attempt C: Certutil URL Cache
where certutil.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo     [-] Downloading via certutil.exe...
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
echo  [*] Launching GIN-VPN Client...
echo ===============================================================================
echo.

:: Terminate any lingering background instance before launching
taskkill /F /IM GIN-VPN.exe >nul 2>&1

:: Start GIN-VPN detached
start "" "%TARGET_EXE%"

echo [*] GIN-VPN is starting. This window will close in 3 seconds...
timeout /t 3 >nul 2>&1
exit /b 0
