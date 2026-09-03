@echo off
chcp 65001 >nul
cls

:: Auto-Elevate to Administrator (fltmc method - reliable Win7+10+11)
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

:: Extract and run the embedded PowerShell section from this file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $s=[System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $s.Substring($s.IndexOf('#'+'#PS_MAIN'))"
exit /b

##PS_MAIN
clear
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "XRAY VPN Installer - EXECUTE"

Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''
Write-Host '  ░▒▓█░▒▓█░▒▓█░▒▓█  X R A Y   V P N   I N S T A L L E R  █▓▒░█▓▒░█▓▒░█▓▒░' -ForegroundColor Yellow
Write-Host '           Windows 10 / 11 edition  |  github.com/GinCz/Windows_scripts' -ForegroundColor DarkGray
Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Yellow
Write-Host ''

Write-Host '[*] Resetting proxy settings...' -ForegroundColor Cyan
& netsh winhttp reset proxy | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f | Out-Null
Write-Host '[+] Proxy cleared.' -ForegroundColor Green

Write-Host '[*] Downloading installer script from server...' -ForegroundColor Cyan
try {
    (New-Object Net.WebClient).DownloadFile('http://prodvig-saita.ru/vpn/install.ps1', "$env:TEMP\xray_install.ps1")
    Write-Host '[+] Installer downloaded.' -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    Write-Host 'Press Enter to exit...' -ForegroundColor DarkGray
    Read-Host | Out-Null
    exit 1
}

Write-Host '[*] Running VPN installer...' -ForegroundColor Cyan
& "$env:TEMP\xray_install.ps1"
Remove-Item "$env:TEMP\xray_install.ps1" -Force -ErrorAction SilentlyContinue

# ── Tray tooltip helper ──────────────────────────────────────────────
Write-Host ''
Write-Host '[*] Downloading tray tooltip helper from GitHub...' -ForegroundColor Cyan
$trayDir = "C:\XRAY_VPN"
$trayPs1 = "$trayDir\tray_tooltip_helper.ps1"
$githubRaw = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/VPN/tray_tooltip_helper.ps1"

if (-not (Test-Path $trayDir)) { New-Item -ItemType Directory -Path $trayDir -Force | Out-Null }

try {
    (New-Object Net.WebClient).DownloadFile($githubRaw, $trayPs1)
    Write-Host "[+] Tray helper ready: $trayPs1" -ForegroundColor Green
} catch {
    Write-Host "[!] GitHub download failed: $_" -ForegroundColor Yellow
}

# ── Ярлык автозапуска в Common Startup ──────────────────────────────
if (Test-Path $trayPs1) {
    Write-Host '[*] Creating autostart shortcut...' -ForegroundColor Cyan
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut([Environment]::GetFolderPath('CommonStartup') + '\XrayVPN_Tray.lnk')
    $lnk.TargetPath = 'powershell.exe'
    $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$trayPs1`""
    $lnk.WorkingDirectory = $trayDir
    $lnk.Description = 'Xray VPN Tray | github.com/GinCz/Windows_scripts'
    $lnk.Save()
    Write-Host '[+] Autostart shortcut created (Common Startup).' -ForegroundColor Green

    Write-Host '[*] Launching tray icon now...' -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$trayPs1`"" -WindowStyle Hidden
    Write-Host '[+] Tray icon started!' -ForegroundColor Green
}

Write-Host ''
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ' [OK] Done! (Windows 10/11 edition)' -ForegroundColor Green
Write-Host ''
Write-Host '  Hover over tray icon to see:' -ForegroundColor Green
Write-Host '    VPN IP (through tunnel) / Original IP / Username' -ForegroundColor Green
Write-Host ''
Write-Host '  Icon colors:  GREEN=Connected  ORANGE=Connecting  GREY=Off  RED=Error' -ForegroundColor Green
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Green
Write-Host '    1. Paste your VLESS key into C:\XRAY_VPN\link.txt and Save' -ForegroundColor Green
Write-Host '    2. Run Start_VPN shortcut' -ForegroundColor Green
Write-Host '    3. Hover over tray icon to verify VPN IP changed' -ForegroundColor Green
Write-Host ''
Write-Host '  GitHub: https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN' -ForegroundColor DarkGray
Write-Host '==========================================================================================' -ForegroundColor Green
Write-Host ''
Write-Host 'Press Enter to exit...' -ForegroundColor DarkGray
Read-Host | Out-Null