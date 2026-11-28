@echo off
rem = Rooted by VladiMIR + AI | v.2026.07.05 | github.com/GinCz =
setlocal enabledelayedexpansion
color 0A

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)
@echo off
cls

echo ==========================================================================================
echo   MEGA Cloud Installer   ^|   Run as Administrator   ^|   CMD Script
echo ==========================================================================================
echo.
echo [+] Analyzing system processor architecture...

set "ps_tls=[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
set "download_url=https://mega.nz/MEGAsyncSetup64.exe"
set "filename=MEGAsyncSetup64.exe"
set "arch_type=x64 (64-bit)"

set "is_64=0"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "is_64=1"
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "is_64=1"

if "%is_64%"=="0" (
    set "download_url=https://mega.nz/MEGAsyncSetup32.exe"
    set "filename=MEGAsyncSetup32.exe"
    set "arch_type=x86 (32-bit)"
)

echo   Detected OS Architecture : %arch_type%
echo   Target File Name         : %filename%
echo   Target Download URL      : %download_url%
echo ==========================================================================================
echo.

echo [+] Preparing unique temporary environment...
set "new_dir=C:\Windows\Temp\mega_dynamic_session_%RANDOM%_%RANDOM%_%RANDOM%"
mkdir "%new_dir%" 2>nul
set "download_path=%new_dir%\%filename%"

echo [+] Downloading from official MEGA servers...
echo.
echo ==========================================================================================

set "ps_cmd=%ps_tls%; $ProgressPreference='SilentlyContinue'; $w = New-Object System.Net.WebClient; $w.DownloadFileAsync((New-Object System.Uri('%download_url%')), '%download_path%'); while (-not $w.ResponseHeaders) { Start-Sleep -Milliseconds 50 }; $t = $w.ResponseHeaders['Content-Length']; $last = -1; while ($w.IsBusy) { Start-Sleep -Milliseconds 50; if ($t) { $c = (Get-Item '%download_path%').Length; $p = [math]::Floor(($c / $t) * 100); $s = [math]::Floor(($p / 100) * 70); if ($s -gt $last) { if ($s -le 70) { $last = $s; $bar = '*' * $s + ' ' * (70 - $s); Write-Host ([char]13 + 'Progress: [' + $bar + '] ' + $p.ToString().PadLeft(3) + '%%') -NoNewline; } } } else { Write-Host ([char]13 + 'Progress: [ Streaming Direct Download Data Flow... ]') -NoNewline; } } Write-Host ([char]13 + 'Progress: [' + ('*' * 70) + '] 100%%')"

powershell -Command "%ps_cmd%"
if errorlevel 1 (
    echo.
    echo ERROR: Download failed. Please verify internet connection or local TLS configurations.
    pause
    exit /b 1
)

echo.
echo ==========================================================================================
echo SUCCESS: Download completed! Launching installer...
echo ==========================================================================================
echo.
start "" "%download_path%"
endlocal
pause
