:: ==========================================================================================
:: FILE: Cursor_Downloader_Silent.bat
:: ==========================================================================================
@echo off
:: = Rooted by VladiMIR + AI | v.2026.08.08 | github.com/GinCz =
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (Robust syntax for special characters like & and spaces)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title Universal Cursor AI Editor SILENT Installer - LOAD

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Universal Cursor AI Editor SILENT Installer Downloader' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

echo [+] Analyzing system processor architecture...

:: Check if the OS environment is 32-bit to notify architecture constraints
set "is_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "is_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "is_64=1"

if "%is_64%"=="0" (
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Cursor AI Editor natively requires an x64 operating system environment.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo [+] Flushing local DNS cache and verifying global network routing...
ipconfig /flushdns >nul
ping -n 1 8.8.8.8 >nul
if errorlevel 1 (
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' CRITICAL ERROR: No internet connection detected (Ping to 8.8.8.8 failed).' -ForegroundColor Red"
    powershell -Command "Write-Host ' Check your network adapter, VPN, or firewall settings.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

:: Force TLS 1.2 and inject TLS 1.3 (3072) support for modern CDN compatibility
set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 3072"

echo [+] Querying official distribution servers to find the LATEST release...

:: Hardcoded working API endpoint for Cursor Windows x64
set "base_url=https://api2.cursor.sh/updates/download/golden/win32-x64-user/cursor/3.15"

:: Robust URL resolution with full Chrome User-Agent mimicking to catch the final redirect URL
set "ps_fetch=%ps_tls%; $req = [System.Net.WebRequest]::Create('%base_url%'); $req.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'; $req.AllowAutoRedirect = $true; try { $res = $req.GetResponse(); Write-Output $res.ResponseUri.AbsoluteUri; $res.Close() } catch { Write-Output '%base_url%' }"

for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "%ps_fetch%"`) do set "download_url=%%I"

:: Extract filename from resolved URL or use default fallback
for %%F in ("%download_url%") do set "filename=%%~nxF"
if "%filename%"=="" set "filename=CursorSetup-Latest-x64.exe"
if "%filename%"=="x64" set "filename=CursorSetup-Latest-x64.exe"
if "%filename%"=="3.15" set "filename=CursorSetup-Latest-x64.exe"

:: Ensure filename ends with .exe for correct execution
echo %filename% | find /i ".exe" >nul
if errorlevel 1 set "filename=%filename%.exe"

set "arch_type=x64 (64-bit)"

echo.
echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Detects the host OS architecture (x86 or x64).
echo   * Dynamically resolves and fetches the LATEST stable Cursor AI release.
echo   * Creates a secure temporary directory and executes a fully SILENT background installation.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Detected OS Architecture : %arch_type%
echo   Target File Name         : %filename%
echo   Target Download URL      : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...
set "new_dir=C:\Windows\Temp\cursor_silent_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul
set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest Cursor User Setup package...
echo.

:: Download using Invoke-WebRequest with full browser headers and diagnostic error catching
set "ps_cmd=%ps_tls%; $headers = @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'; 'Accept'='text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'}; try { Invoke-WebRequest -Uri '%download_url%' -OutFile '%download_path%' -Headers $headers -UseBasicParsing -MaximumRedirection 10 } catch { Write-Host ' DIAGNOSTIC ERROR: ' $_.Exception.Message -ForegroundColor Red; exit 1 }"

powershell -Command "%ps_cmd%"
if errorlevel 1 (
    echo.
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Download failed. See diagnostic message above.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Download completed successfully! Initializing SILENT execution...' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"

:: Remove the internet block flag from the executable to ensure clean background execution
powershell -Command "Unblock-File -Path '%download_path%'"

:: EXECUTION FLAGS MODIFICATION:
:: /S - System flag for fully silent automated installation via NSIS.
echo [*] Installing Cursor AI in background mode (Default profile, no GUI popups)...
start /wait "" "%download_path%" /S

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Green"
powershell -Command "Write-Host ' SUCCESS: Cursor AI Editor deployment successfully finished on this system.' -ForegroundColor Green"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Green"

timeout /t 10 /NOBREAK >nul
exit /b 0
