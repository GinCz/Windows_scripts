@echo off
chcp 65001 >nul
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Unmount_MEGA_M.ps1"
pause
