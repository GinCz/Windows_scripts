# =============================================================================
# Execution Context : Windows PowerShell 5.1+ (Run on PC-02 or Server ULPS1)
# Target Server     : PC-02 (Ulyana / Director PC)
# Description       : Ultarix Activity Report Generator & Analyzer (60-Day History)
# Author            : VladiMIR + Antigravity AI
# Version           : v1.0.0 (2026-11)
# =============================================================================

[CmdletBinding()]
param(
    [string]$TargetComputer = "PC-09",
    [int]$Days = 60,
    [string]$LogsDir = "\\ULPS1\ULTARIX\Monitoring",
    [switch]$OpenReport,
    [switch]$CheckLive
)

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "      ULTARIX s.r.o. - Аналитический отчет активности сотрудников             " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Компьютер директора: $env:COMPUTERNAME | Целевой ПК: $TargetComputer | Период: $Days дней" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Determine target directory
$compLogDir = "$LogsDir\$TargetComputer"
if (-not (Test-Path $compLogDir)) {
    # Fallback to direct administrative share if central share not yet mapped
    $fallbackDir = "\\$TargetComputer\C$\ProgramData\UltarixMonitor\logs\$TargetComputer"
    if (Test-Path $fallbackDir) {
        $compLogDir = $fallbackDir
        Write-Host "[*] Используется прямой административный доступ к $compLogDir" -ForegroundColor Yellow
    } else {
        Write-Host "[-] Папка с логами не найдена ни по пути $LogsDir, ни по прямому доступу к $TargetComputer" -ForegroundColor Red
        Write-Host "    Проверьте, установлен ли агент на $TargetComputer и запущен ли сбор логов." -ForegroundColor DarkYellow
        return
    }
}

# Live status check
$heartbeatFile = "$compLogDir\current_status.json"
if (Test-Path $heartbeatFile) {
    try {
        $hbJson = Get-Content $heartbeatFile -Raw -Encoding utf8 | ConvertFrom-Json
        Write-Host "[● ТЕКУЩИЙ СТАТУС В РЕАЛЬНОМ ВРЕМЕНИ]:" -ForegroundColor Magenta
        Write-Host "  Время обновления : $($hbJson.timestamp)" -ForegroundColor White
        Write-Host "  Пользователь     : $($hbJson.user)" -ForegroundColor White
        Write-Host "  Состояние        : $(if($hbJson.state -eq 'ACTIVE'){'АКТИВЕН (Работает)'}else{'ПАУЗА / ОТОШЕЛ'})" -ForegroundColor $(if($hbJson.state -eq 'ACTIVE'){'Green'}else{'Yellow'})
        Write-Host "  Программа сейчас : $($hbJson.process)" -ForegroundColor Cyan
        Write-Host "  Заголовок окна   : $($hbJson.window_title)" -ForegroundColor Cyan
        Write-Host "  Бездействие (AFK): $($hbJson.idle_sec) сек" -ForegroundColor DarkGray
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
    } catch {}
}

if ($CheckLive) { return }

# Read and aggregate CSV logs for the specified period
$startDate = (Get-Date).AddDays(-$Days)
$csvFiles = Get-ChildItem -Path $compLogDir -Filter "activity_*.csv" -ErrorAction SilentlyContinue | Where-Object {
    $_.LastWriteTime -ge $startDate
}

if (-not $csvFiles -or $csvFiles.Count -eq 0) {
    Write-Host "[-] За последние $Days дней логов для $TargetComputer не найдено." -ForegroundColor Yellow
    return
}

Write-Host "[*] Загрузка и анализ $($csvFiles.Count) файлов логов..." -ForegroundColor Yellow

$allRecords = @()
foreach ($file in $csvFiles) {
    try {
        $records = Import-Csv -Path $file.FullName -Encoding utf8 -ErrorAction SilentlyContinue
        if ($records) {
            $allRecords += $records
        }
    } catch {}
}

if ($allRecords.Count -eq 0) {
    Write-Host "[-] В логах нет записей активности." -ForegroundColor Yellow
    return
}

# Metrics calculation
$totalDurationSec = 0
$activeDurationSec = 0
$idleDurationSec = 0
$appTimeTable = @{}
$dailyBreakdown = @{}

foreach ($row in $allRecords) {
    $dur = [int]$row.DurationSec
    if ($dur -le 0) { continue }

    $totalDurationSec += $dur
    if ($row.State -eq "IDLE" -or $row.ProcessName -eq "IDLE_PAUSE") {
        $idleDurationSec += $dur
    } else {
        $activeDurationSec += $dur
        $proc = $row.ProcessName
        if (-not $appTimeTable.ContainsKey($proc)) {
            $appTimeTable[$proc] = 0
        }
        $appTimeTable[$proc] += $dur
    }

    # Daily grouping
    $dayKey = $row.StartTime.Substring(0, 10)
    if (-not $dailyBreakdown.ContainsKey($dayKey)) {
        $dailyBreakdown[$dayKey] = @{ Active = 0; Idle = 0 }
    }
    if ($row.State -eq "IDLE" -or $row.ProcessName -eq "IDLE_PAUSE") {
        $dailyBreakdown[$dayKey].Idle += $dur
    } else {
        $dailyBreakdown[$dayKey].Active += $dur
    }
}

function Format-Duration([int]$sec) {
    $ts = [TimeSpan]::FromSeconds($sec)
    return "{0:D2} ч {1:D2} мин {2:D2} сек" -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds
}

Write-Host ""
Write-Host "================ СВОДКА ЗА $Days ДНЕЙ ($TargetComputer) ================" -ForegroundColor Green
Write-Host " Всего зафиксировано времени : $(Format-Duration $totalDurationSec)" -ForegroundColor White
Write-Host " Чистое активное время работы: $(Format-Duration $activeDurationSec) ($([math]::Round(($activeDurationSec / [math]::Max($totalDurationSec, 1)) * 100, 1))%)" -ForegroundColor Green
Write-Host " Время пауз и бездействия    : $(Format-Duration $idleDurationSec) ($([math]::Round(($idleDurationSec / [math]::Max($totalDurationSec, 1)) * 100, 1))%)" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray

Write-Host ""
Write-Host "ТОП ИСПОЛЬЗУЕМЫХ ПРОГРАММ (ЧИСТОЕ РАБОЧЕЕ ВРЕМЯ):" -ForegroundColor Cyan
$topApps = $appTimeTable.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
foreach ($app in $topApps) {
    $percent = [math]::Round(($app.Value / [math]::Max($activeDurationSec, 1)) * 100, 1)
    $formatted = Format-Duration $app.Value
    Write-Host ("  {0,-25} : {1,-18} ({2,5}%)" -f $app.Key, $formatted, $percent) -ForegroundColor White
}

Write-Host ""
Write-Host "ПОСЛЕДНИЕ 7 ДНЕЙ (РАЗБИВКА ПО ДНЯМ):" -ForegroundColor Cyan
$dailyBreakdown.GetEnumerator() | Sort-Object Name -Descending | Select-Object -First 7 | ForEach-Object {
    $d = $_.Name
    $act = Format-Duration $_.Value.Active
    $idl = Format-Duration $_.Value.Idle
    Write-Host ("  Дата: {0} | Активно: {1,-16} | Паузы: {2,-16}" -f $d, $act, $idl) -ForegroundColor Gray
}

# Generate HTML Interactive Report
$htmlReportPath = "$env:TEMP\Ultarix_Report_$TargetComputer.html"

$appJson = ($topApps | ForEach-Object { "{ name: '$($_.Key)', seconds: $($_.Value), percent: $([math]::Round(($_.Value / [math]::Max($activeDurationSec, 1)) * 100, 1)) }" }) -join ","
$dailyJson = ($dailyBreakdown.GetEnumerator() | Sort-Object Name -Descending | Select-Object -First 14 | ForEach-Object {
    "{ date: '$($_.Name)', activeMin: $([math]::Round($_.Value.Active / 60)), idleMin: $([math]::Round($_.Value.Idle / 60)) }"
}) -join ","

$htmlContent = @"
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>ULTARIX - Отчет активности $TargetComputer</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 24px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #334155; padding-bottom: 16px; margin-bottom: 24px; }
        .logo { font-size: 24px; font-weight: bold; color: #38bdf8; }
        .badge { background: #1e293b; padding: 6px 12px; border-radius: 6px; border: 1px solid #475569; font-size: 14px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 18px; }
        .card-title { font-size: 13px; color: #94a3b8; text-transform: uppercase; margin-bottom: 8px; }
        .card-value { font-size: 26px; font-weight: bold; }
        .val-green { color: #4ade80; }
        .val-yellow { color: #facc15; }
        .val-blue { color: #38bdf8; }
        .table-box { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 20px; margin-bottom: 24px; }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th { color: #94a3b8; font-size: 13px; border-bottom: 1px solid #334155; padding: 10px 8px; }
        td { border-bottom: 1px solid #1e293b; padding: 12px 8px; font-size: 14px; }
        .bar-container { background: #334155; border-radius: 4px; height: 10px; width: 100%; overflow: hidden; margin-top: 4px; }
        .bar-fill { height: 100%; background: #38bdf8; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">ULTARIX s.r.o. — Мониторинг сотрудников</div>
        <div class="badge">Компьютер: <strong>$TargetComputer</strong> | Период: <strong>$Days дней</strong></div>
    </div>

    <div class="grid">
        <div class="card">
            <div class="card-title">Всего мониторинга</div>
            <div class="card-value val-blue">$(Format-Duration $totalDurationSec)</div>
        </div>
        <div class="card">
            <div class="card-title">Чистое рабочее время</div>
            <div class="card-value val-green">$(Format-Duration $activeDurationSec)</div>
        </div>
        <div class="card">
            <div class="card-title">Время пауз / бездействия</div>
            <div class="card-value val-yellow">$(Format-Duration $idleDurationSec)</div>
        </div>
    </div>

    <div class="table-box">
        <h3>Топ используемых программ за период</h3>
        <table>
            <thead>
                <tr>
                    <th>Программа</th>
                    <th>Затраченное время</th>
                    <th>Доля от работы</th>
                    <th>Визуализация</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($app in $topApps) {
    $pct = [math]::Round(($app.Value / [math]::Max($activeDurationSec, 1)) * 100, 1)
    $fmt = Format-Duration $app.Value
    $htmlContent += @"
                <tr>
                    <td><strong>$($app.Key)</strong></td>
                    <td>$fmt</td>
                    <td>$pct%</td>
                    <td style="width: 30%;"><div class="bar-container"><div class="bar-fill" style="width: $pct%;"></div></div></td>
                </tr>
"@
}

$htmlContent += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@

$htmlContent | Set-Content -Path $htmlReportPath -Encoding utf8

Write-Host ""
Write-Host "[OK] Интерактивный HTML-отчет сгенерирован: $htmlReportPath" -ForegroundColor Green

if ($OpenReport) {
    Start-Process $htmlReportPath
}
