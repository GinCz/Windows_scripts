<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent v022

:: If launched with /service or --service in background
if /i "%~1"=="/service" goto :RUN_SERVICE
if /i "%~1"=="--service" goto :RUN_SERVICE

:: Check for direct region parameter if passed via CLI
if /i "%~1"=="/ru" set "GIN_AGENT_REGION=RU"
if /i "%~1"=="RU" set "GIN_AGENT_REGION=RU"
if /i "%~1"=="/eu" set "GIN_AGENT_REGION=EU"
if /i "%~1"=="EU" set "GIN_AGENT_REGION=EU"

:: 1. Resilient Elevation Check for interactive installer
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

:EXEC_PS
set "GIN_AGENT_SCRIPT=%~f0"

set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) else if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText($env:GIN_AGENT_SCRIPT, [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"

exit /b 0
#>
# ==============================================================================
# GIN-Agent Windows Service v022 (Single File CMD Hybrid)
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Permanent Background Windows Service (Auto-Start, Watchdog Recovery, No Console Window)
# Primary Identifier: 9-Digit Hardware GIN-PIN
# Supported Platforms: Windows 10 (32-bit & 64-bit), Windows 11 (64-bit / ARM64)
# Regional Gateways:
#   - Europe: Server_222 (152.53.182.222:9876), Global (remote.gincz.com)
#   - Russia: Server_109 (212.109.223.109), RU-FastNode (195.158.255.208)
# Interactive Gateway Selector: 1. Europe (Default after 5s) / 2. Russia (Server 109)
# ZERO External PS1 Files - 100% Standalone Polyglot CMD Architecture
# ==============================================================================

try {
    $ErrorActionPreference = "Continue"

    # Universal TLS 1.2
    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {}

    $installDir = "$env:ProgramData\GIN-Agent"
    $targetCmd = "$installDir\GIN-Agent.cmd"
    $targetCmdV22 = "$installDir\GIN-Agent_Windows_v022.cmd"
    $serviceName = "GIN-Agent"
    $serviceDisplayName = "GIN-Agent Remote Support Service"
    $serviceDesc = "Provides resilient background diagnostic connection and RDP shadow support for Vladimir Bulantsev (GinCz)."

    $mode = $env:GIN_AGENT_MODE
    if (-not $mode) {
        if ($env:GIN_AGENT_SCRIPT -and $env:GIN_AGENT_SCRIPT.ToLower().Contains("programdata")) {
            $mode = "SERVICE"
        } else {
            $mode = "INSTALL"
        }
    }

    # ==========================================================================
    # MODE 1: INSTALLER (Interactive Region Selection & Service Deployment)
    # ==========================================================================
    if ($mode -ne "SERVICE") {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "         GIN-AGENT v022 - ВЫБОР РЕГИОНА / GATEWAY SELECTION         " -ForegroundColor Cyan
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "  [1] Европа (Server_222 / Global)   [По умолчанию через 5 сек]" -ForegroundColor Green
        Write-Host "  [2] Россия (Сервер 109 FirstVDS)" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray

        $selectedRegion = $env:GIN_AGENT_REGION
        if (-not $selectedRegion) {
            $selectedRegion = "EU"
            $secondsLeft = 5
            try {
                while ($secondsLeft -gt 0) {
                    Write-Host -NoNewline "`r[*] Выберите регион [1/2] (по умолчанию [1] через $secondsLeft сек): "
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

        Write-Host ""
        if ($selectedRegion -eq "RU") {
            Write-Host "[✓] Выбран регион: РОССИЯ (Сервер 109 - 212.109.223.109)" -ForegroundColor Yellow
        } else {
            Write-Host "[✓] Выбран регион: ЕВРОПА (Server_222 - 152.53.182.222)" -ForegroundColor Green
        }
        Write-Host ""

        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "         GIN-AGENT v022 - СИСТЕМНАЯ СЛУЖБА РАЗВЕРТЫВАНИЯ            " -ForegroundColor Green
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "[*] Полная остановка и удаление предыдущих версий агента..." -ForegroundColor Yellow

        # 1. Stop and remove any running scheduled task instances (Service & Watchdogs)
        $oldTasks = @("GIN-Agent-Service", "GIN-Agent", "GIN-Agent-Watchdog")
        foreach ($ot in $oldTasks) {
            try { schtasks.exe /end /tn $ot >$null 2>&1 } catch {}
            try { schtasks.exe /delete /tn $ot /f >$null 2>&1 } catch {}
        }

        # 2. Kill all background agent processes (both cmd.exe and powershell.exe)
        $currentPid = $PID
        $parentPid = 0
        try {
            $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction SilentlyContinue
            if ($parentProc) { $parentPid = $parentProc.ParentProcessId }
        } catch {}

        # Scan and terminate all previous GIN-Agent powershell and cmd instances
        try {
            Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and $_.ProcessId -ne $parentPid -and (
                    ($_.Name -eq "powershell.exe" -and (
                        $_.CommandLine -like "*GIN-Agent*" -or
                        $_.CommandLine -like "*agent-api*" -or
                        $_.CommandLine -like "*Global\GIN_Agent_Core_Mutex*" -or
                        $_.CommandLine -like "*remote.gincz.com/agent-api*"
                    )) -or
                    ($_.Name -eq "cmd.exe" -and (
                        $_.CommandLine -like "*ProgramData\GIN-Agent*" -or
                        $_.CommandLine -like "*GIN-Agent*.cmd*" -or
                        $_.CommandLine -like "*/service*"
                    ))
                )
            } | ForEach-Object {
                try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
            }
        } catch {}

        # Supplementary safety check via Get-Process
        try {
            Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
                $_.Id -ne $currentPid -and $_.Id -ne $parentPid
            } | ForEach-Object {
                try {
                    $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                    if ($cmdLine -and ($cmdLine -like "*GIN-Agent*" -or $cmdLine -like "*agent-api*")) {
                        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        } catch {}

        Start-Sleep -Milliseconds 800

        # Deploy Directory and CMD file (Zero PS1 files)
        if (-not (Test-Path $installDir)) {
            New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Purge obsolete PS1 files from previous versions (Strictly NO PS1 files)
        Get-ChildItem -Path $installDir -Filter "*.ps1" -File -ErrorAction SilentlyContinue | ForEach-Object {
            try { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
        }

        # Clear ReadOnly flag on existing target if set
        if (Test-Path $targetCmd) {
            try { (Get-Item $targetCmd -Force).IsReadOnly = $false } catch {}
        }

        # Save selected region configuration
        [System.IO.File]::WriteAllText("$installDir\region.txt", $selectedRegion, [System.Text.Encoding]::UTF8)

        # Copy the single CMD file to installation target with safe overwrite
        $sourceScript = $env:GIN_AGENT_SCRIPT
        if ($sourceScript -and (Test-Path $sourceScript)) {
            try { Remove-Item -Path $targetCmd -Force -ErrorAction SilentlyContinue } catch {}
            try {
                Copy-Item -Path $sourceScript -Destination $targetCmd -Force -ErrorAction Stop
            } catch {
                try {
                    $bakFile = "$targetCmd.old.$([System.IO.Path]::GetRandomFileName())"
                    Move-Item -Path $targetCmd -Destination $bakFile -Force -ErrorAction SilentlyContinue
                    Copy-Item -Path $sourceScript -Destination $targetCmd -Force -ErrorAction Stop
                } catch {
                    [System.IO.File]::WriteAllBytes($targetCmd, [System.IO.File]::ReadAllBytes($sourceScript))
                }
            }
            try { Copy-Item -Path $sourceScript -Destination $targetCmdV22 -Force -ErrorAction SilentlyContinue } catch {}
        } else {
            $myRaw = if ($MyInvocation.MyCommand.Path -and (Test-Path $MyInvocation.MyCommand.Path)) {
                [System.IO.File]::ReadAllText($MyInvocation.MyCommand.Path, [System.Text.Encoding]::UTF8)
            } else { "" }
            if ($myRaw) {
                try { [System.IO.File]::WriteAllText($targetCmd, $myRaw, [System.Text.Encoding]::UTF8) } catch {}
                try { [System.IO.File]::WriteAllText($targetCmdV22, $myRaw, [System.Text.Encoding]::UTF8) } catch {}
            }
        }

        # Purge older versioned CMDs in installDir (retain strictly 2 latest: v021 and v022)
        Get-ChildItem -Path $installDir -Filter "GIN-Agent_Windows_v*.cmd" -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne "GIN-Agent_Windows_v022.cmd" -and $_.Name -ne "GIN-Agent_Windows_v021.cmd"
        } | ForEach-Object {
            try { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue } catch {}
        }

        # Register Native Windows Scheduled Service Host (HIGHEST Privileges, ONSTART)
        Write-Host "[*] Регистрация чистой фоновой службы GIN-Agent ($selectedRegion)..." -ForegroundColor Cyan

        $taskName = "GIN-Agent-Service"
        $taskAction = "cmd.exe"
        $taskArgs = "/c `"`"$targetCmd`" /service $selectedRegion`""

        schtasks.exe /delete /tn "$taskName" /f >$null 2>&1
        schtasks.exe /create /tn "$taskName" /tr "$taskAction $taskArgs" /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f >$null 2>&1
        schtasks.exe /run /tn "$taskName" >$null 2>&1

        # Fallback background execution
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"`"$targetCmd`" /service $selectedRegion`"" -WindowStyle Hidden

        $regDesc = if ($selectedRegion -eq "RU") { "РОССИЯ (Сервер 109: 212.109.223.109)" } else { "ЕВРОПА (Server_222: 152.53.182.222)" }

        Write-Host ""
        Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  [+] GIN-Agent v022 успешно развернут как СИСТЕМНАЯ СЛУЖБА!" -ForegroundColor Green
        Write-Host "  [+] Выбранный регион: $regDesc" -ForegroundColor Cyan
        Write-Host "  [+] Совместимость: Windows 10 (32-bit / 64-bit), Windows 11." -ForegroundColor White
        Write-Host "  [+] Архитектура: единый автономный CMD (без внешних PS1 файлов)." -ForegroundColor White
        Write-Host "  [+] Служба запущена и работает в скрытом фоновом режиме." -ForegroundColor White
        Write-Host "  [+] Задача Windows: GIN-Agent-Service (Автозапуск при старте ОС, $selectedRegion)" -ForegroundColor Cyan
        Write-Host "  [+] Окно закроется автоматически через 5 секунд." -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 5; $i -ge 1; $i--) {
            Write-Host -NoNewline "`r[*] Закрытие окна установщика через $i сек... "
            Start-Sleep -Seconds 1
        }
        Write-Host "`r[✓] Установка завершена! Служба активна в фоне. До свидания.       " -ForegroundColor Green
        Start-Sleep -Milliseconds 500
        exit 0
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
        # Russia-first
        $gateways = @(
            @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" },
            @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
            @{ Name = "Europe (Server_222)"; Url = "http://152.53.182.222:9876" },
            @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" }
        )
    } else {
        # Europe-first
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

    # Ensure RDP & Shadow Policy (Shadow = 2: Full remote control without user prompt)
    try {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force -ErrorAction SilentlyContinue
        $tsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
        if (-not (Test-Path $tsPolicy)) { New-Item -Path $tsPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $tsPolicy -Name "Shadow" -Value 2 -Force -ErrorAction SilentlyContinue
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Out-Null
    } catch {}

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

    # Detect RustDesk ID from CLI or configs
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
                if ($c -match '(?m)^\s*id\s*=\s*[''''"]?(\d{6,12})[''''"]?') {
                    $rustdeskId = $matches[1]
                    break
                }
            }
        }
        if (-not $rustdeskId) {
            foreach ($cp in $rdPaths) {
                if (Test-Path $cp) {
                    $c = Get-Content -Path $cp -Raw -ErrorAction SilentlyContinue
                    if ($c -match 'id\s*=\s*[''''"]?([0-9a-zA-Z_-]+)[''''"]?') {
                        $rustdeskId = $matches[1]
                        break
                    }
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

    # Hardware GIN-PIN calculation (Deterministic)
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

    # Initial Registration
    try {
        $regPayload = @{
            pin         = $pin
            host        = $env:COMPUTERNAME
            user        = $env:USERNAME
            admin       = $true
            os          = $osName
            cpu         = $cpuName
            ram         = $ramStr
            disk        = $diskStr
            rustdesk_id = $rustdeskId
            rdp_ready   = $true
            region      = $region
            gateway     = $activeGatewayName
            version     = "v022"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    # Background Polling Loop
    $loopCount = 0
    while ($true) {
        try {
            $pollUrl = "$serverUrl/poll?h=$([System.Uri]::EscapeDataString($env:COMPUTERNAME))"
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
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v022&rd_id=$rustdeskId&gw=$([System.Uri]::EscapeDataString($activeGatewayName))&region=$region"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }
        Start-Sleep -Seconds 5
    }

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
    if ($mode -ne "SERVICE") { pause }
}
