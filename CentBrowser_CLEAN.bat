:: ==========================================================================================
:: FILE: CentBrowser_CLEAN.bat
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
title CentBrowser Cleanup - CLEAN

:: Cyber Parking Zone: 4 blank lines, 89-character line, 3 blank lines
for /L %%i in (1,1,4) do echo.
powershell -NoProfile -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host ' CentBrowser Cache and Log Cleanup Started' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

set "TARGET_DIR=D:\UTIL\N E T\CHROME_temp"

echo Target Directory: %TARGET_DIR%
echo.

if not exist "%TARGET_DIR%" (
    powershell -NoProfile -Command "Write-Host ' ERROR: Target directory not found: %TARGET_DIR%' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
)

echo Cleaning cache folders and temporary log files...
echo.

powershell -NoProfile -Command "$basePath = '%TARGET_DIR%'; if (Test-Path $basePath) { Get-ChildItem -Path $basePath -Directory | ForEach-Object { $p = $_.FullName; Write-Host ('Cleaning profile: {0}' -f $_.Name); @('Cache', 'Code Cache', 'DawnGraphiteCache', 'DawnWebGPUCache', 'GPUCache') | ForEach-Object { $t = Join-Path $p $_; if (Test-Path $t) { Get-ChildItem -Path $t -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue; Get-ChildItem -Path $t -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { (Get-ChildItem $_.FullName -ErrorAction SilentlyContinue) -eq $null } | Remove-Item -Force -ErrorAction SilentlyContinue } }; @('*_log', '*.tmp', 'LOG', 'LOG.old') | ForEach-Object { Get-ChildItem -Path $p -Filter $_ -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue } }; Write-Host 'Cleanup operations finished successfully.' } else { Write-Host ' ERROR: Target path not found!' -ForegroundColor Red; exit 1 }"

if %errorlevel% neq 0 (
    echo.
    powershell -NoProfile -Command "Write-Host ' ERROR: Cleanup operation failed!' -ForegroundColor Red"
    timeout /t 10 /NOBREAK >nul
    exit /b 1
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
