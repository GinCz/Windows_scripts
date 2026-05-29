@echo off
chcp 65001 >nul
cls

:: ==========================================================================================
:: FILE    : AntiVir_OFF.bat
:: VERSION : v2026.05.29d
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: REPO    : github.com/GinCz/Windows_scripts
:: ==========================================================================================
:: DESCRIPTION:
::   Toggles Windows Defender Real-Time Protection ON or OFF interactively.
::   Shows the current protection status before prompting for action.
::   Uses PowerShell Set-MpPreference to change the Defender state.
::
:: REQUIREMENTS:
::   - Windows 10 / Windows 11
::   - Must be run as Administrator
::
:: USAGE:
::   1. Right-click AntiVir_OFF.bat -> Run as administrator
::   2. Current Defender status is displayed
::   3. Enter 1 to disable or 2 to enable real-time protection
:: ==========================================================================================

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b
)

:: Show current Defender status
powershell -Command "cls; if ((Get-MpPreference).DisableRealtimeMonitoring) { Write-Host '[STATUS] Windows Defender Real-Time Protection: OFF' -ForegroundColor Red } else { Write-Host '[STATUS] Windows Defender Real-Time Protection: ON' -ForegroundColor Green }"

echo.
set "choice="
set /p "choice=1=Turn OFF, 2=Turn ON: "

if "%choice%"=="1" (
    powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"
    cls
    echo [OK] Defender Real-Time Protection DISABLED.
) else if "%choice%"=="2" (
    powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
    cls
    echo [OK] Defender Real-Time Protection ENABLED.
) else (
    cls
    echo [!] Invalid choice.
)

echo.
echo = Rooted by VladiMIR ^| AI =
pause
