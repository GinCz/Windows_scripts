@echo off
rem = Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
setlocal enabledelayedexpansion

rem ---------------------------------------------------------------------------
rem SCRIPT: CentBrowser_Setup.bat
rem DESCRIPTION: Downloads and installs Cent Browser v5.2.1168.83.
rem              Auto-detects x86/x64 and fetches the correct static build
rem              from official Cent Browser distribution servers.
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
echo L O A D I N G ^| Universal Cent Browser Stable Installer Downloader
echo ==========================================================================================
echo.

echo [+] Analyzing system processor architecture...

set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

set "download_url=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64.exe"
set "filename=centbrowser_5.2.1168.83_x64.exe"
set "arch_type=x64 (64-bit)"

set "is_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "is_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "is_64=1"

if "%is_64%"=="0" (
set "download_url=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83.exe"
set "filename=centbrowser_5.2.1168.83.exe"
set "arch_type=x86 (32-bit)"
)

echo.
echo ==========================================================================================
echo SCRIPT DESCRIPTION:
echo --------------------------------------------------------------------------------------
echo * This automation script detects the host OS architecture (x86 or x64).
echo * It automatically fetches the specified stable release from official Cent servers.
echo * It creates a secure temporary directory and executes the native installer.
echo.
echo ENVIRONMENT INFO:
echo --------------------------------------------------------------------------------------
echo Detected OS Architecture : %arch_type%
echo Target File Name : %filename%
echo Target Download URL : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...

set "new_dir=C:\Windows\Temp\centbrowser_dynamic_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul

set "download_path=%new_dir%\%filename%"

echo [+] Downloading the specified installer version from official Cent Browser servers...
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