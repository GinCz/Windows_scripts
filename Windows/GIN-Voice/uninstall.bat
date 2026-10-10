@echo off
setlocal
title GIN-Voice Clean Uninstaller
cd /d "%~dp0"
if exist "%~dp0uninstall.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host ('='*90) -ForegroundColor Cyan; Write-Host '   GIN-Voice Clean Uninstaller' -ForegroundColor Cyan; Write-Host ('='*90) -ForegroundColor Cyan; Stop-Process -Name 'GIN-Voice*' -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$([Environment]::GetFolderPath('Desktop'))\GIN-Voice.lnk\" -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"D:\MEGA\DOCS\desktop\GIN-Voice*\" -Force -ErrorAction SilentlyContinue; Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'GIN-Voice' -ErrorAction SilentlyContinue; Write-Host ('='*90) -ForegroundColor Green; Write-Host '   GIN-Voice successfully uninstalled!' -ForegroundColor Green; Write-Host ('='*90) -ForegroundColor Green; Start-Sleep -Seconds 2; Start-Process cmd.exe -ArgumentList '/c timeout /t 1 >nul & rd /s /q \"\"%~dp0\"\"' -WindowStyle Hidden"
)
