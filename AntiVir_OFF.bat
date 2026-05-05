@echo off
chcp 65001 >nul
cls

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

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
