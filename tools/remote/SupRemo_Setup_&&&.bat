:: ==========================================================================================
:: FILE: SupRemo_Downloader.bat
:: ==========================================================================================
@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (Robust syntax for special characters like & and spaces)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title SupRemo Installer Downloader - LOAD

:: Shift output down by 4 lines, output parking zone, and pad with 3 lines below
for /L %%i in (1,1,4) do echo.
powershell -Command "Write-Host ' ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   P A R K I N G   Z O N E  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: ------------------------------------------------------------------------------------------
:: MAIN SCRIPT EXECUTION
:: ------------------------------------------------------------------------------------------
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' Universal SupRemo Remote Desktop Installer Downloader' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
echo.

echo [+] Analyzing system environment...

:: Force TLS 1.2 protocol for secure download
set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

:: Official direct link to the universal executable package
set "download_url=https://www.nanosystems.it/public/download/Supremo.exe"
set "filename=Supremo.exe"

echo.
echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * Deploys the SupRemo remote desktop framework package.
echo   * Automatically fetches the LATEST stable release from official distribution servers.
echo   * Creates a secure temporary directory and executes the native installer.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Target File Name         : %filename%
echo   Target Download URL      : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...
set "new_dir=C:\Windows\Temp\supremo_dynamic_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul
set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest installer version from official remote distribution servers...
echo.

:: Safe PowerShell progress engine
set "ps_cmd=%ps_tls%; $ProgressPreference='SilentlyContinue'; $w = New-Object System.Net.WebClient; $w.DownloadFileAsync((New-Object System.Uri('%download_url%')), '%download_path%'); while (-not $w.ResponseHeaders) { Start-Sleep -Milliseconds 50 }; $t = $w.ResponseHeaders['Content-Length']; $last = -1; while ($w.IsBusy) { Start-Sleep -Milliseconds 50; if ($t) { $c = (Get-Item '%download_path%').Length; $p = [math]::Floor(($c / $t) * 100); $s = [math]::Floor(($p / 100) * 70); if ($s -gt $last) { if ($s -le 70) { $last = $s; $bar = '*' * $s + ' ' * (70 - $s); Write-Host ([char]13 + 'Progress: [' + $bar + '] ' + $p.ToString().PadLeft(3) + '%%') -NoNewline; } } } else { Write-Host ([char]13 + 'Progress: [ Streaming Direct Download Data Flow... ]') -NoNewline; } } Write-Host ([char]13 + 'Progress: [' + ('*' * 70) + '] 100%%')"

powershell -Command "%ps_cmd%"
if errorlevel 1 (
    echo.
    echo.
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    powershell -Command "Write-Host ' ERROR: Download failed. Please verify internet connection or local TLS configurations.' -ForegroundColor Red"
    powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Red"
    pause
    exit /b 1
)

echo.
echo.
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host ' SUCCESS: Download completed successfully! Launching installer execution...' -ForegroundColor Yellow"
powershell -Command "Write-Host '==========================================================================================' -ForegroundColor Yellow"

start "" "%download_path%"

timeout /t 10 /NOBREAK >nul
exit /b 0

:: = Rooted by VladiMIR + AI | v.2026.08.06 | github.com/GinCz =
