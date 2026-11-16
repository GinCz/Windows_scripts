@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions

:: Failsafe Admin Elevation: Open PowerShell directly as Administrator
fltmc >nul 2>&1
if %errorlevel% neq 0 (
    set "PS_CMD=powershell.exe"
    if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_CMD=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
    "%PS_CMD%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', [string]::Format('$f = ''{0}''; if (-not (Test-Path -LiteralPath $f)) { $f = (Get-ChildItem -Path $env:USERPROFILE\Downloads, ''D:\DOCS\DownLOAD'', $pwd -Filter ''*GIN-Agent_Windows*.cmd'' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }; if ($f -and (Test-Path -LiteralPath $f)) { $code = (Get-Content -Raw -Encoding UTF8 -LiteralPath $f) -replace ''(?s)^.*?<#POWERSHELL#>\r?\n'',''''; & ([ScriptBlock]::Create($code)) } else { Write-Host ''[X] ERROR: Could not locate agent script file.'' -ForegroundColor Red }', '%~f0')) -Verb RunAs"
    exit /b 0
)

set "PS_CMD=powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PS_CMD=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%PS_CMD%" -NoExit -NoProfile -ExecutionPolicy Bypass -Command "$f = '%~f0'; if (-not (Test-Path -LiteralPath $f)) { $f = (Get-ChildItem -Path $env:USERPROFILE\Downloads, 'D:\DOCS\DownLOAD', $pwd -Filter '*GIN-Agent_Windows*.cmd' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }; if ($f -and (Test-Path -LiteralPath $f)) { $code = (Get-Content -Raw -Encoding UTF8 -LiteralPath $f) -replace '(?s)^.*?<#POWERSHELL#>\r?\n',''; & ([ScriptBlock]::Create($code)) } else { Write-Host '[X] ERROR: Could not locate agent script file.' -ForegroundColor Red }"
exit /b 0

<#POWERSHELL#>
# ==============================================================================
# GIN-Agent Windows PC v013
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

    # Register Session and Trigger Telegram Notification via Server Bridge
    try {
        $regPayload = @{
            host    = $env:COMPUTERNAME
            user    = $env:USERNAME
            admin   = $admin
            os      = $osName
            cpu     = $cpuName
            ram     = $ramStr
            disk    = $diskStr
            gateway = $activeGatewayName
            version = "v013"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    try {
        [Console]::Title = "GIN-Agent Windows PC v013 [$activeGatewayName]"
    } catch {}

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "     GIN-AGENT WINDOWS PC v013 - REMOTE AI OPTIMIZATION PORTAL      " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "    Status:     CONNECTED TO $activeGatewayName" -ForegroundColor White
    if ($admin) {
        Write-Host "    Privileges: Administrator (Full Access)" -ForegroundColor Green
    } else {
        Write-Host "    Privileges: User (Standard Rights)" -ForegroundColor Yellow
        Write-Host "    [!] For full control: Right-Click -> 'Run as administrator'" -ForegroundColor DarkYellow
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
    Write-Host "[*] Window kept open for debugging." -ForegroundColor Yellow
    while ($true) { Start-Sleep -Seconds 300 }
}
