<# :
@echo off
setlocal DisableDelayedExpansion
title GIN-Agent Windows PC v015

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
"%PS_EXE%" -NoExit -NoProfile -ExecutionPolicy Bypass -Command "$p = $env:GIN_AGENT_SCRIPT; if (-not $p -or -not (Test-Path -LiteralPath $p)) { $p = '%~f0' }; if (-not (Test-Path -LiteralPath $p)) { $p = (Get-ChildItem -Path $env:USERPROFILE\Downloads, 'D:\DOCS\DownLOAD', 'D:\MEGA\WIN-FLASH\Util-WINDOWS', 'D:\MEGA\DOCS\desktop', $pwd -Filter '*GIN-Agent_Windows*.cmd' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }; if ($p -and (Test-Path -LiteralPath $p)) { $raw = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8); try { & ([ScriptBlock]::Create($raw)) } catch { Write-Host ('`n[X] SCRIPT EXECUTION ERROR: ' + $_.Exception.ToString()) -ForegroundColor Red; Write-Host '`nPress any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } } else { Write-Host ('`n[X] ERROR: Could not locate agent script file. Path: ' + $p) -ForegroundColor Red; Write-Host '`nPress any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }"

if %errorlevel% neq 0 pause
exit /b
#>
# ==============================================================================
# GIN-Agent Windows PC v015
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Universal 32-bit / 64-bit Windows Agent for Antigravity AI
# Language: 100% Pure ASCII English (Universal Locale & Encoding Immunity)
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

    # Resilient Triple Gateway Selection
    $gateways = @(
        @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
        @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" },
        @{ Name = "Russia (RU-109)"; Url = "http://212.109.223.109/agent-api" }
    )

    $serverUrl = ""
    $activeGatewayName = ""

    foreach ($gw in $gateways) {
        try {
            $st = Invoke-RestMethod -Uri "$($gw.Url)/status" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
            if ($st -match "Bridge Online") {
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

    # Check Administrator Privileges
    $admin = $false
    try {
        $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {}

    # Host Architecture & Telemetry
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

    # Calculate Deterministic 9-Digit GIN PIN (Hardware Fingerprint)
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

    # Register Session and Trigger Telegram Notification via Server Bridge
    try {
        $regPayload = @{
            pin     = $pin
            host    = $env:COMPUTERNAME
            user    = $env:USERNAME
            admin   = $admin
            os      = $osName
            cpu     = $cpuName
            ram     = $ramStr
            disk    = $diskStr
            gateway = $activeGatewayName
            version = "v015"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    try {
        [Console]::Title = "GIN-Agent Windows PC v015 [$activeGatewayName]"
    } catch {}

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "     GIN-AGENT WINDOWS PC v015 - REMOTE AI OPTIMIZATION PORTAL      " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "    GIN PIN:    $pin" -ForegroundColor Yellow
    Write-Host "    Status:     CONNECTED TO $activeGatewayName" -ForegroundColor White
    if ($admin) {
        Write-Host "    Privileges: Administrator (Full Access)" -ForegroundColor Green
    } else {
        Write-Host "    Privileges: User (Standard Rights)" -ForegroundColor Yellow
        Write-Host "    [!] Running in user mode. For elevated tasks: Right-Click -> 'Run as administrator'" -ForegroundColor DarkYellow
    }
    Write-Host "    Host:       $env:COMPUTERNAME ($env:USERNAME)" -ForegroundColor Cyan
    Write-Host "    OS / Arch:  $osName" -ForegroundColor Gray
    Write-Host "    CPU:        $cpuName" -ForegroundColor DarkGray
    Write-Host "    RAM / Disk: $ramStr | $diskStr" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "    [+] Telegram notification sent to Vladimir." -ForegroundColor Green
    Write-Host "    System is ready for diagnostics and Antigravity maintenance." -ForegroundColor Gray
    Write-Host "    [!] Keep this window open while Antigravity performs tasks." -ForegroundColor Yellow
    Write-Host "    (To end session: press Ctrl+C or close window)" -ForegroundColor DarkGray
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[*] Listening for Antigravity AI tasks..." -ForegroundColor Green

    # Resilient Main Polling Loop
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
                    output = $out
                }
                $jsonBody = $bodyObj | ConvertTo-Json
                
                try {
                    Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBody -TimeoutSec 15 -ErrorAction Stop | Out-Null
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Task #$cmdId finished, report transmitted." -ForegroundColor Green
                } catch {
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
                    $req = [System.Net.HttpWebRequest]::Create("$serverUrl/result")
                    $req.Method = "POST"
                    $req.ContentType = "application/json; charset=utf-8"
                    $req.Headers.Add("Token", $token)
                    $req.ContentLength = $bytes.Length
                    $reqStream = $req.GetRequestStream()
                    $reqStream.Write($bytes, 0, $bytes.Length)
                    $reqStream.Close()
                    $null = $req.GetResponse()
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Task #$cmdId finished, report transmitted (fallback)." -ForegroundColor Green
                }
            }
        } catch {}
        Start-Sleep -Milliseconds 600
    }
} catch {
    Write-Host "`n[X] Critical error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[*] Window kept open for debugging. Press any key to exit..." -ForegroundColor Yellow
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch {}
    while ($true) { Start-Sleep -Seconds 300 }
}
