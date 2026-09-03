@echo off
chcp 65001 >nul
cls

echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7 / 10 / 11
echo ====================================================================
echo.

:: 1. Self-elevation to Administrator via UAC
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c ""%~f0""' -Verb RunAs"
    exit /b
)

echo [+] Running with Administrator privileges!
echo [*] Launching automated installer...

if exist "%~dp0Install_XRAY_VPN.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_XRAY_VPN.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=3072; iex ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Install_XRAY_VPN.ps1'))"
)

echo.
pause
