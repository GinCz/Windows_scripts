:: Execution Context : CMD / Batch (Run as Administrator or Current User)
:: Target Server     : Local Windows Desktop PC
:: Description       : Clean Uninstaller for GIN-Voice

@echo off
cls
title GIN-Voice Clean Uninstaller

echo ======================================================================
echo   Uninstalling GIN-Voice...
echo ======================================================================
echo.

:: 1. Force stop all running instances of GIN-Voice
echo [1/4] Stopping GIN-Voice processes...
taskkill /F /IM GIN-Voice.exe /IM GIN-Voice_v001.exe /IM GIN-Voice_v002.exe /IM GIN-Voice_v003.exe /IM GIN-Voice_Setup*.exe 2>nul
timeout /t 1 /nobreak >nul

:: 2. Remove desktop and start menu shortcuts
echo [2/4] Removing shortcuts...
del /f /q "%USERPROFILE%\Desktop\GIN-Voice.lnk" 2>nul
del /f /q "D:\MEGA\DOCS\desktop\GIN-Voice.lnk" 2>nul
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\GIN-Voice.lnk" 2>nul
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\GIN-Voice.bat" 2>nul

:: 3. Remove Windows Uninstall registry keys
echo [3/4] Cleaning registry entries...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice" /f 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice" /f 2>nul

:: 4. Delete installation folder
echo [4/4] Removing installation directory...
set "APP_DIR=%~dp0"
cd /d "%TEMP%"
start /b "" cmd /c "timeout /t 1 >nul & rd /s /q "%APP_DIR%" 2>nul"

echo.
echo ======================================================================
echo   GIN-Voice was successfully uninstalled!
echo ======================================================================
timeout /t 2 >nul
exit /b 0
