:: ==========================================================================================
:: FILE: Hiddify_LOAD.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :ELEVATE
goto :ADMIN_OK

:ELEVATE
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ADMIN_OK
cd /d "%~dp0"
title Hiddify Portable Backup - LOAD

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

set "SOURCE_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\VPN\XRAY\Hiddify_backup.zip"
set "DEST_DIR=D:\UTIL\Hiddify"

powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Hiddify Portable Restore Started' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo Source ZIP : %SOURCE_ZIP%
echo Target DIR : %DEST_DIR%
echo.

if not exist "%SOURCE_ZIP%" (
    powershell -Command "Write-Host ' ERROR: Backup file not found!' -ForegroundColor Red"
    pause
    exit /b 1
)

echo Stopping Hiddify.exe to prevent locked files...
taskkill /IM Hiddify.exe /F >nul 2>&1
timeout /T 2 /NOBREAK >nul

echo Extracting files, please wait...
powershell -NoProfile -Command "Expand-Archive -Path '%SOURCE_ZIP%' -DestinationPath '%DEST_DIR%' -Force"

if %errorlevel% neq 0 (
    echo.
    powershell -Command "Write-Host ' ERROR: Extraction failed!' -ForegroundColor Red"
    pause
    exit /b 1
)

echo Starting Hiddify.exe...
schtasks /create /tn "Hiddify_Run" /tr "\"%DEST_DIR%\Hiddify.exe\"" /sc once /sd 01/01/2026 /st 00:00 /rl highest /f >nul 2>&1
schtasks /run /tn "Hiddify_Run" >nul 2>&1
schtasks /delete /tn "Hiddify_Run" /f >nul 2>&1

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Restore completed successfully and Hiddify started!' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
