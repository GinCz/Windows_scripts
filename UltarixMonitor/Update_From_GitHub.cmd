<# :
@echo off
setlocal DisableDelayedExpansion
title ULTARIX - Update From GitHub [VladiMIR + Antigravity]

:: Enable UNC support
reg add "HKCU\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1

:: Auto-Elevation check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_UPDATE

if not defined ULTARIX_UPDATE_ELEVATED (
    set ULTARIX_UPDATE_ELEVATED=1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

:RUN_UPDATE
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"

if /i not "%~1"=="-silent" if /i not "%~1"=="/silent" (
    echo.
    pause
)
exit /b
#>
# ==============================================================================
# ULTARIX s.r.o. - 1-Click Update From GitHub (Hybrid Polyglot Engine)
# Author  : VladiMIR + Antigravity AI
# Version : v2.3.1 (2026-11)
# ==============================================================================

$target = "C:\UTIL\UltarixMonitor"
if (-not (Test-Path $target)) {
    if (Test-Path "$PSScriptRoot\dashboard.html") {
        $target = $PSScriptRoot
    } else {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTARIX - Aktualizace monitoringu z GitHub"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "      ULTARIX s.r.o. - Automaticka aktualizace souboru z GitHub                 " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Cilova slozka : $target" -ForegroundColor White
Write-Host " Repozitar     : GinCz/Windows_scripts (vetev main)" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$baseUri = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/UltarixMonitor"
$files = @("dashboard.html", "0_Server_Setup.cmd", "1_Client_Install.cmd", "2_Ulyana_Dashboard.cmd", "employees.json", "README.md", "Update_From_GitHub.cmd")

foreach ($f in $files) {
    $url = "$baseUri/$f?v=" + [DateTime]::UtcNow.Ticks
    $dest = "$target\$f"
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $bytes = $wc.DownloadData($url)
        if ($bytes.Length -gt 100) {
            [System.IO.File]::WriteAllBytes($dest, $bytes)
            Write-Host ("    [OK] {0,-25} : Stazeno ({1} B)" -f $f, $bytes.Length) -ForegroundColor Green
        } else {
            Write-Host ("    [-] {0,-25} : Soubor je prilis maly" -f $f) -ForegroundColor Yellow
        }
    } catch {
        Write-Host ("    [!] {0,-25} : Chyba stahovani: {1}" -f $f, $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "       AKTUALIZACE Z GITHUB BYLA USPESNE DOKONCENA!                            " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host " Vsechny skripty, dashboard.html a nastaveni byly prepsany na nejnovejsi verzi." -ForegroundColor White
Write-Host " Vase ulozene logy v podslozce \logs zustaly nedotceny." -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
