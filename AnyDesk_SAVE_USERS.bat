:: ==========================================================================================
:: FILE: AnyDesk_SAVE_USERS.bat
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
title AnyDesk Config Backup - SAVE

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' AnyDesk User Configuration Backup Started' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

set "SOURCE_FILE=%APPDATA%\AnyDesk\user.conf"
set "LOCAL_ZIP=%~dp0AnyDesk_USERS.zip"
set "ALT_LOCAL_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\AnyDesk\AnyDesk_USERS.zip"
set "NETWORK_ZIP=\\s.gincz.com\user\AnyDesk_BackUp\AnyDesk_USERS.zip"

echo Source File   : %SOURCE_FILE%
echo Local ZIP     : %LOCAL_ZIP%
echo Network Target: %NETWORK_ZIP%
echo.

if not exist "%SOURCE_FILE%" (
    powershell -NoProfile -Command "Write-Host ' ERROR: AnyDesk user configuration file (user.conf) not found!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

echo Creating local backup archive, please wait...
powershell -NoProfile -Command "Compress-Archive -Path '%SOURCE_FILE%' -DestinationPath '%LOCAL_ZIP%' -Force"

if %errorlevel% neq 0 (
    echo.
    powershell -NoProfile -Command "Write-Host ' ERROR: Failed to create local backup archive!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

:: Copy to alternative local path if accessible
for %%I in ("%ALT_LOCAL_ZIP%\..") do set "ALT_DIR=%%~fI"
if exist "%ALT_DIR%" (
    echo Syncing archive to local storage folder...
    copy /Y "%LOCAL_ZIP%" "%ALT_LOCAL_ZIP%" >nul 2>&1
)

:: Copy to network share
echo Copying archive to network share, please wait...
powershell -NoProfile -Command "Copy-Item -Path '%LOCAL_ZIP%' -Destination '%NETWORK_ZIP%' -Force" >nul 2>&1

if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Write-Host ' WARNING: Could not copy backup archive to network share.' -ForegroundColor Yellow"
) else (
    echo Network backup updated successfully.
)

:: ------------------------------------------------------------------------------------------
:: END OF SCRIPT
:: ------------------------------------------------------------------------------------------
echo.
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' Backup completed successfully!' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
