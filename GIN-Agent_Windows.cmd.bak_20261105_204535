@echo off
:: ==============================================================================
:: GIN-Agent Windows PC Launcher v2026-11-05_v007
:: Author: VladiMIR+AI
:: Description: Universal 1-Click Remote Access Agent for Windows 10/11 (32/64-bit)
:: Gateway: Dual Resilient Fallback (Global / Russia) • Zero-Trace
:: ==============================================================================
chcp 65001 >nul
cls

:: Check for administrator rights; auto-elevate with UAC if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Запрос прав Администратора (UAC)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/k ""%~f0""' -Verb RunAs"
    exit /b
)

title GIN-Agent Windows PC [VladiMIR+AI]

echo ================================================================================
echo           GIN-AGENT WINDOWS PC - 1-CLICK ADMINISTRATOR LAUNCHER
echo ================================================================================
echo.
echo [*] Запуск универсального сервисного агента...
echo [*] Пожалуйста, не закрывайте это окно во время сервисного обслуживания.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText($args[0], [System.Text.Encoding]::UTF8); $tag = ':::POWERSHELL_PAYLOAD:::'; $pos = $raw.IndexOf($tag); if ($pos -ge 0) { & ([ScriptBlock]::Create($raw.Substring($pos + $tag.Length))) }" "%~f0"

echo.
echo ================================================================================
echo [*] Сессия GIN-Agent завершена. Окно оставлено открытым для диагностики.
echo [*] Вы можете закрыть это окно вручную.
echo ================================================================================
pause
exit /b

:::POWERSHELL_PAYLOAD:::
# ==============================================================================
# GIN-Agent Windows PC v2026-11-05_v007
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Universal 32-bit / 64-bit Windows Agent for Antigravity AI
# Gateways: Global (remote.gincz.com) & Russia (vds4you-208)
# ==============================================================================

$ErrorActionPreference = "Continue"

# Universal TLS 1.2 Configuration
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
} catch {
    try { [System.Net.ServicePointManager]::SecurityProtocol = 3072 } catch {}
}

$token = "GinCz-Remote-2026"
$headers = @{ "Token" = $token }

# Resilient Dual Gateway Selection (Global & Russia Fast Node)
$gateways = @(
    @{ Name = "Global (remote.gincz.com)"; Url = "https://remote.gincz.com/agent-api" },
    @{ Name = "Russia (RU-FastNode)"; Url = "http://195.158.255.208/agent-api" }
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

if (-not $admin) {
    Write-Warning "Внимание: Запущено без прав Администратора. Для полной диагностики рекомендуются права администратора."
}

# Host Architecture & Telemetry
$arch = if ([IntPtr]::Size -eq 8) { "64-bit" } else { "32-bit" }
$osName = "Microsoft Windows ($arch)"
$cpuName = "N/A"
$ramStr = "N/A"
$diskStr = "N/A"

try {
    $osInfo = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue)
    if ($osInfo) { $osName = "$($osInfo.Caption) ($arch)" }
} catch {}

try {
    $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cpuObj -and $cpuObj.Name) { $cpuName = $cpuObj.Name.Trim() }
} catch {}

try {
    if ($osInfo) {
        $freeRam = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 1)
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
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
        host = $env:COMPUTERNAME
        user = $env:USERNAME
        admin = $admin
        os = $osName
        cpu = $cpuName
        ram = $ramStr
        disk = $diskStr
        gateway = $activeGatewayName
        version = "v007"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
} catch {}

try {
    [Console]::Title = "GIN-Agent Windows PC [$activeGatewayName]"
} catch {}

Clear-Host
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       GIN-AGENT WINDOWS PC - REMOTE AI OPTIMIZATION PORTAL          " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "    Статус:     ПОДКЛЮЧЕНО К $activeGatewayName" -ForegroundColor White
Write-Host "    Привилегии: Administrator ($admin)" -ForegroundColor Yellow
Write-Host "    Хост:       $env:COMPUTERNAME ($env:USERNAME)" -ForegroundColor Cyan
Write-Host "    ОС / Архит: $osName" -ForegroundColor Gray
Write-Host "    Процессор:  $cpuName" -ForegroundColor DarkGray
Write-Host "    ОЗУ / Диск: $ramStr | $diskStr" -ForegroundColor DarkGray
Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "    [+] Уведомление о сессии отправлено в Telegram Владимиру." -ForegroundColor Green
Write-Host "    Система готова к проведению диагностики и аудита Antigravity." -ForegroundColor Gray
Write-Host "    [!] Не закрывайте это окно, пока Antigravity выполняет работы." -ForegroundColor Yellow
Write-Host "    (Для завершения сессии нажмите Ctrl+C или закройте окно)" -ForegroundColor DarkGray
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Ожидание задач от Antigravity AI..." -ForegroundColor Green

# Resilient Main Polling Loop
try {
    while ($true) {
        try {
            $headers = @{ "Token" = $token }
            $resp = Invoke-RestMethod -Uri "$serverUrl/poll" -Headers $headers -TimeoutSec 15 -ErrorAction SilentlyContinue
            if ($resp -and $resp.command) {
                $cmdId = $resp.id
                $cmdText = $resp.command
                Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Задача #$cmdId принята: $cmdText" -ForegroundColor Magenta
                
                $out = ""
                try {
                    $sb = [ScriptBlock]::Create($cmdText)
                    $out = & $sb 2>&1 | Out-String
                } catch {
                    $out = $_.Exception.Message
                }
                if (-not $out -or $out.Trim() -eq "") { $out = "[OK: Команда успешно выполнена без вывода]" }

                $bodyObj = @{
                    id = $cmdId
                    output = $out
                }
                $jsonBody = $bodyObj | ConvertTo-Json
                
                try {
                    Invoke-RestMethod -Uri "$serverUrl/result" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBody -TimeoutSec 15 -ErrorAction Stop | Out-Null
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Задача #$cmdId завершена, отчет передан." -ForegroundColor Green
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
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Задача #$cmdId завершена, отчет передан (fallback)." -ForegroundColor Green
                }
            }
        } catch {}
        Start-Sleep -Milliseconds 600
    }
} catch {
    Write-Host "`n[X] Исключение: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[*] Окно будет открыто для отладки." -ForegroundColor Yellow
    while ($true) { Start-Sleep -Seconds 300 }
}
