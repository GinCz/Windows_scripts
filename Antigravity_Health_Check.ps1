<#
.SYNOPSIS
    Antigravity Health Check & Maintenance Audit Utility
    Author: Vladimir Bulantsev (@GinCz) & AI
    Repository: GinCz/Windows_scripts
.DESCRIPTION
    Audits and purges stale Antigravity daemon hubs, orphan session locks, and crash logs
    to prevent socket connection timeouts and chat startup freezes.
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
$stateFile = Join-Path $appData "last_health_check.json"

$currentDate = Get-Date
$isMonday = ($currentDate.DayOfWeek -eq [System.DayOfWeek]::Monday)

# Check if already run this week (unless -Force)
if (-not $Force -and (Test-Path $stateFile)) {
    try {
        $lastState = Get-Content -Path $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($lastState.LastRun) {
            $lastRunDate = [DateTime]::Parse($lastState.LastRun)
            $diffDays = ($currentDate - $lastRunDate).TotalDays
            # If not Monday and ran less than 5 days ago, skip unless forced
            if (-not $isMonday -and $diffDays -lt 5) {
                Write-Host "Antigravity Health Check: Already verified within this cycle ($($lastState.LastRun)). Skipping." -ForegroundColor DarkGray
                return
            }
        }
    } catch {}
}

Write-Host "=== Antigravity Health Check & Maintenance Audit ===" -ForegroundColor Cyan

$cleanedHubs = 0
$activeHubs = 0
$cleanedLocks = 0
$activeLocks = 0

# 1. Audit Daemon Hubs
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

# 2. Audit Presence Locks
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

# 4. Save Health State
if (-not $CheckOnly) {
    $state = [PSCustomObject]@{
        LastRun = $currentDate.ToString("yyyy-MM-dd HH:mm:ss")
        DayOfWeek = $currentDate.DayOfWeek.ToString()
        ActiveHubs = $activeHubs
        CleanedHubs = $cleanedHubs
        ActiveLocks = $activeLocks
        CleanedLocks = $cleanedLocks
        CleanedCrashes = $cleanedCrashes
        Status = "Healthy"
    }
    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

Write-Host "Audit Complete: Active Hubs: $activeHubs | Cleaned Hubs: $cleanedHubs | Active Locks: $activeLocks | Cleaned Locks: $cleanedLocks" -ForegroundColor Green
