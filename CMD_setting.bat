@echo off
chcp 65001 >nul
cls
setlocal EnableDelayedExpansion

:: Versioning: v2026-05-05 | github.com/GinCz/Windows_scripts
:: Author: = Rooted by VladiMIR | AI =

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] PLEASE RUN AS ADMINISTRATOR.
    pause
    exit /b
)

echo Forcing Consolas 20pt font and UTF-8 encoding for CMD...

:: 1. Delete per-process overrides so global settings take effect
reg delete "HKCU\Console\%%SystemRoot%%_System32_cmd.exe" /f >nul 2>&1
reg delete "HKCU\Console\%%SystemRoot%%_SysWOW64_cmd.exe" /f >nul 2>&1
reg delete "HKCU\Console\Command Prompt" /f >nul 2>&1

:: 2. Global font settings
set "K=HKCU\Console"

:: FaceName: Consolas (TrueType)
reg add "%K%" /v "FaceName" /t REG_SZ /d "Consolas" /f >nul
:: FontFamily: 54 dec (0x36) for TrueType fonts
reg add "%K%" /v "FontFamily" /t REG_DWORD /d 54 /f >nul
:: FontSize: 0x00140000 = 1310720 dec for size 20pt
reg add "%K%" /v "FontSize" /t REG_DWORD /d 1310720 /f >nul
:: FontWeight: 400 standard
reg add "%K%" /v "FontWeight" /t REG_DWORD /d 400 /f >nul

:: 3. Enable modern console mode (required for TrueType fonts on older builds)
reg add "%K%" /v "ForceV2" /t REG_DWORD /d 1 /f >nul
reg add "%K%" /v "VirtualTerminalLevel" /t REG_DWORD /d 1 /f >nul

:: 4. Buffer and window size: 120x9001 buffer / 120x30 window
reg add "%K%" /v "ScreenBufferSize" /t REG_DWORD /d 589889656 /f >nul
reg add "%K%" /v "WindowSize" /t REG_DWORD /d 1966200 /f >nul

:: 5. UTF-8 code page
reg add "%K%" /v "CodePage" /t REG_DWORD /d 65001 /f >nul

echo.
echo ================================================================================
echo  [OK] FONT SETTINGS UPDATED!
echo  [!]  NOTE: If you launch CMD via a desktop shortcut, shortcut settings
echo       may override these values.
echo  [FIX] Create a new shortcut or run CMD via Win+R -^> cmd
echo ================================================================================
echo.
echo = Rooted by VladiMIR ^| AI =
echo.
pause
