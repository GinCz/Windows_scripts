<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent v030

:: If launched with /service or --service in background
if /i "%~1"=="/service" goto :RUN_SERVICE
if /i "%~1"=="--service" goto :RUN_SERVICE

:: If launched with /checkupdate or --checkupdate
if /i "%~1"=="/checkupdate" goto :RUN_CHECKUPDATE
if /i "%~1"=="--checkupdate" goto :RUN_CHECKUPDATE

:: If launched with /uninstall or --uninstall
if /i "%~1"=="/uninstall" goto :RUN_UNINSTALL
if /i "%~1"=="--uninstall" goto :RUN_UNINSTALL

:: If launched with /silent or /update
if /i "%~1"=="/silent" set "GIN_AGENT_SILENT=1"
if /i "%~1"=="/update" set "GIN_AGENT_SILENT=1"

:: Check for direct region parameter if passed via CLI
if /i "%~1"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%~1"=="RU" set "GIN_AGENT_REGION=RU"
if /i "%~1"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%~1"=="EU" set "GIN_AGENT_REGION=EU"

if /i "%~2"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%~2"=="RU" set "GIN_AGENT_REGION=RU"
if /i "%~2"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%~2"=="EU" set "GIN_AGENT_REGION=EU"

:: 1. Resilient Elevation Check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_INSTALLER

if not defined GIN_AGENT_ELEVATED (
    set GIN_AGENT_ELEVATED=1
    if defined GIN_AGENT_REGION (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList '%GIN_AGENT_REGION%' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    ) else (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    )
    if not errorlevel 1 exit /b 0
)

:RUN_INSTALLER
set "GIN_AGENT_MODE=INSTALL"
goto :EXEC_PS

:RUN_SERVICE
set "GIN_AGENT_MODE=SERVICE"
if not "%~2"=="" set "GIN_AGENT_REGION=%~2"
goto :EXEC_PS

:RUN_CHECKUPDATE
set "GIN_AGENT_MODE=CHECKUPDATE"
if not "%~2"=="" set "GIN_AGENT_REGION=%~2"
goto :EXEC_PS

:RUN_UNINSTALL
set "GIN_AGENT_MODE=UNINSTALL"
goto :EXEC_PS

:EXEC_PS
set "GIN_AGENT_SCRIPT=%~f0"

set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) else if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"
set "PS_ERR=%errorlevel%"

if "%GIN_AGENT_MODE%"=="INSTALL" (
    if not defined GIN_AGENT_SILENT (
        if %PS_ERR% neq 0 (
            echo.
            echo ====================================================================
            echo [ERROR] GIN-Agent execution halted with error code: %PS_ERR%
            echo ====================================================================
            echo.
            pause
        )
    )
)

exit /b %PS_ERR%
#>
# ==============================================================================
# GIN-Agent Windows Service v030 (Single File CMD Hybrid)
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Permanent Background Windows Service (Auto-Start, Watchdog Recovery, No Console Window)
# Primary Identifier: 9-Digit Hardware GIN-PIN
# Supported Platforms: Windows 10 (32-bit & 64-bit), Windows 11 (64-bit / ARM64)
# Regional Gateways:
#   - Europe: Server_222 (152.53.182.222:9876), Global (remote.gincz.com)
#   - Russia: Server_109 (212.109.223.109), RU-FastNode (195.158.255.208)
# Key v030 Fixes & Improvements:
#   1. Guaranteed Dual KeepAlive Heartbeat: Direct loop ping every ~25s + global-scoped background timer
#   2. Corrected Variable Scope in Timer & Heartbeat (100% valid PIN & RustDesk ID delivery)
#   3. Clean Process Killer: Kills all previous GIN-Agent instances unconditionally so mutex is released
#   4. Battery & 72h Timeout Hardening: Task Scheduler settings updated to prevent auto-kill on battery
#   5. Watchdog Syntax Fix: Escaped $_.CommandLine in scheduled task definition
# ==============================================================================

try {
    $ErrorActionPreference = "Continue"

    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $OutputEncoding = [System.Text.Encoding]::UTF8
    } catch {}

    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {}

    $installDir = "$env:ProgramFiles\GIN-Agent"
    $targetCmd = "$installDir\GIN-Agent.cmd"
    $targetCmdVer = "$installDir\GIN-Agent_Windows_v030.cmd"
    $uninstallerCmd = "$installDir\uninstall.cmd"
    $serviceName = "GIN-Agent"
    $serviceDisplayName = "GIN-Agent Remote Support Service"
    $serviceDesc = "Provides resilient background diagnostic connection, auto-updates and RDP shadow support for Vladimir Bulantsev (GinCz)."

    $mode = $env:GIN_AGENT_MODE
    if (-not $mode) {
        if ($env:GIN_AGENT_SCRIPT -and ($env:GIN_AGENT_SCRIPT.ToLower().Contains("program files") -or $env:GIN_AGENT_SCRIPT.ToLower().Contains("programdata"))) {
            $mode = "SERVICE"
        } else {
            $mode = "INSTALL"
        }
    }

    # Function: Auto-Update Check
    function Check-GINAgentUpdate {
        param([string]$currentVer = "v030", [string]$activeRegion = "EU")
        try {
            $versionUrls = @()
            if ($activeRegion -eq "RU") {
                $versionUrls += "http://212.109.223.109/agent/version.txt"
                $versionUrls += "https://rd.gincz.com/agent/version.txt"
                $versionUrls += "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/version.txt"
            } else {
                $versionUrls += "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/version.txt"
                $versionUrls += "http://212.109.223.109/agent/version.txt"
                $versionUrls += "https://remote.gincz.com/agent-api/version.txt"
            }

            $remoteVer = ""
            foreach ($vu in $versionUrls) {
                try {
                    $v = (Invoke-RestMethod -Uri $vu -TimeoutSec 4 -ErrorAction Stop).Trim()
                    if ($v -match '^v\d{3}$') {
                        $remoteVer = $v
                        break
                    }
                } catch {}
            }

            if ($remoteVer -and ($remoteVer -gt $currentVer)) {
                $downloadUrls = @()
                if ($activeRegion -eq "RU") {
                    $downloadUrls += "http://212.109.223.109/GIN-Agent_Windows.cmd"
                    $downloadUrls += "https://rd.gincz.com/GIN-Agent_Windows.cmd"
                    $downloadUrls += "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Agent_Windows.cmd"
                } else {
                    $downloadUrls += "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/GIN-Agent_Windows.cmd"
                    $downloadUrls += "http://212.109.223.109/GIN-Agent_Windows.cmd"
                    $downloadUrls += "https://remote.gincz.com/agent-api/GIN-Agent_Windows.cmd"
                }

                $tempUpdateFile = "$env:TEMP\GIN-Agent_Update_$remoteVer.cmd"
                foreach ($du in $downloadUrls) {
                    try {
                        Invoke-WebRequest -Uri $du -OutFile $tempUpdateFile -TimeoutSec 20 -ErrorAction Stop
                        if ((Test-Path $tempUpdateFile) -and ((Get-Item $tempUpdateFile).Length -gt 15000)) {
                            $sample = Get-Content -Path $tempUpdateFile -TotalCount 25 -Raw
                            if ($sample -like "*GIN-Agent*") {
                                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"`"$tempUpdateFile`" /silent /service $activeRegion`"" -WindowStyle Hidden
                                exit 0
                            }
                        }
                    } catch {}
                }
            }
        } catch {}
    }

    # ==========================================================================
    # MODE 1.5: STANDALONE UPDATE CHECK (/checkupdate - Scheduled on logon +30m)
    # ==========================================================================
    if ($mode -eq "CHECKUPDATE") {
        $reg = $env:GIN_AGENT_REGION
        if (-not $reg) {
            $regFile = "$installDir\region.txt"
            if (Test-Path $regFile) {
                try { $reg = (Get-Content $regFile -Raw).Trim() } catch {}
            }
        }
        if (-not $reg -or ($reg -ne "RU" -and $reg -ne "EU")) { $reg = "EU" }
        Check-GINAgentUpdate -currentVer "v030" -activeRegion $reg
        [System.Environment]::Exit(0)
    }

    # ==========================================================================
    # MODE 0: UNINSTALLATION
    # ==========================================================================
    if ($mode -eq "UNINSTALL") {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Red
        Write-Host "           GIN-AGENT - COMPLETE SYSTEM UNINSTALLATION               " -ForegroundColor Yellow
        Write-Host "====================================================================" -ForegroundColor Red
        Write-Host "[*] Stopping and removing GIN-Agent services and scheduled tasks..." -ForegroundColor Cyan

        $tasks = @("GIN-Agent-Service", "GIN-Agent-Update-Logon", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
        foreach ($t in $tasks) {
            try { schtasks.exe /end /tn "$t" 2>&1 | Out-Null } catch {}
            try { schtasks.exe /delete /tn "$t" /f 2>&1 | Out-Null } catch {}
        }

        $services = @("GIN-Agent", "GIN-Agent-Service", "GIN_Agent")
        foreach ($s in $services) {
            try { & sc.exe stop $s 2>&1 | Out-Null } catch {}
            try { & sc.exe delete $s 2>&1 | Out-Null } catch {}
        }

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
                    $_.CommandLine -like "*agent-api*"
                )
            } | ForEach-Object {
                try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
            }
        } catch {}

        Start-Sleep -Milliseconds 600

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

        $scriptPath = $MyInvocation.MyCommand.Path
        if (-not $scriptPath) { $scriptPath = "$installDir\GIN-Agent.cmd" }
        $parentFolder = Split-Path -Parent $scriptPath

        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host "  [OK] GIN-AGENT HAS BEEN COMPLETELY AND CLEANLY REMOVED!           " -ForegroundColor Green
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host ""

        if ($parentFolder -and (Test-Path $parentFolder)) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c ping 127.0.0.1 -n 3 >nul & rd /s /q `"`"$parentFolder`"`"" -WindowStyle Hidden
        }

        Start-Sleep -Seconds 2
        exit 0
    }

    # ==========================================================================
    # MODE 1: INSTALLER (Interactive / Silent Deployment)
    # ==========================================================================
    if ($mode -ne "SERVICE") {
        $isSilent = ($env:GIN_AGENT_SILENT -eq "1")

        if (-not $isSilent) {
            Write-Host ""
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "         GIN-AGENT v030 - REGION / GATEWAY SELECTION               " -ForegroundColor Cyan
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "  [1] Europe (Server_222 / Global)   [Default in 5 sec]" -ForegroundColor Green
            Write-Host "  [2] Russia  (Server 109 FirstVDS)" -ForegroundColor Yellow
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
        }

        $selectedRegion = $env:GIN_AGENT_REGION
        if (-not $selectedRegion) {
            $regFilePrev = "$installDir\region.txt"
            $oldRegFile = "$env:ProgramData\GIN-Agent\region.txt"
            if (Test-Path $regFilePrev) {
                try { $selectedRegion = (Get-Content -Path $regFilePrev -Raw -ErrorAction SilentlyContinue).Trim() } catch {}
            } elseif (Test-Path $oldRegFile) {
                try { $selectedRegion = (Get-Content -Path $oldRegFile -Raw -ErrorAction SilentlyContinue).Trim() } catch {}
            }
        }

        if (-not $selectedRegion -and -not $isSilent) {
            $selectedRegion = "EU"
            $secondsLeft = 1
            try {
                while ($secondsLeft -gt 0) {
                    Write-Host -NoNewline "`r[*] Select region [1/2] (default [1] in $secondsLeft sec): "
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $keyHit = $false
                    while ($sw.ElapsedMilliseconds -lt 1000) {
                        if ([System.Console]::KeyAvailable) {
                            $key = [System.Console]::ReadKey($true)
                            if ($key.KeyChar -eq "2") {
                                $selectedRegion = "RU"
                                $keyHit = $true
                                break
                            } elseif ($key.KeyChar -eq "1" -or $key.Key -eq [System.ConsoleKey]::Enter) {
                                $selectedRegion = "EU"
                                $keyHit = $true
                                break
                            }
                        }
                        Start-Sleep -Milliseconds 50
                    }
                    if ($keyHit) { break }
                    $secondsLeft--
                }
            } catch {
                $selectedRegion = "EU"
            }
        }

        if (-not $selectedRegion) { $selectedRegion = "EU" }

        if (-not $isSilent) {
            Write-Host ""
            if ($selectedRegion -eq "RU") {
                Write-Host "[OK] Region selected: RUSSIA (Server 109 - 212.109.223.109)" -ForegroundColor Yellow
            } else {
                Write-Host "[OK] Region selected: EUROPE (Server_222 - 152.53.182.222)" -ForegroundColor Green
            }
            Write-Host ""

            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "         GIN-AGENT v030 - SYSTEM SERVICE DEPLOYMENT                " -ForegroundColor Green
            Write-Host "====================================================================" -ForegroundColor Cyan
            Write-Host "[*] Stopping and updating all previous agent versions..." -ForegroundColor Yellow
        }

        # 1. Stop and remove any legacy Windows Services (sc.exe)
        $oldServices = @("GIN-Agent", "GIN-Agent-Service", "GIN_Agent")
        foreach ($s in $oldServices) {
            try { & sc.exe stop $s 2>&1 | Out-Null } catch {}
            try { & sc.exe delete $s 2>&1 | Out-Null } catch {}
        }

        # 2. Stop and remove running scheduled task instances
        $oldTasks = @("GIN-Agent-Service", "GIN-Agent-Update-Logon", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
        foreach ($ot in $oldTasks) {
            try { schtasks.exe /end /tn "$ot" 2>&1 | Out-Null } catch {}
            try { schtasks.exe /delete /tn "$ot" /f 2>&1 | Out-Null } catch {}
        }

        # 3. Terminate previous agent processes safely (release Global Mutex)
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
                    $_.CommandLine -like "*agent-api*"
                )
            } | ForEach-Object {
                try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
            }
        } catch {}

        Start-Sleep -Milliseconds 600

        # 4. Clean up legacy ProgramData folder
        $legacyDir = "$env:ProgramData\GIN-Agent"
        if (Test-Path $legacyDir) {
            try {
                Get-ChildItem -Path $legacyDir -File -ErrorAction SilentlyContinue | ForEach-Object {
                    try { $_.IsReadOnly = $false; Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
                }
                Remove-Item -Path $legacyDir -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }

        # 5. Create Program Files directory
        if (-not (Test-Path $installDir)) {
            New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # 6. Save region configuration
        [System.IO.File]::WriteAllText("$installDir\region.txt", $selectedRegion, [System.Text.Encoding]::UTF8)

        # 7. Copy single CMD file to installation target
        $sourceScript = $env:GIN_AGENT_SCRIPT
        if (-not $sourceScript -or (-not (Test-Path $sourceScript))) {
            $sourceScript = $MyInvocation.MyCommand.Path
        }

        if ($sourceScript -and (Test-Path $sourceScript)) {
            try {
                Copy-Item -Path $sourceScript -Destination $targetCmd -Force -ErrorAction Stop
            } catch {
                try {
                    [System.IO.File]::WriteAllBytes($targetCmd, [System.IO.File]::ReadAllBytes($sourceScript))
                } catch {}
            }
            try { Copy-Item -Path $sourceScript -Destination $targetCmdVer -Force -ErrorAction SilentlyContinue } catch {}
        } else {
            if ($raw) {
                try { [System.IO.File]::WriteAllText($targetCmd, $raw, [System.Text.Encoding]::UTF8) } catch {}
                try { [System.IO.File]::WriteAllText($targetCmdVer, $raw, [System.Text.Encoding]::UTF8) } catch {}
            }
        }

        # 8. Deploy uninstaller script using clean Base64 (zero syntax clashes)
        $uninstallerB64 = "PCMgOg0KQGVjaG8gb2ZmDQpzZXRsb2NhbCBEaXNhYmxlRGVsYXllZEV4cGFuc2lvbg0KdGl0bGUgR0lOLUFnZW50IFVuaW5zdGFsbGVyDQoNCjo6IEVsZXZhdGlvbiBjaGVjaw0KbmV0IHNlc3Npb24gPm51bCAyPiYxDQppZiAlZXJyb3JsZXZlbCUgZXF1IDAgZ290byA6UlVOX1VOSU5TVEFMTA0KDQpwb3dlcnNoZWxsLmV4ZSAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICJ0cnkgeyBTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAnJX5mMCcgLVZlcmIgUnVuQXMgLUVycm9yQWN0aW9uIFN0b3A7IGV4aXQgMCB9IGNhdGNoIHsgZXhpdCAxIH0iID5udWwgMj4mMQ0KZXhpdCAvYiAlZXJyb3JsZXZlbCUNCg0KOlJVTl9VTklOU1RBTEwNCnNldCAiUFNfRVhFPXBvd2Vyc2hlbGwuZXhlIg0KaWYgZXhpc3QgIiVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSIgKA0KICAgIHNldCAiUFNfRVhFPSVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikgZWxzZSBpZiBleGlzdCAiJVN5c3RlbVJvb3QlXFN5c3RlbTMyXFdpbmRvd3NQb3dlclNoZWxsXHYxLjBccG93ZXJzaGVsbC5leGUiICgNCiAgICBzZXQgIlBTX0VYRT0lU3lzdGVtUm9vdCVcU3lzdGVtMzJcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikNCg0KIiVQU19FWEUlIiAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICIkcmF3ID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbFRleHQoJyV+ZjAnLCBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4KTsgJiAoW1NjcmlwdEJsb2NrXTo6Q3JlYXRlKCRyYXcpKSINCnNldCAiUFNfRVJSPSVlcnJvcmxldmVsJSINCmV4aXQgL2IgJVBTX0VSUiUNCiM+DQp0cnkgew0KICAgIFtDb25zb2xlXTo6T3V0cHV0RW5jb2RpbmcgPSBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4DQogICAgJE91dHB1dEVuY29kaW5nID0gW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6VVRGOA0KfSBjYXRjaCB7fQ0KDQpXcml0ZS1Ib3N0ICIiDQpXcml0ZS1Ib3N0ICI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIgLUZvcmVncm91bmRDb2xvciBSZWQNCldyaXRlLUhvc3QgIiAgICAgICAgICAgR0lOLUFHRU5UIC0gQ09NUExFVEUgU1lTVEVNIFVOSU5TVEFMTEFUSU9OICAgICAgICAgICAgICAgIiAtRm9yZWdyb3VuZENvbG9yIFllbGxvdw0KV3JpdGUtSG9zdCAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iIC1Gb3JlZ3JvdW5kQ29sb3IgUmVkDQpXcml0ZS1Ib3N0ICJbKl0gU3RvcHBpbmcgYW5kIHJlbW92aW5nIEdJTi1BZ2VudCBzZXJ2aWNlcyBhbmQgc2NoZWR1bGVkIHRhc2tzLi4uIiAtRm9yZWdyb3VuZENvbG9yIEN5YW4NCg0KIyAxLiBTdG9wIGFuZCByZW1vdmUgc2NoZWR1bGVkIHRhc2tzDQokdGFza3MgPSBAKCJHSU4tQWdlbnQtU2VydmljZSIsICJHSU4tQWdlbnQiLCAiR0lOLUFnZW50LVdhdGNoZG9nIiwgIkdJTi1BZ2VudC1VcGRhdGVyIiwgIkdJTi1BZ2VudC1VcGRhdGUtTG9nb24iLCAiR0lOLVJlbW90ZSIpDQpmb3JlYWNoICgkdCBpbiAkdGFza3MpIHsNCiAgICB0cnkgeyBzY2h0YXNrcy5leGUgL2VuZCAvdG4gIiR0IiAyPiYxIHwgT3V0LU51bGwgfSBjYXRjaCB7fQ0KICAgIHRyeSB7IHNjaHRhc2tzLmV4ZSAvZGVsZXRlIC90biAiJHQiIC9mIDI+JjEgfCBPdXQtTnVsbCB9IGNhdGNoIHt9DQp9DQoNCiMgMi4gU3RvcCBhbmQgcmVtb3ZlIGxlZ2FjeSBXaW5kb3dzIFNlcnZpY2VzDQokc2VydmljZXMgPSBAKCJHSU4tQWdlbnQiLCAiR0lOLUFnZW50LVNlcnZpY2UiLCAiR0lOX0FnZW50IikNCmZvcmVhY2ggKCRzIGluICRzZXJ2aWNlcykgew0KICAgIHRyeSB7ICYgc2MuZXhlIHN0b3AgJHMgMj4mMSB8IE91dC1OdWxsIH0gY2F0Y2gge30NCiAgICB0cnkgeyAmIHNjLmV4ZSBkZWxldGUgJHMgMj4mMSB8IE91dC1OdWxsIH0gY2F0Y2gge30NCn0NCg0KIyAzLiBUZXJtaW5hdGUgcnVubmluZyBhZ2VudCBwcm9jZXNzZXMgc2FmZWx5DQokY3VycmVudFBpZCA9ICRQSUQNCiRwYXJlbnRQaWQgPSAwDQp0cnkgew0KICAgICRwYXJlbnRQcm9jID0gR2V0LUNpbUluc3RhbmNlIFdpbjMyX1Byb2Nlc3MgLUZpbHRlciAiUHJvY2Vzc0lkID0gJGN1cnJlbnRQaWQiIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgaWYgKCRwYXJlbnRQcm9jKSB7ICRwYXJlbnRQaWQgPSAkcGFyZW50UHJvYy5QYXJlbnRQcm9jZXNzSWQgfQ0KfSBjYXRjaCB7fQ0KDQp0cnkgew0KICAgIEdldC1DaW1JbnN0YW5jZSBXaW4zMl9Qcm9jZXNzIC1GaWx0ZXIgIk5hbWUgPSAncG93ZXJzaGVsbC5leGUnIG9yIE5hbWUgPSAnY21kLmV4ZSciIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgV2hlcmUtT2JqZWN0IHsNCiAgICAgICAgJF8uUHJvY2Vzc0lkIC1uZSAkY3VycmVudFBpZCAtYW5kICRfLlByb2Nlc3NJZCAtbmUgJHBhcmVudFBpZCAtYW5kICgNCiAgICAgICAgICAgICRfLkNvbW1hbmRMaW5lIC1saWtlICIqR0lOLUFnZW50KiIgLW9yDQogICAgICAgICAgICAkXy5Db21tYW5kTGluZSAtbGlrZSAiKmFnZW50LWFwaSoiDQogICAgICAgICkNCiAgICB9IHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICB0cnkgeyBTdG9wLVByb2Nlc3MgLUlkICRfLlByb2Nlc3NJZCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfSBjYXRjaCB7fQ0KICAgIH0NCn0gY2F0Y2gge30NCg0KU3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyA2MDANCg0KIyA0LiBSZW1vdmUgV2luZG93cyBSZWdpc3RyeSBlbnRyaWVzDQpXcml0ZS1Ib3N0ICJbKl0gUmVtb3ZpbmcgcmVnaXN0cnkgZW50cmllcy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQokcmVnUGF0aHMgPSBAKA0KICAgICJIS0xNOlxTT0ZUV0FSRVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxVbmluc3RhbGxcR0lOLUFnZW50IiwNCiAgICAiSEtMTTpcU09GVFdBUkVcR0lOLUFnZW50Ig0KKQ0KZm9yZWFjaCAoJHJwIGluICRyZWdQYXRocykgew0KICAgIGlmIChUZXN0LVBhdGggJHJwKSB7DQogICAgICAgIHRyeSB7IFJlbW92ZS1JdGVtIC1QYXRoICRycCAtUmVjdXJzZSAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfSBjYXRjaCB7fQ0KICAgIH0NCn0NCg0KIyA1LiBDbGVhbiB1cCBkaXJlY3Rvcmllcw0KV3JpdGUtSG9zdCAiWypdIFJlbW92aW5nIEdJTi1BZ2VudCBmaWxlcyBhbmQgZGlyZWN0b3JpZXMuLi4iIC1Gb3JlZ3JvdW5kQ29sb3IgQ3lhbg0KJGRpcnNUb1B1cmdlID0gQCgNCiAgICAiJGVudjpQcm9ncmFtRGF0YVxHSU4tQWdlbnQiLA0KICAgICIkZW52OlByb2dyYW1GaWxlc1xHSU4tQWdlbnQiLA0KICAgICIke2VudjpQcm9ncmFtRmlsZXMoeDg2KX1cR0lOLUFnZW50Ig0KKQ0KZm9yZWFjaCAoJGQgaW4gJGRpcnNUb1B1cmdlKSB7DQogICAgaWYgKFRlc3QtUGF0aCAkZCkgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgR2V0LUNoaWxkSXRlbSAtUGF0aCAkZCAtRmlsZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZSB8IEZvckVhY2gtT2JqZWN0IHsNCiAgICAgICAgICAgICAgICBpZiAoJF8uRnVsbE5hbWUgLW5lICRNeUludm9jYXRpb24uTXlDb21tYW5kLlBhdGgpIHsNCiAgICAgICAgICAgICAgICAgICAgdHJ5IHsgJF8uSXNSZWFkT25seSA9ICRmYWxzZTsgUmVtb3ZlLUl0ZW0gLVBhdGggJF8uRnVsbE5hbWUgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIH0gY2F0Y2gge30NCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICB9DQogICAgICAgIH0gY2F0Y2gge30NCiAgICB9DQp9DQoNCiMgNi4gRGV0YWNoZWQgc2VsZi1jbGVhbnVwIGZvciByZW1haW5pbmcgZm9sZGVyDQokc2NyaXB0UGF0aCA9ICRNeUludm9jYXRpb24uTXlDb21tYW5kLlBhdGgNCmlmICgtbm90ICRzY3JpcHRQYXRoKSB7ICRzY3JpcHRQYXRoID0gIiRlbnY6UHJvZ3JhbUZpbGVzXEdJTi1BZ2VudFx1bmluc3RhbGwuY21kIiB9DQokcGFyZW50Rm9sZGVyID0gU3BsaXQtUGF0aCAtUGFyZW50ICRzY3JpcHRQYXRoDQoNCldyaXRlLUhvc3QgIiINCldyaXRlLUhvc3QgIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQpXcml0ZS1Ib3N0ICIgIFtPS10gR0lOLUFHRU5UIEhBUyBCRUVOIENPTVBMRVRFTFkgQU5EIENMRUFOTFkgUkVNT1ZFRCEgICAgICAgICAgICIgLUZvcmVncm91bmRDb2xvciBHcmVlbg0KV3JpdGUtSG9zdCAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iIC1Gb3JlZ3JvdW5kQ29sb3IgR3JlZW4NCldyaXRlLUhvc3QgIiINCg0KIyBTcGF3biBkZXRhY2hlZCBjbWQgdG8gcmVtb3ZlIHRoZSBmb2xkZXIgaXRzZWxmIGFmdGVyIGV4aXQNCmlmICgkcGFyZW50Rm9sZGVyIC1hbmQgKFRlc3QtUGF0aCAkcGFyZW50Rm9sZGVyKSkgew0KICAgIFN0YXJ0LVByb2Nlc3MgLUZpbGVQYXRoICJjbWQuZXhlIiAtQXJndW1lbnRMaXN0ICIvYyBwaW5nIDEyNy4wLjAuMSAtbiAzID5udWwgJiByZCAvcyAvcSBgImAiJHBhcmVudEZvbGRlcmAiYCIiIC1XaW5kb3dTdHlsZSBIaWRkZW4NCn0NCg0KU3RhcnQtU2xlZXAgLVNlY29uZHMgMg0KZXhpdCAwDQo="
        [System.IO.File]::WriteAllBytes($uninstallerCmd, [System.Convert]::FromBase64String($uninstallerB64))

        # 9. Register in Windows Installed Apps (Add/Remove Programs)
        try {
            $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent"
            if (-not (Test-Path $uninstallKey)) { New-Item -Path $uninstallKey -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayName" -Value "GIN-Agent Remote Support" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayVersion" -Value "v030" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "Publisher" -Value "VladiMIR+AI" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "InstallLocation" -Value $installDir -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "UninstallString" -Value "`"$uninstallerCmd`"" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "QuietUninstallString" -Value "`"$uninstallerCmd`"" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "NoModify" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "NoRepair" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } catch {}

        # 10. Register Native Windows Scheduled Service Host (HIGHEST Privileges, ONSTART)
        if (-not $isSilent) {
            Write-Host "[*] Registering permanent SYSTEM background service ($selectedRegion)..." -ForegroundColor Cyan
        }

        $taskName = "GIN-Agent-Service"
        schtasks.exe /delete /tn "$taskName" /f 2>&1 | Out-Null
        $svcAction = "cmd.exe /c `"`"$targetCmd`" /service $selectedRegion`""
        schtasks.exe /create /tn "$taskName" /tr $svcAction /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null
        try {
            $svcSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
            Set-ScheduledTask -TaskName "$taskName" -Settings $svcSettings -ErrorAction SilentlyContinue | Out-Null
        } catch {}
        schtasks.exe /run /tn "$taskName" 2>&1 | Out-Null

        # Watchdog Task: fires every 5 minutes, restarts agent if dead
        $watchdogName = "GIN-Agent-Watchdog"
        schtasks.exe /delete /tn "$watchdogName" /f 2>&1 | Out-Null
        $wdAction = "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -Command `"if (-not (Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { `$_.CommandLine -like '*GIN-Agent*' })) { Start-Process -FilePath '$targetCmd' -ArgumentList '/service $selectedRegion' -WindowStyle Hidden }`""
        schtasks.exe /create /tn "$watchdogName" /tr $wdAction /sc MINUTE /mo 5 /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null
        try {
            $wdSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0)
            Set-ScheduledTask -TaskName "$watchdogName" -Settings $wdSettings -ErrorAction SilentlyContinue | Out-Null
        } catch {}

        # Scheduled Auto-Update Task on User Logon (+30 minutes delay)
        $logonTaskName = "GIN-Agent-Update-Logon"
        schtasks.exe /delete /tn "$logonTaskName" /f 2>&1 | Out-Null
        $logonAction = "cmd.exe /c `"`"$targetCmd`" /checkupdate $selectedRegion`""
        schtasks.exe /create /tn "$logonTaskName" /tr $logonAction /sc ONLOGON /delay 0030:00 /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null

        $serviceStarted = $false
        for ($w = 0; $w -lt 6; $w++) {
            Start-Sleep -Milliseconds 500
            $runningProc = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                    $_.CommandLine -like "*$targetCmd*" -or
                    $_.CommandLine -like "*GIN-Agent.cmd*"
                )
            }
            if ($runningProc) {
                $serviceStarted = $true
                break
            }
        }

        if (-not $serviceStarted) {
            try {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"`"$targetCmd`" /service $selectedRegion`"" -WindowStyle Hidden
            } catch {}
        }

        if (-not $isSilent) {
            $regDesc = if ($selectedRegion -eq "RU") { "RUSSIA (Server 109: 212.109.223.109)" } else { "EUROPE (Server_222: 152.53.182.222)" }
            Write-Host ""
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [+] GIN-Agent v030 deployed cleanly in Program Files!" -ForegroundColor Green
            Write-Host "  [+] Location: $installDir" -ForegroundColor White
            Write-Host "  [+] Uninstaller: $uninstallerCmd" -ForegroundColor White
            Write-Host "  [+] Active region: $regDesc" -ForegroundColor Cyan
            Write-Host "  [+] Auto-Update: enabled (Dual-channel: RU-109 / GitHub)" -ForegroundColor Green
            Write-Host "  [+] Tasks: GIN-Agent-Service (Auto-start on OS boot) + GIN-Agent-Watchdog (5-min watchdog)" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "====================================================================" -ForegroundColor Green
            Write-Host "  [OK] INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
            Write-Host "====================================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "[*] Deployment finished. Window closing automatically..." -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 600
        }
        [System.Environment]::Exit(0)
    }

    # ==========================================================================
    # MODE 2: SERVICE WORKER (Background execution loop)
    # ==========================================================================
    $token = "GinCz-Remote-2026"
    $headers = @{ "Token" = $token; "X-Host" = $env:COMPUTERNAME }

    # Singleton Mutex to prevent duplicate service instances
    $createdNew = $false
    try {
        $mutex = New-Object System.Threading.Mutex($true, "Global\GIN_Agent_Core_Mutex", [ref]$createdNew)
    } catch [System.Threading.AbandonedMutexException] {
        $createdNew = $true
    }
    if (-not $createdNew) { exit 0 }
    $global:agentMutex = $mutex

    # Determine Active Region (Command parameter > region.txt > default EU)
    $region = $env:GIN_AGENT_REGION
    if (-not $region -or ($region -ne "RU" -and $region -ne "EU")) {
        $regFile = "$installDir\region.txt"
        if (Test-Path $regFile) {
            try {
                $saved = (Get-Content -Path $regFile -Raw -ErrorAction SilentlyContinue).Trim()
                if ($saved -eq "RU" -or $saved -eq "EU") { $region = $saved }
            } catch {}
        }
    }
    if ($region -ne "RU") { $region = "EU" }

    # Resilient Regional Gateways
    if ($region -eq "RU") {
        $gateways = @(
            @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" },
            @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
            @{ Name = "Europe (Server_222)"; Url = "http://152.53.182.222:9876" },
            @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" }
        )
    } else {
        $gateways = @(
            @{ Name = "Europe (Server_222)"; Url = "http://152.53.182.222:9876" },
            @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
            @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" },
            @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" }
        )
    }

    $serverUrl = ""
    $activeGatewayName = ""
    foreach ($gw in $gateways) {
        try {
            $resp = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
            if ($resp) {
                $serverUrl = $gw.Url
                $activeGatewayName = $gw.Name
                break
            }
        } catch {}
    }
    if (-not $serverUrl) {
        if ($region -eq "RU") {
            $serverUrl = "http://212.109.223.109/agent-api"
            $activeGatewayName = "RU-109 Fallback"
        } else {
            $serverUrl = "http://152.53.182.222:9876"
            $activeGatewayName = "Server_222 Fallback"
        }
    }

    # Ensure RDP & Shadow Policy
    try {
        $null = Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force -ErrorAction SilentlyContinue
        $tsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        if (-not (Test-Path $tsPolicy)) { New-Item -Path $tsPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
        $null = Set-ItemProperty -Path $tsPolicy -Name "Shadow" -Value 2 -Force -ErrorAction SilentlyContinue
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Out-Null
    } catch {}

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

    $headers["X-Pin"] = $pin

    # ULTARIX Policy: Enforce RustDesk unattended password 'Ultarix-22'
    try {
        if ($env:COMPUTERNAME -match '^(ULTARIX|U-\d|ULPS)' -or (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).Workgroup -match 'ULTARIX') {
            $rdExe = @(
                "$env:ProgramFiles\RustDesk\RustDesk.exe",
                "${env:ProgramFiles(x86)}\RustDesk\RustDesk.exe",
                "C:\Program Files\RustDesk\rustdesk.exe"
            ) | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($rdExe) {
                $p = Start-Process -FilePath $rdExe -ArgumentList "--password", "Ultarix-22" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                if ($p) { $p.WaitForExit(5000) }
                Start-Sleep -Seconds 1
                $src = "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
                Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    $dst = "$($_.FullName)\AppData\Roaming\RustDesk\config"
                    if (Test-Path $dst) {
                        Copy-Item "$src\RustDesk*.toml" -Destination $dst -Force -ErrorAction SilentlyContinue
                    }
                }
                Restart-Service RustDesk -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # Detect RustDesk ID
    $rustdeskId = ""
    $rdBin = @(
        "$env:ProgramFiles\RustDesk\RustDesk.exe",
        "${env:ProgramFiles(x86)}\RustDesk\RustDesk.exe",
        "C:\Program Files\RustDesk\rustdesk.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($rdBin) {
        try {
            $tempIdFile = "$env:TEMP\rd_id_probe.txt"
            $p = Start-Process -FilePath $rdBin -ArgumentList "--get-id" -RedirectStandardOutput $tempIdFile -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
            if ($p) { $p.WaitForExit(3000) }
            if (Test-Path $tempIdFile) {
                $probeId = (Get-Content -Path $tempIdFile -Raw -ErrorAction SilentlyContinue).Trim()
                if ($probeId -match '^\d{6,12}$') { $rustdeskId = $probeId }
                Remove-Item -Path $tempIdFile -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    if (-not $rustdeskId) {
        $rdPaths = @(
            "$env:APPDATA\RustDesk\config\RustDesk.toml",
            "$env:APPDATA\RustDesk\config\rustdesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\rustdesk.toml"
        )
        foreach ($cp in $rdPaths) {
            if (Test-Path $cp) {
                $c = Get-Content -Path $cp -Raw -ErrorAction SilentlyContinue
                if ($c -match '(?m)^\s*id\s*=\s*["\x27]?(\d{6,12})["\x27]?') {
                    $rustdeskId = $matches[1]
                    break
                }
            }
        }
    }

    # Telemetry
    $arch = if ([IntPtr]::Size -eq 8) { "64-bit" } else { "32-bit" }
    $osName = "Microsoft Windows ($arch)"
    $cpuName = "N/A"
    $ramStr = "N/A"
    $diskStr = "N/A"
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($osInfo) { $osName = "$($osInfo.Caption) ($arch)" }
        $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpuObj) { $cpuName = $cpuObj.Name.Trim() }
        if ($osInfo) {
            $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
            $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
            $totRam = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            $ramStr = "$freeRam GB free / $totRam GB total"
        }
        $drive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($drive) {
            $freeGb = [math]::Round($drive.Free / 1GB, 1)
            $totGb = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
            $diskStr = "C: $freeGb GB free / $totGb GB total"
        }
    } catch {}

    # Registration & Telegram Alert Suppression Check
    $tagFile = "$installDir\registered.tag"
    $isFirstRegistration = -not (Test-Path $tagFile)

    try {
        $regPayload = @{
            pin             = $pin
            host            = $env:COMPUTERNAME
            user            = $env:USERNAME
            admin           = $true
            os              = $osName
            cpu             = $cpuName
            ram             = $ramStr
            disk            = $diskStr
            rustdesk_id     = $rustdeskId
            rdp_ready       = $true
            region          = $region
            gateway         = $activeGatewayName
            version         = "v030"
            first_connect   = $isFirstRegistration
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
        if ($isFirstRegistration) {
            [System.IO.File]::WriteAllText($tagFile, (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), [System.Text.Encoding]::UTF8)
        }
    } catch {}

    # Global scope variables for bulletproof background heartbeat timer
    $global:hbServerUrl = $serverUrl
    $global:hbHeaders = $headers
    $global:hbPin = $pin
    $global:hbRustdeskId = $rustdeskId
    $global:hbActiveGatewayName = $activeGatewayName
    $global:hbRegion = $region

    # BACKGROUND HEARTBEAT TIMER (ThreadPool execution, active during long commands)
    $hbTimer = New-Object System.Timers.Timer
    $hbTimer.Interval = 30000  # 30 seconds
    $hbTimer.AutoReset = $true

    $hbAction = {
        try {
            $targetPin = if ($global:hbPin) { $global:hbPin } else { $pin }
            $targetRd = if ($global:hbRustdeskId) { $global:hbRustdeskId } else { $rustdeskId }
            $targetGw = if ($global:hbActiveGatewayName) { $global:hbActiveGatewayName } else { $activeGatewayName }
            $targetReg = if ($global:hbRegion) { $global:hbRegion } else { $region }
            if ($targetPin) {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$targetPin&v=v030&rd_id=$targetRd&gw=$([System.Uri]::EscapeDataString($targetGw))&region=$targetReg"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
        try {
            $targetServer = if ($global:hbServerUrl) { $global:hbServerUrl } else { $serverUrl }
            $targetHdr = if ($global:hbHeaders) { $global:hbHeaders } else { $headers }
            $targetPin = if ($global:hbPin) { $global:hbPin } else { $pin }
            $targetReg = if ($global:hbRegion) { $global:hbRegion } else { $region }
            if ($targetServer -and $targetPin) {
                $reRegPayload = @{ pin = $targetPin; host = $env:COMPUTERNAME; region = $targetReg; version = "v030" } | ConvertTo-Json
                Invoke-RestMethod -Uri "$targetServer/register" -Method Post -Headers $targetHdr -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
    }

    Register-ObjectEvent -InputObject $hbTimer -EventName Elapsed -Action $hbAction | Out-Null
    $hbTimer.Start()

    # Background Polling Loop (with direct KeepAlive guaranteed every ~25s)
    $updateCheckCounter = 0
    $consecutiveErrors = 0
    $loopCount = 0

    while ($true) {
        try {
            $pollUrl = "$serverUrl/poll?h=$([System.Uri]::EscapeDataString($env:COMPUTERNAME))&pin=$pin"
            $resp = Invoke-RestMethod -Uri $pollUrl -Method Get -Headers $headers -TimeoutSec 15 -ErrorAction Stop
            $consecutiveErrors = 0  # reset on success
            if ($resp -and $resp.command) {
                $cmdId = $resp.id
                $cmdText = $resp.command
                $out = ""
                try {
                    # Isolated execution: command runs in separate Job, never blocks main loop permanently
                    $job = Start-Job -ScriptBlock ([ScriptBlock]::Create($cmdText))
                    $completed = Wait-Job $job -Timeout 90
                    if ($completed) {
                        $out = Receive-Job $job 2>&1 | Out-String
                    } else {
                        Stop-Job $job -ErrorAction SilentlyContinue
                        $out = "[ERROR: Command timed out after 90 seconds - agent stayed online]"
                    }
                    Remove-Job $job -Force -ErrorAction SilentlyContinue
                } catch {
                    $out = "EXEC ERROR: $($_.Exception.Message)"
                }
                if (-not $out -or $out.Trim() -eq "") { $out = "[OK: Command completed with no output]" }
                $bodyObj = @{ id = $cmdId; host = $env:COMPUTERNAME; output = $out } | ConvertTo-Json
                Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $bodyObj -TimeoutSec 10 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            $consecutiveErrors++
            if ($consecutiveErrors -ge 3) {
                # Network recovery: re-probe gateways and re-register
                $consecutiveErrors = 0
                try {
                    foreach ($gw in $gateways) {
                        try {
                            $resp2 = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
                            if ($resp2) {
                                $serverUrl = $gw.Url
                                $activeGatewayName = $gw.Name
                                $global:hbServerUrl = $serverUrl
                                $global:hbActiveGatewayName = $activeGatewayName
                                break
                            }
                        } catch {}
                    }
                    $reRegPayload = @{ pin = $pin; host = $env:COMPUTERNAME; region = $region; version = "v030" } | ConvertTo-Json
                    Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
                } catch {}
                Start-Sleep -Seconds 10
            } else {
                Start-Sleep -Seconds 2
            }
        }

        # Direct KeepAlive to rd.gincz.com every ~25 seconds (Guaranteed delivery)
        $loopCount++
        if ($loopCount -ge 5) {
            $loopCount = 0
            try {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v030&rd_id=$rustdeskId&gw=$([System.Uri]::EscapeDataString($activeGatewayName))&region=$region"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
            try {
                $reRegPayload = @{ pin = $pin; host = $env:COMPUTERNAME; region = $region; version = "v030" } | ConvertTo-Json
                Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $reRegPayload -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }

        # Auto-Update Check: Initial check after 4 loops (~20s), then every 4320 loops (~6 hours)
        $updateCheckCounter++
        if ($updateCheckCounter -eq 4 -or $updateCheckCounter -ge 4320) {
            if ($updateCheckCounter -ge 4320) { $updateCheckCounter = 5 }
            Check-GINAgentUpdate -currentVer "v030" -activeRegion $region
        }

        Start-Sleep -Seconds 5
    }

} catch {
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host "  [!] CRITICAL ERROR GIN-AGENT v030:" -ForegroundColor Red
    Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Line:    $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}
