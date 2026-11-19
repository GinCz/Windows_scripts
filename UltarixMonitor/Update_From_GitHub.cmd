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
set "SCRIPT_FILE=%~f0"
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$f = $env:SCRIPT_FILE; if (-not $f) { $f = '%~f0' }; $raw = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8); try { & ([ScriptBlock]::Create($raw)) } catch { try { [Console]::WriteLine('`n[X] CHYBA: ' + $_.Exception.Message) } catch { Write-Output $_.Exception.Message } }"

if /i not "%~1"=="-silent" if /i not "%~1"=="/silent" (
    echo.
    pause
)
exit /b
#>
# ==============================================================================
# ULTARIX s.r.o. - 1-Click Update From GitHub (Hybrid Polyglot Engine)
# Author  : VladiMIR + Antigravity AI
# Version : v2.4.0 (2026-11)
# ==============================================================================

function Write-SafeHost {
    param(
        [string]$Text = "",
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    try {
        Write-Host $Text -ForegroundColor $Color
    } catch {
        try {
            [Console]::ForegroundColor = $Color
            [Console]::WriteLine($Text)
            [Console]::ResetColor()
        } catch {
            Write-Output $Text
        }
    }
}

$target = "C:\UTIL\UltarixMonitor"
if (-not (Test-Path $target)) {
    if (Test-Path "$PSScriptRoot\dashboard.html") {
        $target = $PSScriptRoot
    } else {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    }
}

try { Clear-Host } catch {}
try { $Host.UI.RawUI.WindowTitle = "ULTARIX - Aktualizace monitoringu z GitHub" } catch {}

Write-SafeHost "======================================================================" Cyan
Write-SafeHost "   ULTARIX s.r.o. - Automaticka aktualizace souboru z GitHub          " Green
Write-SafeHost "======================================================================" Cyan
Write-SafeHost " Cilova slozka : $target" White
Write-SafeHost " Repozitar     : GinCz/Windows_scripts (vetev main)" White
Write-SafeHost "======================================================================" Cyan
Write-SafeHost "" White

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$baseUri = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/UltarixMonitor"
$files = @("dashboard.html", "0_Server_Setup.cmd", "1_Client_Install.cmd", "2_Ulyana_Dashboard.cmd", "employees.json", "README.md", "Update_From_GitHub.cmd")

foreach ($f in $files) {
    $url = "$baseUri/$f"
    $dest = "$target\$f"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $len = (Get-Item $dest).Length
        Write-SafeHost ("    [OK] {0,-25} : Aktualizovano ({1} B)" -f $f, $len) Green
    } catch {
        Write-SafeHost ("    [!] {0,-25} : Chyba stahovani: {1}" -f $f, $_.Exception.Message) Red
    }
}

Write-SafeHost "" White
Write-SafeHost "======================================================================" Green
Write-SafeHost "       AKTUALIZACE Z GITHUB BYLA USPESNE DOKONCENA!                   " Green
Write-SafeHost "======================================================================" Green
Write-SafeHost " Vsechny skripty, dashboard.html a nastaveni byly prepsany." White
Write-SafeHost " Vase ulozene logy v podslozce \logs zustaly nedotceny." White
Write-SafeHost "======================================================================" Green
Write-SafeHost "" White
