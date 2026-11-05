@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>&1
cls

title GIN-Agent Windows PC [VladiMIR+AI]

echo ================================================================================
echo           GIN-AGENT WINDOWS PC - 1-CLICK REMOTE ACCESS AGENT
echo                              [VladiMIR+AI]
echo ================================================================================
echo.
echo [*] Инициализация сервисного агента...

set "GIN_AGENT_FILE=%~f0"
if "%GIN_AGENT_FILE%"=="" set "GIN_AGENT_FILE=%CD%\GIN-Agent_Windows.cmd"

powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -Command "$f = $env:GIN_AGENT_FILE; if (-not $f -or -not (Test-Path -LiteralPath $f)) { $f = (Get-ChildItem -Path $env:USERPROFILE\Downloads, $pwd -Filter '*GIN-Agent_Windows*.cmd' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName }; if ($f -and (Test-Path -LiteralPath $f)) { $code = (Get-Content -LiteralPath $f -Raw -Encoding UTF8) -replace '(?s)^.*?::POWERSHELL_START::\r?\n',''; iex $code } else { Write-Host '[X] Ошибка: Не удалось определить путь к файлу агента.' -ForegroundColor Red }"

echo.
echo ================================================================================
echo [*] Сессия GIN-Agent завершена. Окно оставлено открытым для диагностики.
echo [*] Вы можете закрыть это окно вручную или нажать любую клавишу.
echo ================================================================================
pause
exit /b

::POWERSHELL_START::
# ==============================================================================
# GIN-Agent Windows PC v011
# Author: Vladimir Bulantsev (GinCz) & Antigravity
# Universal 32-bit / 64-bit Windows Agent for Antigravity AI
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
        "Token" = $token
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
            version = "v011"
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$serverUrl/register" -Method Post -Headers $headers -ContentType "application/json; charset=utf-8" -Body $regPayload -TimeoutSec 6 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    try {
        [Console]::Title = "GIN-Agent Windows PC [$activeGatewayName]"
    } catch {}

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "       GIN-AGENT WINDOWS PC - REMOTE AI OPTIMIZATION PORTAL          " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "    Статус:     ПОДКЛЮЧЕНО К $activeGatewayName" -ForegroundColor White
    if ($admin) {
        Write-Host "    Привилегии: Administrator (Полный доступ)" -ForegroundColor Green
    } else {
        Write-Host "    Привилегии: Пользователь (Стандартные права)" -ForegroundColor Yellow
        Write-Host "    [!] Для полного системного контроля: ПКМ -> 'Запуск от имени администратора'" -ForegroundColor DarkYellow
    }
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
    while ($true) {
        try {
            $headers = @{ 
                "Token" = $token
                "X-Host" = $env:COMPUTERNAME
            }
            $pollUrl = "$serverUrl/poll?h=$env:COMPUTERNAME"
            $resp = Invoke-RestMethod -Uri $pollUrl -Headers $headers -TimeoutSec 15 -ErrorAction SilentlyContinue
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
    Write-Host "`n[X] Критическая ошибка: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[*] Окно зафиксировано для диагностики." -ForegroundColor Yellow
    while ($true) { Start-Sleep -Seconds 300 }
}
