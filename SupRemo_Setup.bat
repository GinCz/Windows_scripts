@echo off
rem = Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
setlocal enabledelayedexpansion

rem ---------------------------------------------------------------------------
rem SCRIPT: SupRemo_Setup.bat
rem DESCRIPTION: Downloads and installs the latest SupRemo remote desktop client.
rem              Universal executable (no architecture selection needed).
rem              Fetches directly from official Nanosystems distribution servers.
rem REQUIRES: Administrator privileges, Internet connection
rem ---------------------------------------------------------------------------

color 0A

net session >nul 2>&1
if %errorlevel% neq 0 (
echo ==========================================================================================
echo WARNING: This script requires ADMINISTRATOR privileges to run correctly!
echo ==========================================================================================
echo Restarting with elevated privileges...
powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
exit /b
)

@echo off
cls

echo ==========================================================================================
echo L O A D I N G ^| Universal SupRemo Remote Desktop Installer Downloader
echo ==========================================================================================
echo.

echo [+] Analyzing system environment...

set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

rem Official direct link to the universal executable package
set "download_url=https://www.nanosystems.it/public/download/Supremo.exe"
set "filename=Supremo.exe"

echo.
echo ==========================================================================================
echo SCRIPT DESCRIPTION:
echo --------------------------------------------------------------------------------------
echo * This automation script deploys the SupRemo remote desktop framework package.
echo * It automatically fetches the LATEST stable release from official distribution servers.
echo * It creates a secure temporary directory and executes the native installer.
echo.
echo ENVIRONMENT INFO:
echo --------------------------------------------------------------------------------------
echo Target File Name : %filename%
echo Target Download URL : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...

set "new_dir=C:\Windows\Temp\supremo_dynamic_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul

set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest installer version from official remote distribution servers...
echo.
echo ==========================================================================================

set "ps_cmd=%ps_tls%; $ProgressPreference='SilentlyContinue'; $w = New-Object System.Net.WebClient; $w.DownloadFileAsync((New-Object System.Uri('%download_url%')), '%download_path%'); while (-not $w.ResponseHeaders) { Start-Sleep -Milliseconds 50 }; $t = $w.ResponseHeaders['Content-Length']; $last = -1; while ($w.IsBusy) { Start-Sleep -Milliseconds 50; if ($t) { $c = (Get-Item '%download_path%').Length; $p = [math]::Floor(($c / $t) * 100); $s = [math]::Floor(($p / 100) * 70); if ($s -gt $last) { if ($s -le 70) { $last = $s; $bar = '*' * $s + ' ' * (70 - $s); Write-Host ([char]13 + 'Progress: [' + $bar + '] ' + $p.ToString().PadLeft(3) + '%%') -NoNewline; } } } else { Write-Host ([char]13 + 'Progress: [ Streaming Direct Download Data Flow... ]') -NoNewline; } } Write-Host ([char]13 + 'Progress: [' + ('*' * 70) + '] 100%%')"

powershell -Command "%ps_cmd%"
if errorlevel 1 (
echo.
echo ==========================================================================================
echo ERROR: Download failed. Please verify internet connection or local TLS configurations.
echo ==========================================================================================
pause
exit /b 1
)

echo.
echo ==========================================================================================
echo SUCCESS: Download completed successfully! Launching installer execution...
echo ==========================================================================================
echo.

start "" "%download_path%"

endlocal
pause