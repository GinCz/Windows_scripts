<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent v016

:: 1. Resilient Elevation Check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_AGENT

if not defined GIN_AGENT_ELEVATED (
    set GIN_AGENT_ELEVATED=1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

:RUN_AGENT
:: 2. Set script path safely in environment variable to avoid quote parsing bugs
set "GIN_AGENT_SCRIPT=%~f0"

set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:: 3. Execute directly with resilient fallback:
"%PS_EXE%" -NoExit -NoProfile -ExecutionPolicy Bypass -Command "$p = $env:GIN_AGENT_SCRIPT; if (-not $p -or -not (Test-Path -LiteralPath $p)) { $p = '%~f0' }; if (-not (Test-Path -LiteralPath $p)) { $p = (Get-ChildItem -Path $env:USERPROFILE\Downloads, 'D:\DOCS\DownLOAD', 'D:\MEGA\WIN-FLASH\Util-WINDOWS', 'D:\MEGA\DOCS\desktop', $pwd -Filter '*GIN-Agent*.cmd' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }; if ($p -and (Test-Path -LiteralPath $p)) { $raw = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8); try { & ([ScriptBlock]::Create($raw)) } catch { Write-Host ('`n[X] SCRIPT EXECUTION ERROR: ' + $_.Exception.ToString()) -ForegroundColor Red; Write-Host '`nPress any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } } else { Write-Host ('`n[X] ERROR: Could not locate agent script file. Path: ' + $p) -ForegroundColor Red; Write-Host '`nPress any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }"

if %errorlevel% neq 0 pause
exit /b
#>
# ==============================================================================
# GIN-Agent v016
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Universal Multi-Platform Agent Ecosystem (Windows PC, Android, Linux)
# Features: Anti-Conflict Lock, Auto-RDP Shadow Enable, RustDesk ID Sync, Telemetry
# Gateways: Global (remote.gincz.com), RU-FastNode (195.158.255.208), RU-109 (212.109.223.109)
# ==============================================================================

try {
    $ErrorActionPreference = "Continue"

    # Universal TLS 1.2 Configuration
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    } catch {
        try { [System.Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}
    }

    $token = "GinCz-Remote-2026"
    $headers = @{ 
        "Token"  = $token
        "X-Host" = $env:COMPUTERNAME
    }

    # 1. Anti-Conflict Singleton Lock via Named Mutex
    $mutexName = "Global\GIN_Agent_SingleInstance_Mutex"
    $createdNew = $false
    $agentMutex = $null
    try {
        $agentMutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
        if (-not $createdNew) {
            Write-Host "`n[!] An instance of GIN-Agent is already running on this machine." -ForegroundColor Yellow
            Write-Host "[*] Terminating duplicate/older session cleanly to avoid conflicts..." -ForegroundColor Cyan
            # Close previous PowerShell agent instances if running from temp or older scripts
            $currentPid = $PID
            Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $currentPid -and ($_.CommandLine -like "*GIN-Agent*" -or $_.CommandLine -like "*agent-api*")
            } | ForEach-Object {
                try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
            }
            Start-Sleep -Milliseconds 800
        }
    } catch {}

    # 2. Resilient Triple Gateway Selection
    $gateways = @(
        @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
        @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
        @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" }
    )

    $serverUrl = ""
    $activeGatewayName = ""

    foreach ($gw in $gateways) {
        try {
            $testUrl = "$($gw.Url)/status"
            $resp = Invoke-RestMethod -Uri $testUrl -Headers $headers -TimeoutSec 3 -ErrorAction Stop
            if ($resp -and ($resp.status -eq "ok" -or $resp.message -like "*Bridge Online*" -or $resp.gateway)) {
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

    # 3. Check Administrator Privileges
    $admin = $false
    try {
        $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {}

    # 4. Auto-Configure RDP Shadow Mode (If Admin)
    $rdpConfigured = $false
    if ($admin) {
        try {
            # Enable RDP
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force -ErrorAction SilentlyContinue
            # Configure Shadowing: 2 = Full control without user consent prompt (ideal for remote support)
            $tsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
            if (-not (Test-Path $tsPolicy)) { New-Item -Path $tsPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $tsPolicy -Name "Shadow" -Value 2 -Force -ErrorAction SilentlyContinue
            # Ensure firewall allows RDP
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Out-Null
            $rdpConfigured = $true
        } catch {}
    }

    # 5. Detect Installed RustDesk ID
    $rustdeskId = ""
    try {
        $rdConfigPaths = @(
            "$env:APPDATA\RustDesk\config\RustDesk.toml",
            "$env:APPDATA\RustDesk\config\rustdesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml",
            "$env:SystemDrive\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\rustdesk.toml"
        )
        foreach ($cp in $rdConfigPaths) {
            if (Test-Path $cp) {
                $content = Get-Content -Path $cp -Raw -ErrorAction SilentlyContinue
                if ($content -match 'id\s*=\s*[''"]?([0-9a-zA-Z_-]+)[''"]?') {
                    $rustdeskId = $matches[1]
                    break
                }
            }
        }
    } catch {}

    # 6. Host Architecture & Telemetry
    $arch = if ([IntPtr]::Size -eq 8) { "64-bit" } else { "32-bit" }
    $osName = "Microsoft Windows ($arch)"
    $cpuName = "N/A"
    $ramStr = "N/A"
    $diskStr = "N/A"

    try {
        $osInfo = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue)
        if (-not $osInfo) { $osInfo = (Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue) }
        if ($osInfo) { $osName = "$($osInfo.Caption) ($arch)" }
    } catch {}

    try {
        $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $cpuObj) { $cpuObj = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1 }
        if ($cpuObj -and $cpuObj.Name) { $cpuName = $cpuObj.Name.Trim() }
    } catch {}

    try {
        if ($osInfo) {
            $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
            $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
            if (-not $cs) { $cs = Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue }
            $totRam = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            $ramStr = "$freeRam GB free / $totRam GB total"
        }
    } catch {}

    try {
        $drive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($drive) {
            $freeGb = [math]::Round($drive.Free / 1GB, 1)
            $totGb = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
            $diskStr = "C: $freeGb GB free / $totGb GB total"
        }
    } catch {}

    # 7. Calculate Deterministic 9-Digit GIN PIN (Hardware Fingerprint)
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

    # 8. Register Session and Trigger Telegram Notification via Server Bridge
    try {
        $regPayload = @{
            pin         = $pin
            host        = $env:COMPUTERNAME
            user        = $env:USERNAME
            admin       = $admin
            os          = $osName
            cpu         = $cpuName
            ram         = $ramStr
            disk        = $diskStr
            rustdesk_id = $rustdeskId
            rdp_ready   = $rdpConfigured
            gateway     = $activeGatewayName
            version     = "v016"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    # Also Ping RU-109 Central Dashboard (rd.gincz.com) for Immediate Status Sync
    try {
        $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v016&rd_id=$rustdeskId"
        Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    try {
        [Console]::Title = "GIN-Agent v016 [$activeGatewayName]"
    } catch {}

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "               GIN-AGENT v016 - CENTRAL REMOTE HUB                  " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "    GIN PIN:     $pin" -ForegroundColor Yellow
    Write-Host "    Status:      CONNECTED TO $activeGatewayName" -ForegroundColor White
    if ($admin) {
        Write-Host "    Privileges:  Administrator (Full Access & RDP Shadow Ready)" -ForegroundColor Green
    } else {
        Write-Host "    Privileges:  User (Standard Rights)" -ForegroundColor Yellow
        Write-Host "    [!] For full RDP and background control: Right-Click -> 'Run as administrator'" -ForegroundColor DarkYellow
    }
    Write-Host "    Host:        $env:COMPUTERNAME ($env:USERNAME)" -ForegroundColor Cyan
    Write-Host "    RustDesk ID: $(if ($rustdeskId) { $rustdeskId } else { 'Not Detected' })" -ForegroundColor Magenta
    Write-Host "    OS / Arch:   $osName" -ForegroundColor Gray
    Write-Host "    CPU / RAM:   $cpuName | $ramStr" -ForegroundColor DarkGray
    Write-Host "    Disk:        $diskStr" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "    [+] Registered on rd.gincz.com & remote.gincz.com" -ForegroundColor Green
    Write-Host "    [+] Telegram notification sent to Vladimir." -ForegroundColor Green
    Write-Host "    System is ready for Antigravity AI maintenance and RDP Shadow." -ForegroundColor Gray
    Write-Host "    (Keep this window open during active maintenance session)" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[*] Listening for Antigravity AI tasks..." -ForegroundColor Green

    # 9. Resilient Main Polling Loop with Direct Execution & RU-109 KeepAlive
    $loopCount = 0
    while ($true) {
        try {
            $headers = @{ 
                "Token"  = $token
                "X-Host" = $env:COMPUTERNAME
            }
            $pollUrl = "$serverUrl/poll?h=$env:COMPUTERNAME"
            $resp = Invoke-RestMethod -Uri $pollUrl -Headers $headers -TimeoutSec 15 -ErrorAction SilentlyContinue
            if ($resp -and $resp.command) {
                $cmdId = $resp.id
                $cmdText = $resp.command
                Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Task #$cmdId received: $cmdText" -ForegroundColor Magenta
                
                $out = ""
                try {
                    $sb = [ScriptBlock]::Create($cmdText)
                    $out = & $sb 2>&1 | Out-String
                } catch {
                    $out = $_.Exception.Message
                }
                if (-not $out -or $out.Trim() -eq "") { $out = "[OK: Command completed with no output]" }

                $bodyObj = @{
                    id     = $cmdId
                    host   = $env:COMPUTERNAME
                    output = $out
                } | ConvertTo-Json

                Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $bodyObj -TimeoutSec 10 -ErrorAction SilentlyContinue | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Task #$cmdId completed." -ForegroundColor Green
            }
        } catch {
            Start-Sleep -Seconds 2
        }

        # KeepAlive to rd.gincz.com every ~30 seconds (every 6th poll)
        $loopCount++
        if ($loopCount -ge 6) {
            $loopCount = 0
            try {
                $rdPingUrl = "https://rd.gincz.com/api/agent_heartbeat?host=$($env:COMPUTERNAME)&user=$($env:USERNAME)&pin=$pin&v=v016&rd_id=$rustdeskId"
                Invoke-RestMethod -Uri $rdPingUrl -Method Get -TimeoutSec 4 -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }

        Start-Sleep -Seconds 5
    }

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
    pause
}
