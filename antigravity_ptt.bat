@echo off
:: ==========================================================================================
::  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  Antigravity Launcher + PTT | [v2026-08-15_b]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
:: ==========================================================================================

:: Start Antigravity IDE if not already running
tasklist /fi "imagename eq Antigravity.exe" | find /i "Antigravity.exe" >nul
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe" (
        start "" "%LOCALAPPDATA%\Programs\antigravity\Antigravity.exe"
    )
)

:: Start Helper Daemon hidden in background (will automatically self-terminate when Antigravity closes)
wscript.exe "D:\AI\GitHub\Windows_scripts\antigravity_ptt_hidden.vbs"

exit
:: = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz
