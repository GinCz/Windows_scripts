<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent v027

:: If launched with /service or --service in background
if /i "%~1"=="/service" goto :RUN_SERVICE
if /i "%~1"=="--service" goto :RUN_SERVICE

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
# GIN-Agent Windows Service v027 (Single File CMD Hybrid)
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Permanent Background Windows Service (Auto-Start, Watchdog Recovery, No Console Window)
# Primary Identifier: 9-Digit Hardware GIN-PIN
# Supported Platforms: Windows 10 (32-bit & 64-bit), Windows 11 (64-bit / ARM64)
# Regional Gateways:
#   - Europe: Server_222 (152.53.182.222:9876), Global (remote.gincz.com)
#   - Russia: Server_109 (212.109.223.109), RU-FastNode (195.158.255.208)
# Key v027 Additions:
#   1. Standard Program Files Installation: C:\Program Files\GIN-Agent
#   2. Full Turnkey Uninstaller: C:\Program Files\GIN-Agent\uninstall.cmd
#      Registered in Windows Installed Apps (Control Panel / Add-Remove Programs)
#   3. Autonomous Auto-Update Engine: Dual source (RU-109 for Russia, GitHub for Global)
#   4. Double Telegram Alert Suppression: Local tag & Server-side persistent deduplication
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
    $targetCmdV27 = "$installDir\GIN-Agent_Windows_v027.cmd"
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

    # ==========================================================================
    # MODE 0: UNINSTALLATION
    # ==========================================================================
    if ($mode -eq "UNINSTALL") {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Red
        Write-Host "           GIN-AGENT - COMPLETE SYSTEM UNINSTALLATION               " -ForegroundColor Yellow
        Write-Host "====================================================================" -ForegroundColor Red
        Write-Host "[*] Stopping and removing GIN-Agent services and scheduled tasks..." -ForegroundColor Cyan

        $tasks = @("GIN-Agent-Service", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
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
                    $_.CommandLine -like "*GIN-Agent* /service*" -or
                    $_.CommandLine -like "*Global\GIN_Agent_Core_Mutex*"
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
            Write-Host "         GIN-AGENT v027 - REGION / GATEWAY SELECTION               " -ForegroundColor Cyan
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
            Write-Host "         GIN-AGENT v027 - SYSTEM SERVICE DEPLOYMENT                " -ForegroundColor Green
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
        $oldTasks = @("GIN-Agent-Service", "GIN-Agent", "GIN-Agent-Watchdog", "GIN-Agent-Updater", "GIN-Remote")
        foreach ($ot in $oldTasks) {
            try { schtasks.exe /end /tn $ot 2>&1 | Out-Null } catch {}
            try { schtasks.exe /delete /tn $ot /f 2>&1 | Out-Null } catch {}
        }

        # 3. Terminate previous agent processes safely
        $currentPid = $PID
        $parentPid = 0
        try {
            $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
            if ($parentProc) { $parentPid = $parentProc.ParentProcessId }
        } catch {}

        try {
            Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' or Name = 'cmd.exe'" -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                    $_.CommandLine -like "*GIN-Agent* /service*" -or
                    $_.CommandLine -like "*Global\GIN_Agent_Core_Mutex*"
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
            try { Copy-Item -Path $sourceScript -Destination $targetCmdV27 -Force -ErrorAction SilentlyContinue } catch {}
        } else {
            if ($raw) {
                try { [System.IO.File]::WriteAllText($targetCmd, $raw, [System.Text.Encoding]::UTF8) } catch {}
                try { [System.IO.File]::WriteAllText($targetCmdV27, $raw, [System.Text.Encoding]::UTF8) } catch {}
            }
        }

        # 8. Deploy uninstaller script using clean Base64 (zero syntax clashes)
        $uninstallerB64 = "PCMgOg0KQGVjaG8gb2ZmDQpzZXRsb2NhbCBEaXNhYmxlRGVsYXllZEV4cGFuc2lvbg0KdGl0bGUgR0lOLUFnZW50IFVuaW5zdGFsbGVyDQoNCjo6IEVsZXZhdGlvbiBjaGVjaw0KbmV0IHNlc3Npb24gPm51bCAyPiYxDQppZiAlZXJyb3JsZXZlbCUgZXF1IDAgZ290byA6UlVOX1VOSU5TVEFMTA0KDQpwb3dlcnNoZWxsLmV4ZSAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICJ0cnkgeyBTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAnJX5mMCcgLVZlcmIgUnVuQXMgLUVycm9yQWN0aW9uIFN0b3A7IGV4aXQgMCB9IGNhdGNoIHsgZXhpdCAxIH0iID5udWwgMj4mMQ0KZXhpdCAvYiAlZXJyb3JsZXZlbCUNCg0KOlJVTl9VTklOU1RBTEwNCnNldCAiUFNfRVhFPXBvd2Vyc2hlbGwuZXhlIg0KaWYgZXhpc3QgIiVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSIgKA0KICAgIHNldCAiUFNfRVhFPSVTeXN0ZW1Sb290JVxTeXNuYXRpdmVcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikgZWxzZSBpZiBleGlzdCAiJVN5c3RlbVJvb3QlXFN5c3RlbTMyXFdpbmRvd3NQb3dlclNoZWxsXHYxLjBccG93ZXJzaGVsbC5leGUiICgNCiAgICBzZXQgIlBTX0VYRT0lU3lzdGVtUm9vdCVcU3lzdGVtMzJcV2luZG93c1Bvd2VyU2hlbGxcdjEuMFxwb3dlcnNoZWxsLmV4ZSINCikNCg0KIiVQU19FWEUlIiAtTm9Qcm9maWxlIC1FeGVjdXRpb25Qb2xpY3kgQnlwYXNzIC1Db21tYW5kICIkcmF3ID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbFRleHQoJyV+ZjAnLCBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4KTsgJiAoW1NjcmlwdEJsb2NrXTo6Q3JlYXRlKCRyYXcpKSINCnNldCAiUFNfRVJSPSVlcnJvcmxldmVsJSINCmV4aXQgL2IgJVBTX0VSUiUNCiM+DQp0cnkgew0KICAgICRFcnJvckFjdGlvblByZWZlcmVuY2UgPSAiQ29udGludWUiDQoNCiAgICB0cnkgew0KICAgICAgICBbQ29uc29sZV06Ok91dHB1dEVuY29kaW5nID0gW1N5c3RlbS5UZXh0LkVuY29kaW5nXTo6VVRGOA0KICAgICAgICAkT3V0cHV0RW5jb2RpbmcgPSBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4DQogICAgfSBjYXRjaCB7fQ0KDQogICAgV3JpdGUtSG9zdCAiIg0KICAgIFdyaXRlLUhvc3QgIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IiAtRm9yZWdyb3VuZENvbG9yIFJlZA0KICAgIFdyaXRlLUhvc3QgIiAgICAgICAgICAgR0lOLUFHRU5UIC0gQ09NUExFVEUgU1lTVEVNIFVOSU5TVEFMTEFUSU9OICAgICAgICAgICAgICAgIiAtRm9yZWdyb3VuZENvbG9yIFllbGxvdw0KICAgIFdyaXRlLUhvc3QgIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IiAtRm9yZWdyb3VuZENvbG9yIFJlZA0KICAgIFdyaXRlLUhvc3QgIiINCg0KICAgICMgSGFyZHdhcmUgR0lOLVBJTiBjYWxjdWxhdGlvbiAoRGV0ZXJtaW5pc3RpYyBXTUkpDQogICAgJHBpbiA9ICIxMDAtMDAwLTAwMSINCiAgICB0cnkgew0KICAgICAgICAkdXVpZCA9IChHZXQtQ2ltSW5zdGFuY2UgV2luMzJfQ29tcHV0ZXJTeXN0ZW1Qcm9kdWN0IC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlKS5VVUlEDQogICAgICAgICRib2FyZCA9IChHZXQtQ2ltSW5zdGFuY2UgV2luMzJfQmFzZUJvYXJkIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlKS5TZXJpYWxOdW1iZXINCiAgICAgICAgaWYgKC1ub3QgJHV1aWQpIHsgJHV1aWQgPSAkZW52OkNPTVBVVEVSTkFNRSB9DQogICAgICAgIGlmICgtbm90ICRib2FyZCkgeyAkYm9hcmQgPSAiRGVmYXVsdEJvYXJkIiB9DQogICAgICAgICRyYXdQaW4gPSAiaHdfd2luXyR7dXVpZH1fJHtib2FyZH0iDQogICAgICAgICRzaGEgPSBbU3lzdGVtLlNlY3VyaXR5LkNyeXB0b2dyYXBoeS5TSEEyNTZdOjpDcmVhdGUoKQ0KICAgICAgICAkYnl0ZXMgPSBbU3lzdGVtLlRleHQuRW5jb2RpbmddOjpVVEY4LkdldEJ5dGVzKCRyYXdQaW4pDQogICAgICAgICRkaWdlc3QgPSAkc2hhLkNvbXB1dGVIYXNoKCRieXRlcykNCiAgICAgICAgaWYgKFtCaXRDb252ZXJ0ZXJdOjpJc0xpdHRsZUVuZGlhbikgeyBbQXJyYXldOjpSZXZlcnNlKCRkaWdlc3QsIDAsIDgpIH0NCiAgICAgICAgJG51bSA9IFtNYXRoXTo6QWJzKFtCaXRDb252ZXJ0ZXJdOjpUb0ludDY0KCRkaWdlc3QsIDApKQ0KICAgICAgICAkY29kZSA9ICgkbnVtICUgOTAwMDAwMDAwKSArIDEwMDAwMDAwMA0KICAgICAgICAkZFN0ciA9ICRjb2RlLlRvU3RyaW5nKCJEOSIpDQogICAgICAgICRwaW4gPSAiJCgkZFN0ci5TdWJzdHJpbmcoMCwzKSktJCgkZFN0ci5TdWJzdHJpbmcoMywzKSktJCgkZFN0ci5TdWJzdHJpbmcoNiwzKSkiDQogICAgfSBjYXRjaCB7fQ0KDQogICAgIyBTVEVQIDE6IERlcmVnaXN0ZXIgZnJvbSByZW1vdGUgc2VydmVyIGRhc2hib2FyZHMNCiAgICBXcml0ZS1Ib3N0ICJbKl0gU3RlcCAxLzY6IERlcmVnaXN0ZXJpbmcgaG9zdCBmcm9tIHJlbW90ZSBzZXJ2ZXIgZGFzaGJvYXJkcy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQogICAgV3JpdGUtSG9zdCAiICAgIFtpXSBIb3N0OiAkZW52OkNPTVBVVEVSTkFNRSB8IEhhcmR3YXJlIFBJTjogJHBpbiIgLUZvcmVncm91bmRDb2xvciBEYXJrR3JheQ0KICAgICR1bnJlZ1BheWxvYWQgPSBAeyBwaW4gPSAkcGluOyBob3N0ID0gJGVudjpDT01QVVRFUk5BTUUgfSB8IENvbnZlcnRUby1Kc29uDQogICAgJGdhdGV3YXlzID0gQCgNCiAgICAgICAgImh0dHBzOi8vcmVtb3RlLmdpbmN6LmNvbS9hZ2VudC1hcGkiLA0KICAgICAgICAiaHR0cDovLzIxMi4xMDkuMjIzLjEwOS9hZ2VudC1hcGkiLA0KICAgICAgICAiaHR0cDovLzE1Mi41My4xODIuMjIyOjk4NzYiDQogICAgKQ0KICAgICR1bnJlZ1N1Y2Nlc3MgPSAkZmFsc2UNCiAgICBmb3JlYWNoICgkZ3cgaW4gJGdhdGV3YXlzKSB7DQogICAgICAgIHRyeSB7DQogICAgICAgICAgICAkcmVzcCA9IEludm9rZS1SZXN0TWV0aG9kIC1VcmkgIiRndy91bnJlZ2lzdGVyIiAtTWV0aG9kIFBvc3QgLUhlYWRlcnMgQHsgVG9rZW4gPSAiR2luQ3otUmVtb3RlLTIwMjYiIH0gLUNvbnRlbnRUeXBlICJhcHBsaWNhdGlvbi9qc29uOyBjaGFyc2V0PXV0Zi04IiAtQm9keSAkdW5yZWdQYXlsb2FkIC1UaW1lb3V0U2VjIDMgLUVycm9yQWN0aW9uIFN0b3ANCiAgICAgICAgICAgIGlmICgkcmVzcCkgew0KICAgICAgICAgICAgICAgIFdyaXRlLUhvc3QgIiAgICBbK10gRGVyZWdpc3RlcmVkIGZyb20gZ2F0ZXdheTogJGd3IiAtRm9yZWdyb3VuZENvbG9yIERhcmtHcmF5DQogICAgICAgICAgICAgICAgJHVucmVnU3VjY2VzcyA9ICR0cnVlDQogICAgICAgICAgICB9DQogICAgICAgIH0gY2F0Y2gge30NCiAgICB9DQogICAgdHJ5IHsNCiAgICAgICAgJHJlc3BSZCA9IEludm9rZS1SZXN0TWV0aG9kIC1VcmkgImh0dHBzOi8vcmQuZ2luY3ouY29tL2FwaS91bnJlZ2lzdGVyP3Bpbj0kcGluJmhvc3Q9JGVudjpDT01QVVRFUk5BTUUiIC1NZXRob2QgR2V0IC1UaW1lb3V0U2VjIDMgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgaWYgKCRyZXNwUmQpIHsgV3JpdGUtSG9zdCAiICAgIFsrXSBEZXJlZ2lzdGVyZWQgZnJvbSBSdXN0RGVzayByZWdpc3RyeSAocmQuZ2luY3ouY29tKSIgLUZvcmVncm91bmRDb2xvciBEYXJrR3JheSB9DQogICAgfSBjYXRjaCB7fQ0KICAgIFdyaXRlLUhvc3QgIiAgICBbT0tdIFJlbW90ZSBzZXJ2ZXIgZGFzaGJvYXJkIHN0YXR1czogY2xlYXJlZCAob2ZmbGluZS91bmluc3RhbGxlZCkuIiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQoNCiAgICAjIFNURVAgMjogU3RvcCBhbmQgZGVsZXRlIHNjaGVkdWxlZCB0YXNrcw0KICAgIFdyaXRlLUhvc3QgIlsqXSBTdGVwIDIvNjogU3RvcHBpbmcgYW5kIHJlbW92aW5nIFdpbmRvd3MgU2NoZWR1bGVkIFRhc2tzLi4uIiAtRm9yZWdyb3VuZENvbG9yIEN5YW4NCiAgICAkdGFza3MgPSBAKCJHSU4tQWdlbnQtU2VydmljZSIsICJHSU4tQWdlbnQiLCAiR0lOLUFnZW50LVdhdGNoZG9nIiwgIkdJTi1BZ2VudC1VcGRhdGVyIiwgIkdJTi1SZW1vdGUiKQ0KICAgIGZvcmVhY2ggKCR0IGluICR0YXNrcykgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgJHRhc2tJbmZvID0gc2NodGFza3MuZXhlIC9xdWVyeSAvdG4gIiR0IiAyPiYxDQogICAgICAgICAgICBpZiAoJExBU1RFWElUQ09ERSAtZXEgMCkgew0KICAgICAgICAgICAgICAgIHNjaHRhc2tzLmV4ZSAvZW5kIC90biAiJHQiIDI+JjEgfCBPdXQtTnVsbA0KICAgICAgICAgICAgICAgIHNjaHRhc2tzLmV4ZSAvZGVsZXRlIC90biAiJHQiIC9mIDI+JjEgfCBPdXQtTnVsbA0KICAgICAgICAgICAgICAgIFdyaXRlLUhvc3QgIiAgICBbK10gVGVybWluYXRlZCBhbmQgZGVsZXRlZCB0YXNrOiAkdCIgLUZvcmVncm91bmRDb2xvciBEYXJrR3JheQ0KICAgICAgICAgICAgfQ0KICAgICAgICB9IGNhdGNoIHt9DQogICAgfQ0KICAgIFdyaXRlLUhvc3QgIiAgICBbT0tdIEFsbCBHSU4tQWdlbnQgc2NoZWR1bGVkIHRhc2tzIHJlbW92ZWQuIiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQoNCiAgICAjIFNURVAgMzogU3RvcCBhbmQgcmVtb3ZlIGxlZ2FjeSBXaW5kb3dzIFNlcnZpY2VzDQogICAgV3JpdGUtSG9zdCAiWypdIFN0ZXAgMy82OiBTdG9wcGluZyBhbmQgZGVsZXRpbmcgbGVnYWN5IFdpbmRvd3MgU2VydmljZXMgKHNjLmV4ZSkuLi4iIC1Gb3JlZ3JvdW5kQ29sb3IgQ3lhbg0KICAgICRzZXJ2aWNlcyA9IEAoIkdJTi1BZ2VudCIsICJHSU4tQWdlbnQtU2VydmljZSIsICJHSU5fQWdlbnQiKQ0KICAgIGZvcmVhY2ggKCRzIGluICRzZXJ2aWNlcykgew0KICAgICAgICB0cnkgew0KICAgICAgICAgICAgJiBzYy5leGUgc3RvcCAkcyAyPiYxIHwgT3V0LU51bGwNCiAgICAgICAgICAgICYgc2MuZXhlIGRlbGV0ZSAkcyAyPiYxIHwgT3V0LU51bGwNCiAgICAgICAgICAgIFdyaXRlLUhvc3QgIiAgICBbK10gU3RvcHBlZC9wdXJnZWQgc2VydmljZTogJHMiIC1Gb3JlZ3JvdW5kQ29sb3IgRGFya0dyYXkNCiAgICAgICAgfSBjYXRjaCB7fQ0KICAgIH0NCiAgICBXcml0ZS1Ib3N0ICIgICAgW09LXSBXaW5kb3dzIFNlcnZpY2VzIGNoZWNrZWQgYW5kIGNsZWFuZWQuIiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQoNCiAgICAjIFNURVAgNDogVGVybWluYXRlIHJ1bm5pbmcgYmFja2dyb3VuZCBhZ2VudCBwcm9jZXNzZXMNCiAgICBXcml0ZS1Ib3N0ICJbKl0gU3RlcCA0LzY6IFRlcm1pbmF0aW5nIGFjdGl2ZSBiYWNrZ3JvdW5kIGFnZW50IHByb2Nlc3Nlcy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQogICAgJGN1cnJlbnRQaWQgPSAkUElEDQogICAgJHBhcmVudFBpZCA9IDANCiAgICB0cnkgew0KICAgICAgICAkcGFyZW50UHJvYyA9IEdldC1DaW1JbnN0YW5jZSBXaW4zMl9Qcm9jZXNzIC1GaWx0ZXIgIlByb2Nlc3NJZCA9ICRjdXJyZW50UGlkIiAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQ0KICAgICAgICBpZiAoJHBhcmVudFByb2MpIHsgJHBhcmVudFBpZCA9ICRwYXJlbnRQcm9jLlBhcmVudFByb2Nlc3NJZCB9DQogICAgfSBjYXRjaCB7fQ0KDQogICAgJGtpbGxlZENvdW50ID0gMA0KICAgIHRyeSB7DQogICAgICAgIEdldC1DaW1JbnN0YW5jZSBXaW4zMl9Qcm9jZXNzIC1GaWx0ZXIgIk5hbWUgPSAncG93ZXJzaGVsbC5leGUnIG9yIE5hbWUgPSAnY21kLmV4ZSciIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgV2hlcmUtT2JqZWN0IHsNCiAgICAgICAgICAgICRfLlByb2Nlc3NJZCAtbmUgJGN1cnJlbnRQaWQgLWFuZCAkXy5Qcm9jZXNzSWQgLW5lICRwYXJlbnRQaWQgLWFuZCAoDQogICAgICAgICAgICAgICAgJF8uQ29tbWFuZExpbmUgLWxpa2UgIipHSU4tQWdlbnQqIC9zZXJ2aWNlKiIgLW9yDQogICAgICAgICAgICAgICAgJF8uQ29tbWFuZExpbmUgLWxpa2UgIipHSU4tQWdlbnQuY21kKiIgLW9yDQogICAgICAgICAgICAgICAgJF8uQ29tbWFuZExpbmUgLWxpa2UgIipHbG9iYWxcR0lOX0FnZW50X0NvcmVfTXV0ZXgqIg0KICAgICAgICAgICAgKQ0KICAgICAgICB9IHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICAgICAgdHJ5IHsNCiAgICAgICAgICAgICAgICBTdG9wLVByb2Nlc3MgLUlkICRfLlByb2Nlc3NJZCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgICAgICAmIHRhc2traWxsLmV4ZSAvRiAvUElEICRfLlByb2Nlc3NJZCAyPiYxIHwgT3V0LU51bGwNCiAgICAgICAgICAgICAgICBXcml0ZS1Ib3N0ICIgICAgWytdIFRlcm1pbmF0ZWQgUElEOiAkKCRfLlByb2Nlc3NJZCkgKCQoJF8uTmFtZSkpIiAtRm9yZWdyb3VuZENvbG9yIERhcmtHcmF5DQogICAgICAgICAgICAgICAgJGtpbGxlZENvdW50KysNCiAgICAgICAgICAgIH0gY2F0Y2gge30NCiAgICAgICAgfQ0KICAgIH0gY2F0Y2gge30NCiAgICBXcml0ZS1Ib3N0ICIgICAgW09LXSBQcm9jZXNzIGNsZWFudXAgY29tcGxldGUgKCRraWxsZWRDb3VudCBiYWNrZ3JvdW5kIGluc3RhbmNlcyB0ZXJtaW5hdGVkKS4iIC1Gb3JlZ3JvdW5kQ29sb3IgR3JlZW4NCg0KICAgICMgU1RFUCA1OiBSZW1vdmUgV2luZG93cyBSZWdpc3RyeSB1bmluc3RhbGwgZW50cmllcw0KICAgIFdyaXRlLUhvc3QgIlsqXSBTdGVwIDUvNjogUmVtb3ZpbmcgV2luZG93cyBSZWdpc3RyeSB1bmluc3RhbGwgcmVnaXN0cmF0aW9ucy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQogICAgJHJlZ1BhdGhzID0gQCgNCiAgICAgICAgIkhLTE06XFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXFVuaW5zdGFsbFxHSU4tQWdlbnQiLA0KICAgICAgICAiSEtMTTpcU09GVFdBUkVcR0lOLUFnZW50Ig0KICAgICkNCiAgICBmb3JlYWNoICgkcnAgaW4gJHJlZ1BhdGhzKSB7DQogICAgICAgIGlmIChUZXN0LVBhdGggJHJwKSB7DQogICAgICAgICAgICB0cnkgew0KICAgICAgICAgICAgICAgIFJlbW92ZS1JdGVtIC1QYXRoICRycCAtUmVjdXJzZSAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCiAgICAgICAgICAgICAgICBXcml0ZS1Ib3N0ICIgICAgWytdIFB1cmdlZCByZWdpc3RyeSBrZXk6ICRycCIgLUZvcmVncm91bmRDb2xvciBEYXJrR3JheQ0KICAgICAgICAgICAgfSBjYXRjaCB7fQ0KICAgICAgICB9DQogICAgfQ0KICAgIFdyaXRlLUhvc3QgIiAgICBbT0tdIFdpbmRvd3MgQWRkL1JlbW92ZSBQcm9ncmFtcyByZWdpc3RyeSBrZXlzIHB1cmdlZC4iIC1Gb3JlZ3JvdW5kQ29sb3IgR3JlZW4NCg0KICAgICMgU1RFUCA2OiBDbGVhbiB1cCBkaXJlY3RvcmllcyBhbmQgZmlsZXMNCiAgICBXcml0ZS1Ib3N0ICJbKl0gU3RlcCA2LzY6IFB1cmdpbmcgcHJvZ3JhbSBmaWxlcyBhbmQgZGF0YSBkaXJlY3Rvcmllcy4uLiIgLUZvcmVncm91bmRDb2xvciBDeWFuDQogICAgJHNjcmlwdFBhdGggPSAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5QYXRoDQogICAgaWYgKC1ub3QgJHNjcmlwdFBhdGgpIHsgJHNjcmlwdFBhdGggPSAiJGVudjpQcm9ncmFtRmlsZXNcR0lOLUFnZW50XHVuaW5zdGFsbC5jbWQiIH0NCiAgICAkcGFyZW50Rm9sZGVyID0gU3BsaXQtUGF0aCAtUGFyZW50ICRzY3JpcHRQYXRoDQoNCiAgICAkZGlyc1RvUHVyZ2UgPSBAKA0KICAgICAgICAiJGVudjpQcm9ncmFtRGF0YVxHSU4tQWdlbnQiLA0KICAgICAgICAiJGVudjpQcm9ncmFtRmlsZXNcR0lOLUFnZW50IiwNCiAgICAgICAgIiR7ZW52OlByb2dyYW1GaWxlcyh4ODYpfVxHSU4tQWdlbnQiDQogICAgKQ0KICAgIGZvcmVhY2ggKCRkIGluICRkaXJzVG9QdXJnZSkgew0KICAgICAgICBpZiAoVGVzdC1QYXRoICRkKSB7DQogICAgICAgICAgICBHZXQtQ2hpbGRJdGVtIC1QYXRoICRkIC1GaWxlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlIHwgRm9yRWFjaC1PYmplY3Qgew0KICAgICAgICAgICAgICAgIGlmICgkXy5GdWxsTmFtZSAtbmUgJHNjcmlwdFBhdGgpIHsNCiAgICAgICAgICAgICAgICAgICAgdHJ5IHsNCiAgICAgICAgICAgICAgICAgICAgICAgICRfLklzUmVhZE9ubHkgPSAkZmFsc2UNCiAgICAgICAgICAgICAgICAgICAgICAgIFJlbW92ZS1JdGVtIC1QYXRoICRfLkZ1bGxOYW1lIC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQ0KICAgICAgICAgICAgICAgICAgICAgICAgV3JpdGUtSG9zdCAiICAgIFsrXSBEZWxldGVkIGZpbGU6ICQoJF8uTmFtZSkiIC1Gb3JlZ3JvdW5kQ29sb3IgRGFya0dyYXkNCiAgICAgICAgICAgICAgICAgICAgfSBjYXRjaCB7fQ0KICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgIH0NCiAgICAgICAgfQ0KICAgIH0NCiAgICBXcml0ZS1Ib3N0ICIgICAgW09LXSBGaWxlIHB1cmdlIGNvbXBsZXRlZCBzdWNjZXNzZnVsbHkuIiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQoNCiAgICBXcml0ZS1Ib3N0ICIiDQogICAgV3JpdGUtSG9zdCAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iIC1Gb3JlZ3JvdW5kQ29sb3IgR3JlZW4NCiAgICBXcml0ZS1Ib3N0ICIgIFtPS10gR0lOLUFHRU5UIEhBUyBCRUVOIENPTVBMRVRFTFkgQU5EIENMRUFOTFkgUkVNT1ZFRCEgICAgICAgICAgICIgLUZvcmVncm91bmRDb2xvciBHcmVlbg0KICAgIFdyaXRlLUhvc3QgIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IiAtRm9yZWdyb3VuZENvbG9yIEdyZWVuDQogICAgV3JpdGUtSG9zdCAiICBbK10gQWxsIGJhY2tncm91bmQgc2VydmljZXMsIHNjaGVkdWxlZCB0YXNrcywgYW5kIHJlZ2lzdHJ5IGVudHJpZXMgZGVsZXRlZC4iIC1Gb3JlZ3JvdW5kQ29sb3IgV2hpdGUNCiAgICBXcml0ZS1Ib3N0ICIgIFsrXSBTZXJ2ZXItc2lkZSB0ZWxlbWV0cnkgcmVjb3JkIGRlcmVnaXN0ZXJlZCBmcm9tIHJlbW90ZSBkYXNoYm9hcmQuIiAtRm9yZWdyb3VuZENvbG9yIFdoaXRlDQogICAgV3JpdGUtSG9zdCAiICBbK10gSW5zdGFsbGF0aW9uIGRpcmVjdG9yeSB3aWxsIGJlIHB1cmdlZCB1cG9uIHdpbmRvdyBjbG9zZS4iIC1Gb3JlZ3JvdW5kQ29sb3IgV2hpdGUNCiAgICBXcml0ZS1Ib3N0ICItLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIgLUZvcmVncm91bmRDb2xvciBEYXJrR3JheQ0KICAgIFdyaXRlLUhvc3QgIiINCg0KICAgICMgU2VsZi1kZWxldGlvbiBvZiB0aGUgZGlyZWN0b3J5IHZpYSBkZXRhY2hlZCBjbWQgYWZ0ZXIgZXhpdA0KICAgIGlmICgkcGFyZW50Rm9sZGVyIC1hbmQgKFRlc3QtUGF0aCAkcGFyZW50Rm9sZGVyKSkgew0KICAgICAgICBTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAiY21kLmV4ZSIgLUFyZ3VtZW50TGlzdCAiL2MgcGluZyAxMjcuMC4wLjEgLW4gMiA+bnVsICYgcmQgL3MgL3EgYCJgIiRwYXJlbnRGb2xkZXJgImAiIiAtV2luZG93U3R5bGUgSGlkZGVuDQogICAgfQ0KDQogICAgIyAxMC1zZWNvbmQgaW50ZXJhY3RpdmUgY291bnRkb3duIGZvciB1c2VyIHRvIHJlYWQvY29weSB0aGUgbG9nDQogICAgZm9yICgkc2VjID0gMTA7ICRzZWMgLWd0IDA7ICRzZWMtLSkgew0KICAgICAgICBXcml0ZS1Ib3N0IC1Ob05ld2xpbmUgImByWypdIFdpbmRvdyBjbG9zaW5nIGF1dG9tYXRpY2FsbHkgaW4gJHNlYyBzZWNvbmRzIChvciBwcmVzcyBhbnkga2V5IHRvIGNsb3NlIG5vdykuLi4gICAiDQogICAgICAgICRzdyA9IFtTeXN0ZW0uRGlhZ25vc3RpY3MuU3RvcHdhdGNoXTo6U3RhcnROZXcoKQ0KICAgICAgICB3aGlsZSAoJHN3LkVsYXBzZWRNaWxsaXNlY29uZHMgLWx0IDEwMDApIHsNCiAgICAgICAgICAgICRrZXlIaXQgPSAkZmFsc2UNCiAgICAgICAgICAgIHRyeSB7DQogICAgICAgICAgICAgICAgaWYgKC1ub3QgW0NvbnNvbGVdOjpJc0lucHV0UmVkaXJlY3RlZCkgew0KICAgICAgICAgICAgICAgICAgICBpZiAoW1N5c3RlbS5Db25zb2xlXTo6S2V5QXZhaWxhYmxlKSB7DQogICAgICAgICAgICAgICAgICAgICAgICBbdm9pZF1bU3lzdGVtLkNvbnNvbGVdOjpSZWFkS2V5KCR0cnVlKQ0KICAgICAgICAgICAgICAgICAgICAgICAgJGtleUhpdCA9ICR0cnVlDQogICAgICAgICAgICAgICAgICAgIH0NCiAgICAgICAgICAgICAgICB9DQogICAgICAgICAgICB9IGNhdGNoIHt9DQogICAgICAgICAgICBpZiAoJGtleUhpdCkgew0KICAgICAgICAgICAgICAgICRzZWMgPSAwDQogICAgICAgICAgICAgICAgYnJlYWsNCiAgICAgICAgICAgIH0NCiAgICAgICAgICAgIFN0YXJ0LVNsZWVwIC1NaWxsaXNlY29uZHMgNTANCiAgICAgICAgfQ0KICAgIH0NCiAgICBXcml0ZS1Ib3N0ICIiDQogICAgW1N5c3RlbS5FbnZpcm9ubWVudF06OkV4aXQoMCkNCn0gY2F0Y2ggew0KICAgIFdyaXRlLUhvc3QgIiINCiAgICBXcml0ZS1Ib3N0ICJbIV0gVW5pbnN0YWxsYXRpb24gZXJyb3I6ICQoJF8uRXhjZXB0aW9uLk1lc3NhZ2UpIiAtRm9yZWdyb3VuZENvbG9yIFJlZA0KICAgIFN0YXJ0LVNsZWVwIC1TZWNvbmRzIDEwDQogICAgZXhpdCAxDQp9DQo="
        [System.IO.File]::WriteAllBytes($uninstallerCmd, [System.Convert]::FromBase64String($uninstallerB64))

        # 9. Register in Windows Installed Apps (Add/Remove Programs)
        try {
            $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Agent"
            if (-not (Test-Path $uninstallKey)) { New-Item -Path $uninstallKey -Force -ErrorAction SilentlyContinue | Out-Null }
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayName" -Value "GIN-Agent Remote Support" -Force -ErrorAction SilentlyContinue
            $null = Set-ItemProperty -Path $uninstallKey -Name "DisplayVersion" -Value "v027" -Force -ErrorAction SilentlyContinue
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
        schtasks.exe /create /tn "$taskName" /tr "\`"$targetCmd\`" /service $selectedRegion" /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f 2>&1 | Out-Null
        schtasks.exe /run /tn "$taskName" 2>&1 | Out-Null

        $serviceStarted = $false
        for ($w = 0; $w -lt 6; $w++) {
            Start-Sleep -Milliseconds 500
            $runningProc = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                    $_.CommandLine -like "*$targetCmd* /service*" -or
                    $_.CommandLine -like "*GIN-Agent.cmd* /service*"
                )
            }
            if ($runningProc) {
                $serviceStarted = $true
                break
            }
        }

        if (-not $serviceStarted) {
            try {
                [void](Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
                    CommandLine = "`"$targetCmd`" /service $selectedRegion"
                } -ErrorAction SilentlyContinue)
            } catch {}
        }

        if (-not $isSilent) {
            $regDesc = if ($selectedRegion -eq "RU") { "RUSSIA (Server 109: 212.109.223.109)" } else { "EUROPE (Server_222: 152.53.182.222)" }
            Write-Host ""
            Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [+] GIN-Agent v027 deployed cleanly in Program Files!" -ForegroundColor Green
            Write-Host "  [+] Location: $installDir" -ForegroundColor White
            Write-Host "  [+] Uninstaller: $uninstallerCmd" -ForegroundColor White
            Write-Host "  [+] Active region: $regDesc" -ForegroundColor Cyan
            Write-Host "  [+] Auto-Update: enabled (Dual-channel: RU-109 / GitHub)" -ForegroundColor Green
            Write-Host "  [+] Task: GIN-Agent-Service (Auto-start on OS boot, $selectedRegion)" -ForegroundColor Cyan
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
    $mutex = New-Object System.Threading.Mutex($true, "Global\GIN_Agent_Core_Mutex", [ref]$createdNew)
    if (-not $createdNew) { exit 0 }

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
                if ($c -match '(?m)^\s*id\s*=\s*[''"]?(\d{6,12})[''"]?') {
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
            version         = "v027"
            first_connect   = $isFirstRegistration
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
        if ($isFirstRegistration) {
            [System.IO.File]::WriteAllText($tagFile, (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), [System.Text.Encoding]::UTF8)
        }
    } catch {}

    # Function: Auto-Update Check
    function Check-GINAgentUpdate {
        param([string]$currentVer = "v027", [string]$activeRegion = "EU")
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

    # Background Polling Loop
    $loopCount = 0
    $updateCheckCounter = 0

    while ($true) {
        try {
            $pollUrl = "$serverUrl/poll?h=$([System.Uri]::EscapeDataString($env:COMPUTERNAME))&pin=$pin"
            $resp = Invoke-RestMethod -Uri $pollUrl -Method Get -Headers $headers -TimeoutSec 15 -ErrorAction SilentlyContinue
            if ($resp -and $resp.command) {
                $cmdId = $resp.id
                $cmdText = $resp.command
                $out = ""
                try {
                    $sb = [ScriptBlock]::Create($cmdText)
                    $out = & $sb 2>&1 | Out-String
                } catch {
                    $out = $_.Exception.Message
                }
                if (-not $out -or $out.Trim() -eq "") { $out = "[OK: Command completed with no output]" }
                $bodyObj = @{ id = $cmdId; host = $env:COMPUTERNAME; output = $out } | ConvertTo-Json
                Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $bodyObj -TimeoutSec 10 -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            Start-Sleep -Seconds 2
        }

        # KeepAlive to rd.gincz.com every ~30 seconds
        $loopCount++
        if ($loopCount -ge 6) {
            $loopCount = 0
            try {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v027&rd_id=$rustdeskId&gw=$([System.Uri]::EscapeDataString($activeGatewayName))&region=$region"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }

        # Auto-Update Check: Initial check after 4 loops (~60s), then every 960 loops (~4 hours)
        $updateCheckCounter++
        if ($updateCheckCounter -eq 4 -or $updateCheckCounter -ge 960) {
            if ($updateCheckCounter -ge 960) { $updateCheckCounter = 5 }
            Check-GINAgentUpdate -currentVer "v027" -activeRegion $region
        }

        Start-Sleep -Seconds 5
    }

} catch {
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host "  [!] CRITICAL ERROR GIN-AGENT v027:" -ForegroundColor Red
    Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Line:    $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}
