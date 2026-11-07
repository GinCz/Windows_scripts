@echo off
setlocal EnableDelayedExpansion
title GIN-DNS-Switch Uninstaller [ VladiMIR ^& Antigravity ]

:: Auto-Elevation: Ensure Full Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%ProgramFiles%\GIN-DNS-Switch"

echo ==============================================================================
echo   GIN-DNS-SWITCH UNINSTALLER
echo ==============================================================================
echo.
echo [*] Removing shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$desk = [Environment]::GetFolderPath('CommonDesktopDirectory'); " ^
    "$userDesk = [Environment]::GetFolderPath('Desktop'); " ^
    "$start = [Environment]::GetFolderPath('CommonPrograms'); " ^
    "Remove-Item (Join-Path $desk 'GIN-DNS-Switch.lnk') -Force -ErrorAction SilentlyContinue; " ^
    "Remove-Item (Join-Path $userDesk 'GIN-DNS-Switch.lnk') -Force -ErrorAction SilentlyContinue; " ^
    "Remove-Item (Join-Path $start 'GIN-DNS-Switch.lnk') -Force -ErrorAction SilentlyContinue;"

echo [*] Removing Registry entries...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /f >nul 2>&1

echo [*] Scheduling directory removal...
start /b "" cmd /c "timeout /t 2 >nul & rmdir /s /q \"%INSTALL_DIR%\""

echo.
echo [OK] GIN-DNS-Switch uninstalled cleanly.
timeout /t 2 >nul
exit /b 0
