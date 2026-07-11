@echo off
rem = Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
setlocal enabledelayedexpansion

rem ---------------------------------------------------------------------------
rem SCRIPT: Cursor_Install.bat
rem DESCRIPTION: Downloads and installs the latest Cursor AI Editor (x64 only).
rem              Detects architecture, downloads from official servers,
rem              unblocks the file and launches the interactive setup wizard.
rem REQUIRES: Administrator privileges, Internet connection, x64 OS
rem ---------------------------------------------------------------------------

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
cls

echo ==========================================================================================
echo L O A D I N G ^| Universal Cursor AI Editor Installer Downloader (Interactive Mode)
echo ==========================================================================================
echo.

echo [+] Analyzing system processor architecture...

rem Force TLS 1.2 protocol for secure download
set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"

rem Official Cursor windows standalone x64 distribution link
set "download_url=https://downloader.cursor.sh/windows/nsis/x64"
set "filename=CursorUserSetup-x64.exe"
set "arch_type=x64 (64-bit)"

rem Check if the OS environment is 32-bit to notify architecture constraints
set "is_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "is_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "is_64=1"

if "%is_64%"=="0" (
echo ==========================================================================================
echo ERROR: Cursor AI Editor natively requires an x64 operating system environment.
echo ==========================================================================================
pause
exit /b 1
)

echo.
echo ==========================================================================================
echo SCRIPT DESCRIPTION:
echo --------------------------------------------------------------------------------------
echo * This automation script detects the host OS architecture (x86 or x64).
echo * It automatically fetches the LATEST stable Cursor AI release from official servers.
echo * It executes the GUI installer interactively so you can customize your preferences.
echo.
echo ENVIRONMENT INFO:
echo --------------------------------------------------------------------------------------
echo Detected OS Architecture : %arch_type%
echo Target File Name : %filename%
echo Target Download URL : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...

rem Generate a triple-random unique dynamic folder to eliminate any write or access conflicts
set "new_dir=C:\Windows\Temp\cursor_interactive_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul

set "download_path=%new_dir%\%filename%"

echo [+] Downloading the latest Cursor User Setup package from official distribution servers...
echo.
echo ==========================================================================================

rem Safe PowerShell progress engine: Wait for connection, then draw exactly ONE dynamic bar
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
echo SUCCESS: Download completed successfully! Launching interactive setup wizard...
echo ==========================================================================================
echo.
echo [*] Opening Cursor AI installation window...

rem Remove the internet block flag from the executable to ensure clean background execution
powershell -Command "Unblock-File -Path '%download_path%'"

rem EXECUTION: Removed /S flag to open full graphical interface for manual configuration
cmd.exe /c ""%download_path%""

echo.
echo ==========================================================================================
echo SUCCESS: Script processing completed.
echo ==========================================================================================
echo.

endlocal
pause