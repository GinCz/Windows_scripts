:: ==========================================================================================
:: FILE: Hiddify_SAVE.bat
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
title Hiddify Portable Backup - SAVE

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

set "SOURCE_DIR=D:\UTIL\Hiddify"
set "DEST_DIR=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\VPN\XRAY"
set "DEST_ZIP=%DEST_DIR%\Hiddify_backup.zip"

powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Hiddify Portable Backup Started' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo Source : %SOURCE_DIR%
echo Target : %DEST_ZIP%
echo.

:: 1. Close application before backup
echo Stopping Hiddify.exe...
taskkill /IM Hiddify.exe /F >nul 2>&1
timeout /T 2 /NOBREAK >nul

:: Create backup date text file in the program folder before archiving
set "CUR_DATE=%date:~0,2%-%date:~3,2%-%date:~6,4% %time:~0,5%"
echo Backup Date: %CUR_DATE% > "%SOURCE_DIR%\backup_date.txt"

:: Check destination folder existence
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

:: 2. Archiving
echo Archiving files, please wait...
powershell -NoProfile -Command "Get-ChildItem -Path '%SOURCE_DIR%' | Compress-Archive -DestinationPath '%DEST_ZIP%' -CompressionLevel Fastest -Force"

if %errorlevel% neq 0 (
    echo.
    powershell -Command "Write-Host ' ERROR: Archive creation failed!' -ForegroundColor Red"
    pause
    exit /b 1
)

:: Remove temporary label file from working directory
if exist "%SOURCE_DIR%\backup_date.txt" del /f /q "%SOURCE_DIR%\backup_date.txt"

:: 3. Launch application via scheduled task (Isolated elevated execution)
echo Starting Hiddify.exe back up...
schtasks /create /tn "Hiddify_Run" /tr "\"%SOURCE_DIR%\Hiddify.exe\"" /sc once /sd 01/01/2026 /st 00:00 /rl highest /f >nul 2>&1
schtasks /run /tn "Hiddify_Run" >nul 2>&1
schtasks /delete /tn "Hiddify_Run" /f >nul 2>&1

echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Backup completed successfully and Hiddify restarted!' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
