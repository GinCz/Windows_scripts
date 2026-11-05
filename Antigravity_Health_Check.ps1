<#
.SYNOPSIS
    Antigravity Health Check & Maintenance Audit Utility
    Author: Vladimir Bulantsev (@GinCz) & AI
    Repository: GinCz/Windows_scripts
.DESCRIPTION
    Audits and purges stale Antigravity daemon hubs, orphan session locks, crash logs,
    and performs SQLite database optimization (WAL checkpoint & VACUUM) to prevent
    freezes, high latency, and startup delays.
#>

[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Continue"
$appData = Join-Path $env:USERPROFILE ".gemini\antigravity"
$daemonDir = Join-Path $appData "daemon"
$presenceDir = Join-Path $appData "presence"
$crashesDir = Join-Path $appData "crashes"
$convsDir = Join-Path $appData "conversations"
$stateFile = Join-Path $appData "last_health_check.json"

$currentDate = Get-Date
$isMonday = ($currentDate.DayOfWeek -eq [System.DayOfWeek]::Monday)

Write-Host "=== Antigravity Health Check & Maintenance Audit ===" -ForegroundColor Cyan

$cleanedHubs = 0
$activeHubs = 0
$cleanedLocks = 0
$activeLocks = 0
$optimizedDbs = 0

# 1. Audit Daemon Hubs (Always executed)
if (Test-Path $daemonDir) {
    $hubFiles = Get-ChildItem -Path "$daemonDir\hub_*.json" -ErrorAction SilentlyContinue
    foreach ($hub in $hubFiles) {
        $isStale = $false
        try {
            $json = Get-Content -Path $hub.FullName -Raw | ConvertFrom-Json
            $proc = Get-Process -Id $json.pid -ErrorAction SilentlyContinue
            if (-not $proc -or $proc.ProcessName -notmatch "language_server|antigravity") {
                $isStale = $true
            } else {
                $activeHubs++
            }
        } catch {
            $isStale = $true
        }

        if ($isStale) {
            if (-not $CheckOnly) {
                Remove-Item -Path $hub.FullName -Force -ErrorAction SilentlyContinue
            }
            $cleanedHubs++
            Write-Host "  [PURGE] Stale daemon hub: $($hub.Name)" -ForegroundColor Yellow
        }
    }
}

# 2. Audit Presence Locks (Always executed to prevent chat freezes)
if (Test-Path $presenceDir) {
    $lockFiles = Get-ChildItem -Path "$presenceDir\*.lock" -ErrorAction SilentlyContinue
    foreach ($lock in $lockFiles) {
        $unlocked = $false
        try {
            $stream = [System.IO.File]::Open($lock.FullName, 'Open', 'ReadWrite', 'None')
            $stream.Close()
            $unlocked = $true
        } catch {
            $activeLocks++
        }

        if ($unlocked) {
            if (-not $CheckOnly) {
                Remove-Item -Path $lock.FullName -Force -ErrorAction SilentlyContinue
            }
            $cleanedLocks++
            Write-Host "  [PURGE] Orphan session lock: $($lock.Name)" -ForegroundColor Yellow
        }
    }
}

# 3. Clean Stale Crash Logs (> 7 days)
$cleanedCrashes = 0
if (Test-Path $crashesDir) {
    Get-ChildItem -Path "$crashesDir\*.log" -ErrorAction SilentlyContinue | Where-Object {
        $_.LastWriteTime -lt $currentDate.AddDays(-7)
    } | ForEach-Object {
        try {
            if (-not $CheckOnly) {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
            $cleanedCrashes++
        } catch {}
    }
}

# 4. SQLite Optimization & Compaction (Monday or -Force)
$pyExe = "C:\Users\USER\.local\bin\python3.14.exe"
if (($Force -or $isMonday) -and (Test-Path $pyExe)) {
    Write-Host "  [OPTIMIZE] Running SQLite WAL checkpoint and VACUUM..." -ForegroundColor Cyan
    $dbFiles = @()
    $sumDb = Join-Path $appData "conversation_summaries.db"
    if (Test-Path $sumDb) { $dbFiles += $sumDb }
    if (Test-Path $convsDir) {
        $dbFiles += (Get-ChildItem -Path "$convsDir\*.db" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }

    foreach ($db in $dbFiles) {
        try {
            & $pyExe -c "import sqlite3; con = sqlite3.connect(r'$db'); con.execute('PRAGMA wal_checkpoint(TRUNCATE);'); con.execute('VACUUM;'); con.execute('PRAGMA optimize;'); con.close()" 2>$null
            $optimizedDbs++
        } catch {}
    }
    Write-Host "  [OPTIMIZE] Compacted and verified $optimizedDbs SQLite databases" -ForegroundColor Green
}

# 5. Save Health State
if (-not $CheckOnly) {
    $state = [PSCustomObject]@{
        LastRun = $currentDate.ToString("yyyy-MM-dd HH:mm:ss")
        DayOfWeek = $currentDate.DayOfWeek.ToString()
        ActiveHubs = $activeHubs
        CleanedHubs = $cleanedHubs
        ActiveLocks = $activeLocks
        CleanedLocks = $cleanedLocks
        CleanedCrashes = $cleanedCrashes
        OptimizedDbs = $optimizedDbs
        Status = "Healthy"
    }
    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

Write-Host "Audit Complete: Active Hubs: $activeHubs | Cleaned Hubs: $cleanedHubs | Active Locks: $activeLocks | Cleaned Locks: $cleanedLocks | Optimized DBs: $optimizedDbs" -ForegroundColor Green
