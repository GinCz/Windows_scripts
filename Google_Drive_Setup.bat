@echo off
rem = Rooted by VladiMIR + AI | v.2026.07.05 | github.com/GinCz =
setlocal enabledelayedexpansion

rem Set color: 0 = Black background, A = Light Green text
color 0A

rem Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ==========================================================================================
    echo WARNING: This script requires ADMINISTRATOR privileges to run correctly!
    echo ==========================================================================================
    echo Restarting with elevated privileges...
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

rem CRITICAL RESET: Forcefully turn off command echo output inside the elevated Administrator window
@echo off
clear || cls

echo ==========================================================================================
echo L O A D I N G   ^|   Universal Google Drive Stable Installer Downloader
echo ==========================================================================================
echo.

echo [+] Analyzing system environment...

rem Force TLS 1.2 protocol for secure download
set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

rem Google Drive installer is natively universal (handles both x86 and x64 frameworks)
set "download_url=https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
set "filename=GoogleDriveSetup.exe"

echo.
echo ==========================================================================================
echo   SCRIPT DESCRIPTION:
echo   --------------------------------------------------------------------------------------
echo   * This automation script deploys the official Google Drive client framework.
echo   * It automatically fetches the LATEST stable release from official Google servers.
echo   * It creates a secure temporary directory and executes the native installer.
echo.
echo   ENVIRONMENT INFO:
echo   --------------------------------------------------------------------------------------
echo   Target File Name        : %filename%
echo   Target Download URL     : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...

rem Generate a triple-random unique dynamic folder to eliminate any write or access conflicts
set "new_dir=C:\Windows\Temp\gdrive_dynamic_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul

set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest installer version from official Google servers...
echo.
echo ==========================================================================================

rem Safe PowerShell progress engine: Wait for connection, then draw exactly ONE dynamic bar
set "ps_cmd=%ps_tls%; $ProgressPreference='SilentlyContinue'; $w = New-Object System.Net.WebClient; $w.DownloadFileAsync((New-Object System.Uri('%download_url%')), '%download_path%'); while (-not $w.ResponseHeaders) { Start-Sleep -Milliseconds 50 }; $last = -1; while ($w.IsBusy) { Start-Sleep -Milliseconds 50; $t = $w.ResponseHeaders['Content-Length']; if ($t) { $c = (Get-Item '%download_path%').Length; $p = [math]::Floor(($c / $t) * 100); $s = [math]::Floor(($p / 100) * 70); if ($s -gt $last) { if ($s -le 70) { $last = $s; $bar = '*' * $s + ' ' * (70 - $s); Write-Host ([char]13 + 'Progress: [' + $bar + '] ' + $p.ToString().PadLeft(3) + '%%') -NoNewline; } } } } Write-Host ([char]13 + 'Progress: [' + ('*' * 70) + '] 100%%')"

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
