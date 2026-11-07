@echo off
setlocal EnableDelayedExpansion
title GIN-DNS-Switch Installer v001 [ VladiMIR ^& Antigravity ]

:: Auto-Elevation: Ensure Full Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Elevating to Administrator privileges for Setup...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

set "INSTALL_DIR=%ProgramFiles%\GIN-DNS-Switch"
set "SRC_DIR=%~dp0"

echo ==============================================================================
echo   GIN-DNS-SWITCH INSTALLER v001
echo   Smart 1-Click DNS Profile Manager
echo   Author: Vladimir Bulantsev (GinCz) ^& AI
echo ==============================================================================
echo.
echo [*] Target Directory: %INSTALL_DIR%

:: 1. Create directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: 2. Copy application files
echo [*] Copying core application files...
copy /y "%SRC_DIR%GIN-DNS-Switch.cmd" "%INSTALL_DIR%\" >nul
copy /y "%SRC_DIR%GIN-DNS-Switch_v001.cmd" "%INSTALL_DIR%\" >nul
copy /y "%SRC_DIR%app.ico" "%INSTALL_DIR%\" >nul
copy /y "%SRC_DIR%version.json" "%INSTALL_DIR%\" >nul
copy /y "%SRC_DIR%Uninstall.cmd" "%INSTALL_DIR%\" >nul

:: 3. Create Desktop and Start Menu Shortcuts via PowerShell
echo [*] Creating Desktop and Start Menu shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$desk = [Environment]::GetFolderPath('CommonDesktopDirectory'); " ^
    "if (-not $desk) { $desk = [Environment]::GetFolderPath('Desktop') }; " ^
    "$sc1 = $ws.CreateShortcut((Join-Path $desk 'GIN-DNS-Switch.lnk')); " ^
    "$sc1.TargetPath = Join-Path $env:ProgramFiles 'GIN-DNS-Switch\GIN-DNS-Switch.cmd'; " ^
    "$sc1.WorkingDirectory = Join-Path $env:ProgramFiles 'GIN-DNS-Switch'; " ^
    "$sc1.IconLocation = (Join-Path $env:ProgramFiles 'GIN-DNS-Switch\app.ico') + ',0'; " ^
    "$sc1.Description = 'GIN-DNS-Switch: 1-Click DNS Profile Manager (AdGuard, DHCP, Google, ISP)'; " ^
    "$sc1.Save(); " ^
    "$start = [Environment]::GetFolderPath('CommonPrograms'); " ^
    "$sc2 = $ws.CreateShortcut((Join-Path $start 'GIN-DNS-Switch.lnk')); " ^
    "$sc2.TargetPath = Join-Path $env:ProgramFiles 'GIN-DNS-Switch\GIN-DNS-Switch.cmd'; " ^
    "$sc2.WorkingDirectory = Join-Path $env:ProgramFiles 'GIN-DNS-Switch'; " ^
    "$sc2.IconLocation = (Join-Path $env:ProgramFiles 'GIN-DNS-Switch\app.ico') + ',0'; " ^
    "$sc2.Description = 'GIN-DNS-Switch: 1-Click DNS Profile Manager'; " ^
    "$sc2.Save();"

:: 4. Register in Windows Add/Remove Programs (Optional clean registry entry)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayName" /t REG_SZ /d "GIN-DNS-Switch" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayVersion" /t REG_SZ /d "v001" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "Publisher" /t REG_SZ /d "Vladimir Bulantsev (GinCz) & AI" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "DisplayIcon" /t REG_SZ /d "%INSTALL_DIR%\app.ico" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "UninstallString" /t REG_SZ /d "\"%INSTALL_DIR%\Uninstall.cmd\"" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-DNS-Switch" /v "InstallLocation" /t REG_SZ /d "%INSTALL_DIR%" /f >nul 2>&1

echo.
echo ==============================================================================
echo  [OK] Installation completed successfully!
echo  Desktop and Start Menu shortcuts created: GIN-DNS-Switch.lnk
echo ==============================================================================
echo.
timeout /t 3 >nul
exit /b 0
