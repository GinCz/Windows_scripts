:: ==========================================================================================
:: FILE: AnyDesk_LOAD_USERS.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-elevate to Administrator
fltmc >nul 2>&1
if %errorlevel% neq 0 goto :ELEVATE
goto :ADMIN_OK

:ELEVATE
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ADMIN_OK
cd /d "%~dp0"
title AnyDesk Config Restore - LOAD

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' AnyDesk User Configuration Restore Started' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

set "SOURCE_ZIP=%~dp0AnyDesk_USERS.zip"
if not exist "%SOURCE_ZIP%" set "SOURCE_ZIP=D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\TeamViewer_RadMin\AnyDesk\AnyDesk_USERS.zip"

set "DEST_DIR=%APPDATA%\AnyDesk"
set "ANYDESK_EXE=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"
if not exist "%ANYDESK_EXE%" set "ANYDESK_EXE=%ProgramFiles%\AnyDesk\AnyDesk.exe"

echo Source ZIP : %SOURCE_ZIP%
echo Target DIR : %DEST_DIR%
echo.

if not exist "%SOURCE_ZIP%" (
    powershell -NoProfile -Command "Write-Host ' ERROR: Source archive AnyDesk_USERS.zip not found!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

echo Stopping AnyDesk.exe to prevent locked files...
taskkill /IM AnyDesk.exe /F >nul 2>&1
timeout /t 2 /NOBREAK >nul

if not exist "%DEST_DIR%" (
    echo Creating target directory...
    mkdir "%DEST_DIR%" >nul 2>&1
)

echo Extracting user configuration archive, please wait...
powershell -NoProfile -Command "Expand-Archive -Path '%SOURCE_ZIP%' -DestinationPath '%DEST_DIR%' -Force"

if %errorlevel% neq 0 (
    echo.
    powershell -NoProfile -Command "Write-Host ' ERROR: Failed to extract AnyDesk user configuration archive!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

echo.
echo Starting AnyDesk...
if exist "%ANYDESK_EXE%" (
    start "" "%ANYDESK_EXE%"
) else (
    echo AnyDesk executable not found at default locations. Please launch AnyDesk manually.
)

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
