<# :
@echo off
setlocal DisableDelayedExpansion
title ULTARIX Monitor - Fast Updater to v008

net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_UPDATE

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs" >nul 2>&1
exit /b 0

:RUN_UPDATE
set "PS_EXE=powershell.exe"
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); & ([ScriptBlock]::Create($raw))"
timeout /t 3 >nul 2>&1
exit /b 0
#>
# ==============================================================================
# Fast 1-Click In-Place Updater to v008 (Zero Questions)
# ==============================================================================
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       ULTARIX MONITOR - INSTANT UPDATE TO v008                     " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan

$agentDir = "$env:ProgramData\Ultarix-Monitor"
$agentFile = "$agentDir\agent.ps1"
if (-not (Test-Path $agentDir)) { New-Item -ItemType Directory -Path $agentDir -Force | Out-Null }

# 1. Stop existing process
Write-Host "[*] Restarting agent service..." -ForegroundColor Yellow
schtasks /end /tn "Ultarix-Monitor" 2>$null | Out-Null
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*Ultarix-Monitor*agent.ps1*" -and $_.ProcessId -ne $PID
} | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}

# 2. Write v008 agent.ps1
$newAgent = @'
﻿# ==============================================================================
# ULTARIX s.r.o. - Background Activity Collector Daemon
# Runs silently 24/7 without windows or tray icons
# Version: v008 (Mon_v008)
# ==============================================================================
try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288 } catch { try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {} }

$PollIntervalSec = 5
$IdleThresholdSec = 180
$CloudPushIntervalSec = 10
$MonitorVersion = "Mon_v008"
$CloudUrl = "https://ultarix.gincz.com/api/push"
$ApiToken = "Ultarix-Monitor-2026"
$ServerShares = @("\\ulps1\UTIL\UltarixMonitor\logs", "\\ulps1\UTIL\Ultarix-Monitor\logs")

function Get-CanonicalName($rawName) {
    if (-not $rawName) { return "UNKNOWN" }
    $n = ($rawName).Trim().ToLower()
    $map = @{
        "pc-02" = "U-002"; "ulka-02" = "U-002"; "ultarix-02" = "U-002"; "u-02" = "U-002"; "u-002" = "U-002";
        "pc-03" = "U-003"; "ultarix-03" = "U-003"; "u-03" = "U-003"; "u-003" = "U-003";
        "pc-04" = "U-004"; "ultarix-04" = "U-004"; "u-04" = "U-004"; "u-004" = "U-004";
        "pc-05" = "U-005"; "ultarix-05" = "U-005"; "u-05" = "U-005"; "u-005" = "U-005";
        "pc-06" = "U-006"; "ultarix-06" = "U-006"; "u-06" = "U-006"; "u-006" = "U-006";
        "007" = "U-007"; "pc-07" = "U-007"; "u-07" = "U-007"; "ulta_007" = "U-007"; "ultarix-07" = "U-007"; "u-007" = "U-007";
        "pc-08" = "U-008"; "ultarix-08" = "U-008"; "u-08" = "U-008"; "u-008" = "U-008";
        "pc-09" = "U-009"; "ultarix-09" = "U-009"; "u-09" = "U-009"; "u-009" = "U-009";
        "pc-010" = "U-010"; "ultarix-010" = "U-010"; "u-010" = "U-010"; "u-10" = "U-010"; "pc-10" = "U-010";
        "u-507" = "U-507"; "u-510" = "U-510"; "u-511" = "U-511"; "u-512" = "U-512";
        "ulps1" = "ULPS1";
    }
    if ($map.ContainsKey($n)) { return $map[$n] }
    return $rawName.ToUpper()
}

$comp = Get-CanonicalName $env:COMPUTERNAME
$user = $env:USERNAME

# Terminate duplicate agent instances to guarantee strictly 1 active process
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*agent.ps1*" -and $_.ProcessId -ne $PID
} | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}

$win32 = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32x86 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleMillis() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(lii);
        if (GetLastInputInfo(ref lii)) {
            uint cur = unchecked((uint)Environment.TickCount);
            return (cur >= lii.dwTime) ? (cur - lii.dwTime) : (cur + (uint.MaxValue - lii.dwTime));
        }
        return 0;
    }
}
"@
if (-not ([System.Management.Automation.PSTypeName]"Win32x86").Type) {
    Add-Type -TypeDefinition $win32 -ErrorAction SilentlyContinue
}

$localData = "$env:ProgramData\Ultarix-Monitor"
$localLogs = "$localData\logs\$comp"
$null = New-Item -ItemType Directory -Path $localLogs -Force -ErrorAction SilentlyContinue

function Get-ActiveRemoteShare {
    foreach ($sh in $ServerShares) {
        if (Test-Path $sh -ErrorAction SilentlyContinue) {
            $compDir = "$sh\$comp"
            if (-not (Test-Path $compDir -ErrorAction SilentlyContinue)) {
                $null = New-Item -ItemType Directory -Path $compDir -Force -ErrorAction SilentlyContinue
            }
            return $sh
        }
    }
    return ""
}

function Push-ToCloud($currentStatusObj, $todayObj) {
    try {
        $payload = [PSCustomObject]@{
            computer = $comp
            version = $MonitorVersion
            current_status = $currentStatusObj
            today = $todayObj
        }
        $json = $payload | ConvertTo-Json -Depth 5 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

        $req = [System.Net.HttpWebRequest]::Create($CloudUrl)
        $req.Method = "POST"
        $req.ContentType = "application/json; charset=utf-8"
        $req.Headers.Add("Authorization", "Bearer $ApiToken")
        $req.Timeout = 4000
        $req.ReadWriteTimeout = 4000
        $req.ContentLength = $bytes.Length

        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()

        $resp = $req.GetResponse()
        $resp.Close()
    } catch {}
}

function Update-DayJs($date) {
    try {
        $csv = "$localLogs\activity_$date.csv"
        if (-not (Test-Path $csv)) { return $null }
        $lines = Get-Content $csv -Encoding utf8 -ErrorAction SilentlyContinue
        if ($null -eq $lines -or $lines.Count -le 1) { return $null }

        $appMap = @{}
        $parsedLines = @()
        $lastActiveIdx = -1

        for ($i = 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line.Split(",")
            if ($parts.Count -lt 7) { continue }
            $dur = 0
            [int]::TryParse($parts[2], [ref]$dur) | Out-Null
            if ($dur -le 0) { continue }
            $proc = $parts[5].Trim()
            $win = ""
            if ($parts.Count -ge 8) {
                $winParts = $parts[6..($parts.Count - 2)]
                $win = ($winParts -join ",") -replace '^"|"$', "" -replace '""', '"'
                $st = $parts[$parts.Count - 1].Trim()
            } else {
                $win = $parts[6].Trim() -replace '^"|"$', "" -replace '""', '"'
                $st = "ACTIVE"
            }

            $rec = @{ dur = $dur; proc = $proc; win = $win; st = $st }
            $parsedLines += $rec
        }

        $firstActiveIdx = -1
        $lastActiveIdx = -1
        for ($i = 0; $i -lt $parsedLines.Count; $i++) {
            $rec = $parsedLines[$i]
            $st = $rec.st
            $proc = $rec.proc
            if ($st -eq "ACTIVE" -and $proc -ne "IDLE_PAUSE" -and $proc -ne "Unknown" -and $proc -ne "") {
                if ($firstActiveIdx -lt 0) { $firstActiveIdx = $i }
                $lastActiveIdx = $i
            }
        }

        $totSec = 0
        $actSec = 0
        $idleSec = 0

        # Vladimir's Rule:
        # If no active work, idle and work are strictly 0.
        # Trailing idle after last activity of the day is NOT counted as a pause.
        # Idle before first activity of the day is NOT counted as a pause.
        # Only idle BETWEEN active working sessions is counted as pause!
        if ($lastActiveIdx -ge 0) {
            for ($i = 0; $i -lt $parsedLines.Count; $i++) {
                if ($i -lt $firstActiveIdx -or $i -gt $lastActiveIdx) {
                    continue
                }
                $rec = $parsedLines[$i]
                $dur = $rec.dur
                $proc = $rec.proc
                $win = $rec.win
                $st = $rec.st

                $appKey = $proc
                $disp = $proc
                $icon = "📱"
                $color = "blue"

                $pLower = ($proc).ToLower()
                $wTitle = ($win).Trim()
                $cleanWin = $wTitle -replace "^(?i)(Administrator:\s*|\s*Správce:\s*)", ""

                if ($pLower -eq "cmd" -or $pLower -eq "cmd.exe" -or $pLower -like "*stereo*" -or $pLower.StartsWith("cmd-") -or $pLower.StartsWith("cmd -")) {
                    if ($cleanWin -match "(?i)stereo\s*(\d+)") {
                        $appKey = "cmd-Stereo$($Matches[1])"
                        $disp = "cmd-Stereo$($Matches[1])"
                        $icon = "🦔"
                        $color = "orange"
                    } elseif ($cleanWin -match "(?i)gin-agent") {
                        $appKey = "cmd - GIN-Agent"
                        $disp = "cmd - GIN-Agent"
                        $icon = "🤖"
                        $color = "blue"
                    } elseif ($cleanWin -match "(?i)instalace|setup|monitor") {
                        $appKey = "cmd - Instalace monitoringu"
                        $disp = "cmd - Instalace monitoringu"
                        $icon = "⚙️"
                        $color = "blue"
                    } elseif ($cleanWin -match "(?i)ježek|stereo") {
                        $appKey = "cmd-Stereo"
                        $disp = "cmd-Stereo"
                        $icon = "🦔"
                        $color = "orange"
                    } elseif ($pLower -match "(?i)stereo\s*(\d+)") {
                        $appKey = "cmd-Stereo$($Matches[1])"
                        $disp = "cmd-Stereo$($Matches[1])"
                        $icon = "🦔"
                        $color = "orange"
                    } elseif ($cleanWin -and $cleanWin -ne "cmd.exe" -and $cleanWin -notlike "*system32\cmd.exe*") {
                        $appKey = "cmd - $cleanWin"
                        $disp = "cmd - $cleanWin"
                        $icon = "💻"
                        $color = "blue"
                    } else {
                        $appKey = "cmd"
                        $disp = "cmd"
                        $icon = "💻"
                        $color = "blue"
                    }
                } elseif ($pLower -like "*powershell*" -or $pLower -like "*pwsh*") {
                    if ($cleanWin -and $cleanWin -notmatch "^(?i)(windows powershell|powershell|pwsh)$") {
                        $appKey = "powershell - $cleanWin"
                        $disp = "powershell - $cleanWin"
                        $icon = "⚡"
                        $color = "blue"
                    } else {
                        $appKey = "PowerShell"
                        $disp = "PowerShell"
                        $icon = "⚡"
                        $color = "blue"
                    }
                } elseif ($pLower -like "*ekonom*") {
                    $icon = "💼"; $color = "blue"; $disp = "$proc (Ekonom.win)"
                } elseif ($pLower -like "*chrome*") {
                    $icon = "🌐"; $color = "purple"; $disp = "$proc (Google Chrome)"
                } elseif ($pLower -like "*brave*") {
                    $icon = "🦁"; $color = "orange"; $disp = "$proc (Brave Browser)"
                } elseif ($pLower -like "*firefox*") {
                    $icon = "🦊"; $color = "orange"; $disp = "$proc (Mozilla Firefox)"
                } elseif ($pLower -like "*edge*") {
                    $icon = "🌀"; $color = "blue"; $disp = "$proc (Microsoft Edge)"
                } elseif ($pLower -like "*excel*") {
                    $icon = "📊"; $color = "green"; $disp = "$proc (Microsoft Excel)"
                } elseif ($pLower -like "*word*") {
                    $icon = "📝"; $color = "blue"; $disp = "$proc (Microsoft Word)"
                } elseif ($pLower -like "*telegram*") {
                    $icon = "✈️"; $color = "blue"; $disp = "$proc (Telegram)"
                }

                if ($st -eq "ACTIVE" -and $proc -ne "IDLE_PAUSE" -and $proc -ne "Unknown" -and $proc -ne "") {
                    $actSec += $dur
                    $totSec += $dur

                    if (-not $appMap.ContainsKey($appKey)) {
                        $appMap[$appKey] = @{
                            name = $disp
                            icon = $icon
                            color = $color
                            durationSec = 0
                            pages = @{}
                        }
                    }

                    $appMap[$appKey].durationSec += $dur
                    $wKey = if ($win) { $win } else { "Hlavní okno programu" }
                    if (-not $appMap[$appKey].pages.ContainsKey($wKey)) {
                        $appMap[$appKey].pages[$wKey] = 0
                    }
                    $appMap[$appKey].pages[$wKey] += $dur
                } elseif ($st -eq "IDLE" -or $proc -eq "IDLE_PAUSE") {
                    # Internal pause between active work sessions
                    # Vladimir's Rule: A single pause between work sessions cannot be an overnight/long gap (> 2 hours = 7200s)!
                    if ($dur -le 7200) {
                        $idleSec += $dur
                        $totSec += $dur
                    }
                }
            }

            # Vladimir's Rule:
            # If all activity occurred in only 1 session, there are no intermediate pauses -> idle is strictly 0.
            # If total active work is brief (< 30 min) and idle is massive (> 1 hour), it's overnight/trailing -> 0.
            if ($firstActiveIdx -eq $lastActiveIdx -or ($actSec -lt 1800 -and $idleSec -gt 7200)) {
                $idleSec = 0
                $totSec = $actSec
            }
        }

        $appList = @()
        foreach ($k in $appMap.Keys) {
            $a = $appMap[$k]
            $pgList = @()
            foreach ($w in $a.pages.Keys) {
                $pgList += @{ title = $w; durationSec = $a.pages[$w] }
            }
            $sortedPg = $pgList | Sort-Object -Property durationSec -Descending
            $appList += @{
                name = $a.name
                icon = $a.icon
                color = $a.color
                durationSec = $a.durationSec
                pages = @($sortedPg)
            }
        }
        $sortedApps = @($appList | Sort-Object -Property durationSec -Descending)

        $actSec = [math]::Max(0, $totSec - $idleSec)
        $obj = @{
            date = $date
            computer = $comp
            totalMonitoredSec = $totSec
            activeSec = $actSec
            idleSec = $idleSec
            apps = $sortedApps
        }

        $json = $obj | ConvertTo-Json -Depth 5 -Compress
        $js = "window.updateDaySummary && window.updateDaySummary('$comp', '$date', $json);"

        $js | Set-Content -Path "$localLogs\today.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        $json | Set-Content -Path "$localLogs\today.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        $js | Set-Content -Path "$localLogs\activity_$date.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue

        $sh = Get-ActiveRemoteShare
        if ($sh -ne "") {
            $remDir = "$sh\$comp"
            $js | Set-Content -Path "$remDir\today.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
            $json | Set-Content -Path "$remDir\today.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
            $js | Set-Content -Path "$remDir\activity_$date.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        }
        return $obj
    } catch {
        return $null
    }
}

function Append-Log($s, $e, $d, $p, $t, $st) {
    if ($d -le 0) { return }
    $date = (Get-Date).ToString("yyyy-MM-dd")
    $csv = "activity_$date.csv"
    $loc = "$localLogs\$csv"
    if (-not (Test-Path $loc)) {
        "StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State" | Out-File -FilePath $loc -Encoding utf8
    }
    $esc = $t -replace '"', '""'
    $line = "$s,$e,$d,$comp,$user,$p,`"$esc`",$st"
    $line | Out-File -FilePath $loc -Encoding utf8 -Append

    $sh = Get-ActiveRemoteShare
    if ($sh -ne "") {
        try {
            $rem = "$sh\$comp\$csv"
            if (-not (Test-Path $rem)) {
                "StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State" | Out-File -FilePath $rem -Encoding utf8
            }
            $line | Out-File -FilePath $rem -Encoding utf8 -Append
        } catch {}
    }

    $null = Update-DayJs $date
}

function Write-Pulse($p, $t, $st, $d, $idle) {
    $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $hb = [PSCustomObject]@{
        timestamp = $now
        computer = $comp; user = $user; process = $p; window = $t
        version = $MonitorVersion
        state = $st; duration_sec = $d; idle_sec = $idle
    }
    $j = $hb | ConvertTo-Json -Compress
    $js = "window.updateHostStatus && window.updateHostStatus('$comp', $j);"

    # Local write
    $j | Set-Content -Path "$localData\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
    $js | Set-Content -Path "$localData\current_status.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
    $j | Set-Content -Path "$localLogs\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
    $js | Set-Content -Path "$localLogs\current_status.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue

    # SMB share write
    $sh = Get-ActiveRemoteShare
    if ($sh -ne "") {
        try {
            $remDir = "$sh\$comp"
            $j | Set-Content -Path "$remDir\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
            $js | Set-Content -Path "$remDir\current_status.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        } catch {}
    }

    return $hb
}

$lastP = ""; $lastT = ""; $lastSt = "ACTIVE"
$startT = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); $dur = 0
$cloudTimer = 0

while ($true) {
    try {
        $idleSec = [math]::Floor([Win32x86]::GetIdleMillis() / 1000)
        $curSt = if ($idleSec -ge $IdleThresholdSec) { "IDLE" } else { "ACTIVE" }

        $hWnd = [Win32x86]::GetForegroundWindow()
        $pName = "Unknown"; $wTitle = ""

        if ($hWnd -ne [IntPtr]::Zero) {
            $sb = New-Object System.Text.StringBuilder 512
            [void][Win32x86]::GetWindowText($hWnd, $sb, $sb.Capacity)
            $wTitle = $sb.ToString().Trim()

            [uint32]$procId = 0
            [void][Win32x86]::GetWindowThreadProcessId($hWnd, [ref]$procId)
            if ($procId -gt 0) {
                $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($p) {
                    $pName = $p.ProcessName
                    if ($pName -eq "cmd" -or $pName -eq "cmd.exe" -or $pName -like "*stereo*") {
                        if ($wTitle -match "(?i)stereo\s*(\d+)") {
                            $pName = "cmd-Stereo$($Matches[1])"
                        } elseif ($wTitle -match "(?i)ježek|stereo") {
                            $pName = "cmd-Stereo"
                        }
                    }
                }
            }
        }

        $recP = if ($curSt -eq "IDLE") { "IDLE_PAUSE" } else { $pName }
        $recT = if ($curSt -eq "IDLE") { "" } else { $wTitle }

        $stateChanged = ($curSt -ne $lastSt)
        if (($recP -ne $lastP) -or ($recT -ne $lastT) -or $stateChanged) {
            if ($lastP -ne "") {
                $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Append-Log $startT $now $dur $lastP $lastT $lastSt
                $startT = $now; $dur = 0
            }
        }

        $lastP = $recP; $lastT = $recT; $lastSt = $curSt; $dur += $PollIntervalSec
        $pulseP = if ($curSt -eq "IDLE") { "" } else { $pName }
        $pulseT = if ($curSt -eq "IDLE") { "" } else { $wTitle }
        $hbObj = Write-Pulse $pulseP $pulseT $curSt $dur $idleSec

        $cloudTimer += $PollIntervalSec
        if ($cloudTimer -ge $CloudPushIntervalSec -or $stateChanged) {
            $curDate = (Get-Date).ToString("yyyy-MM-dd")
            $tdObj = Update-DayJs $curDate
            Push-ToCloud $hbObj $tdObj
            $cloudTimer = 0
        }

    } catch {}
    Start-Sleep -Seconds $PollIntervalSec
}
'@

[System.IO.File]::WriteAllText($agentFile, $newAgent, [System.Text.Encoding]::UTF8)
Write-Host "[OK] agent.ps1 updated to v008 successfully!" -ForegroundColor Green

# 3. Start task
schtasks /run /tn "Ultarix-Monitor" 2>$null | Out-Null
Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentFile`"" -ErrorAction SilentlyContinue
Write-Host "[OK] Ultarix-Monitor v008 started and running in background!" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "Auto-closing in 3 seconds..." -ForegroundColor DarkGray
