@echo off
:: ==========================================================================================
::  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  Antigravity Launcher + PTT | [v2026-09-20]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
:: ==========================================================================================

:: Start Antigravity IDE if not already running
tasklist /fi "imagename eq Antigravity.exe" | find /i "Antigravity.exe" >nul
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe" (
        start "" "%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe"
    )
)

:: Start Helper Daemon hidden in background (persistent loop with auto-reconnect)
if exist "D:\AI\GitHub\Windows_scripts\antigravity_ptt_hidden.vbs" (
    wscript.exe "D:\AI\GitHub\Windows_scripts\antigravity_ptt_hidden.vbs"
) else if exist "C:\UTIL\Antigravity_AI\GitHub\Windows_scripts\antigravity_ptt_hidden.vbs" (
    wscript.exe "C:\UTIL\Antigravity_AI\GitHub\Windows_scripts\antigravity_ptt_hidden.vbs"
)

exit
