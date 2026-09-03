@echo off
chcp 65001 >nul
cls

:: Auto-Elevate (fltmc - reliable Win10+11)
fltmc >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title XRAY VPN Installer - LOADING...
for /L %%i in (1,1,4) do echo.
powershell -Command "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Write-Host ' ░▒▓█░▒▓█░▒▓█  P O W E R S H E L L   S T A R T I N G  █▓▒░█▓▒░█▓▒░' -ForegroundColor DarkGray"
for /L %%i in (1,1,3) do echo.

:: Run embedded PowerShell section
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "XRAY VPN Installer - EXECUTE"

Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host '  ░▒▓█  X R A Y   V P N   I N S T A L L E R   -   Windows 10 / 11  ░▒▓█' -ForegroundColor Yellow
Write-Host '  github.com/GinCz/Windows_scripts  |  Windows/VPN/' -ForegroundColor DarkGray
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''
Write-Host '[*] Resetting proxy settings...' -ForegroundColor Cyan
& netsh winhttp reset proxy | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null
Write-Host '[+] Proxy cleared.' -ForegroundColor Green
Write-Host '[*] Downloading VPN installer from server...' -ForegroundColor Cyan
try {
    (New-Object Net.WebClient).DownloadFile('http://prodvig-saita.ru/vpn/install.ps1', "$env:TEMP\xray_install.ps1")
    Write-Host '[+] Downloaded.' -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host '[*] Running VPN installer...' -ForegroundColor Cyan
& "$env:TEMP\xray_install.ps1"
Remove-Item "$env:TEMP\xray_install.ps1" -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '[*] Downloading tray IP-tooltip helper from GitHub...' -ForegroundColor Cyan
$trayPs1 = "C:\XRAY_VPN\TrayVPN.ps1"
$githubRaw = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/VPN/tray_tooltip_helper.ps1"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    (New-Object Net.WebClient).DownloadFile($githubRaw, $trayPs1)
    Write-Host "[+] Tray helper updated: $trayPs1" -ForegroundColor Green
} catch {
    Write-Host "[!] GitHub download failed: $_" -ForegroundColor Yellow
}
if (Test-Path $trayPs1) {
    Write-Host '[*] Restarting tray with tooltip version...' -ForegroundColor Cyan
    Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -eq ""} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$trayPs1`"" -WindowStyle Hidden
    Write-Host '[+] Tray restarted with IP tooltip!' -ForegroundColor Green
}
Write-Host '[*] Creating autostart shortcut...' -ForegroundColor Cyan
$wsh = New-Object -ComObject WScript.Shell
$startupDir = $wsh.SpecialFolders("AllUsersStartup")
$lnk = $wsh.CreateShortcut("$startupDir\XrayVPN_Tray.lnk")
$lnk.TargetPath = "powershell.exe"
$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$trayPs1`""
$lnk.WorkingDirectory = "C:\XRAY_VPN"
$lnk.Description = "Xray VPN Tray | github.com/GinCz/Windows_scripts"
$lnk.Save()
Write-Host '[+] Autostart shortcut created.' -ForegroundColor Green
Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ' [OK] Done! (Windows 10/11 edition)' -ForegroundColor Green
Write-Host ''
Write-Host '  Hover over tray icon:   VPN IP / Original IP / Username' -ForegroundColor Green
Write-Host '  Double-click tray icon: Balloon with full IP info' -ForegroundColor Green
Write-Host '  GREEN=Connected  ORANGE=Connecting  GREY=Off  RED=Error' -ForegroundColor Green
Write-Host ''
Write-Host '  Next:  VLESS key -> C:\XRAY_VPN\link.txt -> Save -> Start_VPN' -ForegroundColor Green
Write-Host '  GitHub: https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN' -ForegroundColor DarkGray
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ''
Read-Host "Press Enter to exit"
