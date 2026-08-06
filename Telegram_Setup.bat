:: ==========================================================================================
:: FILE: Telegram_Setup.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-elevate to Administrator
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :ELEVATE
goto :ADMIN_OK

:ELEVATE
powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
exit /b

:ADMIN_OK
cd /d "%~dp0"
title Telegram Desktop Setup - INSTALL

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' Universal Telegram Desktop Dynamic Release Installer Downloader Started' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

echo Analyzing system processor architecture...

set "IS_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "IS_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "IS_64=1"

if "%IS_64%"=="1" (
    set "ARCH_TYPE=x64 (64-bit)"
    set "DOWNLOAD_URL=https://telegram.org/dl/desktop/win64"
) else (
    set "ARCH_TYPE=x86 (32-bit)"
    set "DOWNLOAD_URL=https://telegram.org/dl/desktop/win"
)

set "FILENAME=TelegramSetup.exe"

echo.
echo Detected OS Architecture : %ARCH_TYPE%
echo Target File Name        : %FILENAME%
echo Target Download URL     : %DOWNLOAD_URL%
echo.

echo Preparing temporary download environment...
set "TEMP_DIR=C:\Windows\Temp\telegram_installer_%RANDOM%_%RANDOM%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >nul 2>&1
set "DOWNLOAD_PATH=%TEMP_DIR%\%FILENAME%"

echo Downloading Telegram Desktop installer from official servers...
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
