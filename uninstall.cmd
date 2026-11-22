<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent Uninstaller

:: Elevation check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_UNINSTALL

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
exit /b %errorlevel%

:RUN_UNINSTALL
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) else if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"
set "PS_ERR=%errorlevel%"
exit /b %PS_ERR%
#>
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Red
Write-Host "           GIN-AGENT - COMPLETE SYSTEM UNINSTALLATION               " -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Red
Write-Host "[*] Stopping and removing GIN-Agent services and scheduled tasks..." -ForegroundColor Cyan

# 1. Stop and remove scheduled tasks
$tasks = @("GIN-Agent-Service", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
foreach ($t in $tasks) {
    try { schtasks.exe /end /tn "$t" 2>&1 | Out-Null } catch {}
    try { schtasks.exe /delete /tn "$t" /f 2>&1 | Out-Null } catch {}
}

# 2. Stop and remove legacy Windows Services
$services = @("GIN-Agent", "GIN-Agent-Service", "GIN_Agent")
foreach ($s in $services) {
    try { & sc.exe stop $s 2>&1 | Out-Null } catch {}
    try { & sc.exe delete $s 2>&1 | Out-Null } catch {}
}

# 3. Terminate running agent processes
$currentPid = $PID
$parentPid = 0
try {
    $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
    if ($parentProc) { $parentPid = $parentProc.ParentProcessId }
} catch {}

try {
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' or Name = 'cmd.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
            $_.CommandLine -like "*GIN-Agent*" -or
            $_.CommandLine -like "*agent-api*" -or
            $_.CommandLine -like "*Global\GIN_Agent_Core_Mutex*"
        )
    } | ForEach-Object {
        try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
    }
} catch {}

Start-Sleep -Milliseconds 600

# 4. Remove Windows Registry entries
Write-Host "[*] Removing registry entries..." -ForegroundColor Cyan
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent",
    "HKLM:\SOFTWARE\GIN-Agent"
)
foreach ($rp in $regPaths) {
    if (Test-Path $rp) {
        try { Remove-Item -Path $rp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# 5. Clean up directories
Write-Host "[*] Removing GIN-Agent files and directories..." -ForegroundColor Cyan
$dirsToPurge = @(
    "$env:ProgramData\GIN-Agent",
    "$env:ProgramFiles\GIN-Agent",
    "${env:ProgramFiles(x86)}\GIN-Agent"
)
foreach ($d in $dirsToPurge) {
    if (Test-Path $d) {
        try {
            Get-ChildItem -Path $d -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.FullName -ne $MyInvocation.MyCommand.Path) {
                    try { $_.IsReadOnly = $false; Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
                }
            }
        } catch {}
    }
}

# 6. Detached self-cleanup for remaining folder
$scriptPath = $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = "$env:ProgramFiles\GIN-Agent\uninstall.cmd" }
$parentFolder = Split-Path -Parent $scriptPath

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  [OK] GIN-AGENT HAS BEEN COMPLETELY AND CLEANLY REMOVED!           " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

# Spawn detached cmd to remove the folder itself after exit
if ($parentFolder -and (Test-Path $parentFolder)) {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c ping 127.0.0.1 -n 3 >nul & rd /s /q `"`"$parentFolder`"`"" -WindowStyle Hidden
}

Start-Sleep -Seconds 2
exit 0
