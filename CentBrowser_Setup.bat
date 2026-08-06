:: ==========================================================================================
:: FILE: CentBrowser_Setup.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-elevate to Administrator (Robust syntax for special characters like & and spaces)
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :ELEVATE
goto :ADMIN_OK

:ELEVATE
powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
exit /b

:ADMIN_OK
cd /d "%~dp0"
title CentBrowser Setup - INSTALL

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' Universal CentBrowser Dynamic Latest Release Installer Downloader Started' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

echo Analyzing system processor architecture...

set "IS_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "IS_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "IS_64=1"

echo Querying official CentBrowser servers for the latest stable release...

set "DOWNLOAD_URL="
if "%IS_64%"=="1" (
    set "ARCH_TYPE=x64 (64-bit)"
    for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "((Invoke-WebRequest -Uri 'https://www.centbrowser.com/history.html' -UseBasicParsing).Links | Where-Object href -like '*win_stable*x64.exe')[0].href"` ) do set "DOWNLOAD_URL=%%A"
) else (
    set "ARCH_TYPE=x86 (32-bit)"
    for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "((Invoke-WebRequest -Uri 'https://www.centbrowser.com/history.html' -UseBasicParsing).Links | Where-Object href -like '*win_stable*.exe' | Where-Object href -notlike '*x64*' | Where-Object href -notlike '*portable*')[0].href"` ) do set "DOWNLOAD_URL=%%A"
)

:: Fallback if dynamic resolution fails
if "%DOWNLOAD_URL%"=="" (
    powershell -NoProfile -Command "Write-Host ' WARNING: Dynamic release search failed. Using fallback static release URL...' -ForegroundColor Yellow"
    if "%IS_64%"=="1" (
        set "DOWNLOAD_URL=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64.exe"
    ) else (
        set "DOWNLOAD_URL=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83.exe"
    )
)

:: Extract filename from URL
for %%F in ("%DOWNLOAD_URL%") do set "FILENAME=%%~nxF"

echo.
echo Detected OS Architecture : %ARCH_TYPE%
echo Latest Target File Name  : %FILENAME%
echo Target Download URL      : %DOWNLOAD_URL%
echo.

echo Preparing temporary download environment...
set "TEMP_DIR=C:\Windows\Temp\centbrowser_installer_%RANDOM%_%RANDOM%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >nul 2>&1
set "DOWNLOAD_PATH=%TEMP_DIR%\%FILENAME%"

echo Downloading CentBrowser installer from official servers...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'Continue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%DOWNLOAD_PATH%'"

if %errorlevel% neq 0 (
    echo.
    powershell -NoProfile -Command "Write-Host ' ERROR: Download failed! Please check your internet connection or TLS settings.' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

if not exist "%DOWNLOAD_PATH%" (
    echo.
    powershell -NoProfile -Command "Write-Host ' ERROR: Downloaded installer file not found!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

echo.
echo Download completed successfully! Launching installer...
start "" "%DOWNLOAD_PATH%"

:: ------------------------------------------------------------------------------------------
:: END OF SCRIPT
:: ------------------------------------------------------------------------------------------
echo.
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' Execution completed successfully!' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
