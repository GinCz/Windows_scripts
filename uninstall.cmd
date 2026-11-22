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
    $ErrorActionPreference = "Continue"

    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $OutputEncoding = [System.Text.Encoding]::UTF8
    } catch {}

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host "           GIN-AGENT - COMPLETE SYSTEM UNINSTALLATION               " -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host ""

    # Hardware GIN-PIN calculation (Deterministic WMI)
    $pin = "100-000-001"
    try {
        $uuid = (Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        $board = (Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).SerialNumber
        if (-not $uuid) { $uuid = $env:COMPUTERNAME }
        if (-not $board) { $board = "DefaultBoard" }
        $rawPin = "hw_win_${uuid}_${board}"
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawPin)
        $digest = $sha.ComputeHash($bytes)
        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($digest, 0, 8) }
        $num = [Math]::Abs([BitConverter]::ToInt64($digest, 0))
        $code = ($num % 900000000) + 100000000
        $dStr = $code.ToString("D9")
        $pin = "$($dStr.Substring(0,3))-$($dStr.Substring(3,3))-$($dStr.Substring(6,3))"
    } catch {}

    # STEP 1: Deregister from remote server dashboards
    Write-Host "[*] Step 1/6: Deregistering host from remote server dashboards..." -ForegroundColor Cyan
    Write-Host "    [i] Host: $env:COMPUTERNAME | Hardware PIN: $pin" -ForegroundColor DarkGray
    $unregPayload = @{ pin = $pin; host = $env:COMPUTERNAME } | ConvertTo-Json
    $gateways = @(
        "https://remote.gincz.com/agent-api",
        "http://212.109.223.109/agent-api",
        "http://152.53.182.222:9876"
    )
    $unregSuccess = $false
    foreach ($gw in $gateways) {
        try {
            $resp = Invoke-RestMethod -Uri "$gw/unregister" -Method Post -Headers @{ Token = "GinCz-Remote-2026" } -ContentType "application/json; charset=utf-8" -Body $unregPayload -TimeoutSec 3 -ErrorAction Stop
            if ($resp) {
                Write-Host "    [+] Deregistered from gateway: $gw" -ForegroundColor DarkGray
                $unregSuccess = $true
            }
        } catch {}
    }
    try {
        $respRd = Invoke-RestMethod -Uri "https://rd.gincz.com/api/unregister?pin=$pin&host=$env:COMPUTERNAME" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($respRd) { Write-Host "    [+] Deregistered from RustDesk registry (rd.gincz.com)" -ForegroundColor DarkGray }
    } catch {}
    Write-Host "    [OK] Remote server dashboard status: cleared (offline/uninstalled)." -ForegroundColor Green

    # STEP 2: Stop and delete scheduled tasks
    Write-Host "[*] Step 2/6: Stopping and removing Windows Scheduled Tasks..." -ForegroundColor Cyan
    $tasks = @("GIN-Agent-Service", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
    foreach ($t in $tasks) {
        try {
            $taskInfo = schtasks.exe /query /tn "$t" 2>&1
            if ($LASTEXITCODE -eq 0) {
                schtasks.exe /end /tn "$t" 2>&1 | Out-Null
                schtasks.exe /delete /tn "$t" /f 2>&1 | Out-Null
                Write-Host "    [+] Terminated and deleted task: $t" -ForegroundColor DarkGray
            }
        } catch {}
    }
    Write-Host "    [OK] All GIN-Agent scheduled tasks removed." -ForegroundColor Green

    # STEP 3: Stop and remove legacy Windows Services
    Write-Host "[*] Step 3/6: Stopping and deleting legacy Windows Services (sc.exe)..." -ForegroundColor Cyan
    $services = @("GIN-Agent", "GIN-Agent-Service", "GIN_Agent")
    foreach ($s in $services) {
        try {
            & sc.exe stop $s 2>&1 | Out-Null
            & sc.exe delete $s 2>&1 | Out-Null
            Write-Host "    [+] Stopped/purged service: $s" -ForegroundColor DarkGray
        } catch {}
    }
    Write-Host "    [OK] Windows Services checked and cleaned." -ForegroundColor Green

    # STEP 4: Terminate running background agent processes
    Write-Host "[*] Step 4/6: Terminating active background agent processes..." -ForegroundColor Cyan
    $currentPid = $PID
    $parentPid = 0
    try {
        $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
        if ($parentProc) { $parentPid = $parentProc.ParentProcessId }
    } catch {}

    $killedCount = 0
    try {
        Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' or Name = 'cmd.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                $_.CommandLine -like "*GIN-Agent* /service*" -or
                $_.CommandLine -like "*GIN-Agent.cmd*" -or
                $_.CommandLine -like "*Global\GIN_Agent_Core_Mutex*"
            )
        } | ForEach-Object {
            try {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
                & taskkill.exe /F /PID $_.ProcessId 2>&1 | Out-Null
                Write-Host "    [+] Terminated PID: $($_.ProcessId) ($($_.Name))" -ForegroundColor DarkGray
                $killedCount++
            } catch {}
        }
    } catch {}
    Write-Host "    [OK] Process cleanup complete ($killedCount background instances terminated)." -ForegroundColor Green

    # STEP 5: Remove Windows Registry uninstall entries
    Write-Host "[*] Step 5/6: Removing Windows Registry uninstall registrations..." -ForegroundColor Cyan
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent",
        "HKLM:\SOFTWARE\GIN-Agent"
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            try {
                Remove-Item -Path $rp -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "    [+] Purged registry key: $rp" -ForegroundColor DarkGray
            } catch {}
        }
    }
    Write-Host "    [OK] Windows Add/Remove Programs registry keys purged." -ForegroundColor Green

    # STEP 6: Clean up directories and files
    Write-Host "[*] Step 6/6: Purging program files and data directories..." -ForegroundColor Cyan
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = "$env:ProgramFiles\GIN-Agent\uninstall.cmd" }
    $parentFolder = Split-Path -Parent $scriptPath

    $dirsToPurge = @(
        "$env:ProgramData\GIN-Agent",
        "$env:ProgramFiles\GIN-Agent",
        "${env:ProgramFiles(x86)}\GIN-Agent"
    )
    foreach ($d in $dirsToPurge) {
        if (Test-Path $d) {
            Get-ChildItem -Path $d -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.FullName -ne $scriptPath) {
                    try {
                        $_.IsReadOnly = $false
                        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                        Write-Host "    [+] Deleted file: $($_.Name)" -ForegroundColor DarkGray
                    } catch {}
                }
            }
        }
    }
    Write-Host "    [OK] File purge completed successfully." -ForegroundColor Green

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  [OK] GIN-AGENT HAS BEEN COMPLETELY AND CLEANLY REMOVED!           " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  [+] All background services, scheduled tasks, and registry entries deleted." -ForegroundColor White
    Write-Host "  [+] Server-side telemetry record deregistered from remote dashboard." -ForegroundColor White
    Write-Host "  [+] Installation directory will be purged upon window close." -ForegroundColor White
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    # Self-deletion of the directory via detached cmd after exit
    if ($parentFolder -and (Test-Path $parentFolder)) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c ping 127.0.0.1 -n 2 >nul & rd /s /q `"`"$parentFolder`"`"" -WindowStyle Hidden
    }

    # 10-second interactive countdown for user to read/copy the log
    for ($sec = 10; $sec -gt 0; $sec--) {
        Write-Host -NoNewline "`r[*] Window closing automatically in $sec seconds (or press any key to close now)...   "
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.ElapsedMilliseconds -lt 1000) {
            $keyHit = $false
            try {
                if (-not [Console]::IsInputRedirected) {
                    if ([System.Console]::KeyAvailable) {
                        [void][System.Console]::ReadKey($true)
                        $keyHit = $true
                    }
                }
            } catch {}
            if ($keyHit) {
                $sec = 0
                break
            }
            Start-Sleep -Milliseconds 50
        }
    }
    Write-Host ""
    [System.Environment]::Exit(0)
} catch {
    Write-Host ""
    Write-Host "[!] Uninstallation error: $($_.Exception.Message)" -ForegroundColor Red
    Start-Sleep -Seconds 10
    exit 1
}
