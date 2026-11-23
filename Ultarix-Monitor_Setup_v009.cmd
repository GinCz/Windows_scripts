<# :
@echo off
setlocal DisableDelayedExpansion
title ULTARIX - Client Monitor Setup v009 [VladiMIR + Antigravity]

:: Enable UNC support
reg add "HKCU\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t REG_DWORD /d 1 /f >nul 2>&1

:: 1. Resilient Elevation Check
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_INSTALLER

if not defined ULTARIX_ELEVATED (
    set ULTARIX_ELEVATED=1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

:RUN_INSTALLER
set "SCRIPT_FILE=%~f0"
set "PS_EXE=powershell.exe"
if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$f = $env:SCRIPT_FILE; if (-not $f) { $f = '%~f0' }; $raw = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8); try { & ([ScriptBlock]::Create($raw)) } catch { try { [Console]::WriteLine('`n[X] CHYBA INSTALACE: ' + $_.Exception.Message) } catch { Write-Output $_.Exception.Message } }"

timeout /t 2 >nul 2>&1
exit /b 0
#>
# ==============================================================================
# ULTARIX s.r.o. - Client Activity Monitor Agent (Win10 x86 / x64)
# Author  : VladiMIR + Antigravity AI
# Version : v009 (v2.6.4 - 2026-11)
# Target  : All employee workstations (32-bit & 64-bit Windows)
# Format  : U-002, U-003, ..., U-010, U-507, ULPS1 (Zero Duplicates)
# Cloud   : https://ultarix.gincz.com/ (Direct Push every 10s)
# Network : \\ulps1\UTIL\UltarixMonitor\logs (Local office backup)
# ==============================================================================

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

function Write-SafeHost {
    param(
        [string]$Text = "",
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    try {
        Write-Host $Text -ForegroundColor $Color
    } catch {
        try {
            [Console]::ForegroundColor = $Color
            [Console]::WriteLine($Text)
            [Console]::ResetColor()
        } catch {
            Write-Output $Text
        }
    }
}

try { Clear-Host } catch {}
try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288 } catch { try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {} }
$canonName = Get-CanonicalName $env:COMPUTERNAME
try { $Host.UI.RawUI.WindowTitle = "ULTARIX - Instalace agenta monitoringu [$canonName]" } catch {}

Write-SafeHost "======================================================================" Cyan
Write-SafeHost "   ULTARIX s.r.o. - Instalace ticheho agenta monitoringu (Win10/Win11) " Green
Write-SafeHost "======================================================================" Cyan
Write-SafeHost " Pocitac: $canonName (raw: $env:COMPUTERNAME) | Uzivatel: $env:USERNAME" White
Write-SafeHost " Cloud:   https://ultarix.gincz.com/" White
Write-SafeHost "======================================================================" Cyan
Write-SafeHost "" White

$localDir = "$env:ProgramData\Ultarix-Monitor"
$localLogDir = "$localDir\logs\$canonName"

if (-not (Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir -Force | Out-Null
}
if (-not (Test-Path $localLogDir)) {
    New-Item -ItemType Directory -Path $localLogDir -Force | Out-Null
}
Write-SafeHost "[OK] Mistni slozka: $localDir pripravena." Green

# Check server share targets
$targetShares = @("\\ulps1\UTIL\UltarixMonitor\logs", "\\ulps1\UTIL\Ultarix-Monitor\logs")
$activeShare = ""
foreach ($sh in $targetShares) {
    if (Test-Path $sh -ErrorAction SilentlyContinue) {
        $activeShare = $sh
        break
    }
}
if ($activeShare -ne "") {
    Write-SafeHost "[OK] Nalezena lokalni sitova slozka: $activeShare" Green
    try {
        $hf = "$activeShare\active_hosts.txt"
        $ex = if (Test-Path $hf) { Get-Content $hf -ErrorAction SilentlyContinue } else { @() }
        if ($ex -notcontains $canonName) {
            $canonName | Out-File -FilePath $hf -Encoding utf8 -Append
        }
    } catch {}
} else {
    Write-SafeHost "[i] Sitova slozka \\ulps1 neni dostupna (prace z domova/offline) - telemetrie jde primo do cloudu!" Yellow
}

$agentScriptPath = "$localDir\agent.ps1"

# Generate agent.ps1
$agentCode = @'
﻿# ==============================================================================
# ULTARIX s.r.o. - Background Activity Collector Daemon
# Runs silently 24/7 without windows or tray icons
# Version: v009 (Mon_v009)
# ==============================================================================
try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288 } catch { try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {} }

$PollIntervalSec = 5
$IdleThresholdSec = 30
$CloudPushIntervalSec = 10
$MonitorVersion = "Mon_v009"
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
            $sTime = $parts[0].Trim()
            $eTime = $parts[1].Trim()
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

            $rec = @{ sTime = $sTime; eTime = $eTime; dur = $dur; proc = $proc; win = $win; st = $st }
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
        $timelineList = @()

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
                $sTime = $rec.sTime
                $eTime = $rec.eTime

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

                    # Timeline work item (coalesce adjacent same item)
                    if ($timelineList.Count -gt 0 -and $timelineList[-1].type -eq "work" -and $timelineList[-1].name -eq $disp -and $timelineList[-1].title -eq $win) {
                        $timelineList[-1].durationSec += $dur
                        $timelineList[-1].endTime = $eTime
                    } else {
                        $timelineList += [PSCustomObject]@{
                            type = "work"
                            name = $disp
                            title = $win
                            icon = $icon
                            color = $color
                            startTime = $sTime
                            endTime = $eTime
                            durationSec = $dur
                        }
                    }
                } elseif ($st -eq "IDLE" -or $proc -eq "IDLE_PAUSE") {
                    # Internal pause between active work sessions
                    # Vladimir's Rule: A single pause between work sessions cannot be an overnight/long gap (> 2 hours = 7200s)!
                    if ($dur -le 7200) {
                        $idleSec += $dur
                        $totSec += $dur

                        # Timeline idle item (coalesce adjacent idle)
                        if ($timelineList.Count -gt 0 -and $timelineList[-1].type -eq "idle") {
                            $timelineList[-1].durationSec += $dur
                            $timelineList[-1].endTime = $eTime
                        } else {
                            $timelineList += [PSCustomObject]@{
                                type = "idle"
                                name = "Отдых"
                                title = ""
                                icon = "☕"
                                color = "yellow"
                                startTime = $sTime
                                endTime = $eTime
                                durationSec = $dur
                            }
                        }
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
            timeline = @($timelineList)
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

Set-Content -Path $agentScriptPath -Value $agentCode -Encoding utf8 -Force
Write-SafeHost "[OK] Skript agenta vytvoren v $agentScriptPath" Green

# Terminate previous instances and register Scheduled Task
Write-SafeHost "[*] Ukoncuji predchozi instance agenta..." Yellow
schtasks /end /tn "Ultarix-Monitor" 2>$null | Out-Null
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*agent.ps1*" -and $_.ProcessId -ne $PID
} | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}
Start-Sleep -Milliseconds 500

Write-SafeHost "[*] Registruji automaticky start agenta v Planovaci uloh..." Yellow
schtasks /delete /tn "Ultarix-Monitor" /f 2>$null | Out-Null
$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScriptPath`""
schtasks /create /tn "Ultarix-Monitor" /tr "$taskCmd" /sc ONLOGON /rl HIGHEST /f 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    schtasks /create /tn "Ultarix-Monitor" /tr "$taskCmd" /sc ONLOGON /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /f 2>$null | Out-Null
}

# Backup in registry Run
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Ultarix-Monitor" -Value "$taskCmd" -ErrorAction SilentlyContinue

# Start task immediately
schtasks /run /tn "Ultarix-Monitor" 2>$null | Out-Null
Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScriptPath`"" -ErrorAction SilentlyContinue
Write-SafeHost "    [OK] Uloha Planovace 'Ultarix-Monitor' uspesne vytvorena a SPUSTENA!" Green

# Initial Pulse & Direct Push
try {
    $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $firstHb = [PSCustomObject]@{
        timestamp = $now
        computer = $canonName
        version = "Mon_v009"
        user = $env:USERNAME
        process = "explorer"
        window = "Plocha Windows"
        state = "ACTIVE"
        duration_sec = 10
        idle_sec = 0
    }
    $firstPayload = [PSCustomObject]@{
        computer = $canonName
        version = "Mon_v009"
        current_status = $firstHb
        today = $null
    }
    $firstJson = $firstPayload | ConvertTo-Json -Depth 4 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($firstJson)
    $req = [System.Net.HttpWebRequest]::Create("https://ultarix.gincz.com/api/push")
    $req.Method = "POST"
    $req.ContentType = "application/json; charset=utf-8"
    $req.Headers.Add("Authorization", "Bearer Ultarix-Monitor-2026")
    $req.Timeout = 4000
    $st = $req.GetRequestStream()
    $st.Write($bytes, 0, $bytes.Length)
    $st.Close()
    $resp = $req.GetResponse()
    $resp.Close()
    Write-SafeHost "    [OK] Prvni telemetrie uspesne odeslana do cloudu https://ultarix.gincz.com/!" Green
} catch {
    Write-SafeHost "    [!] Prvni odeslani do cloudu selhalo: $($_.Exception.Message)" Yellow
}

Write-SafeHost "" White
Write-SafeHost "======================================================================" Green
Write-SafeHost "     INSTALACE BYLA USPESNE DOKONCENA NA POCITACI $canonName!  " Green
Write-SafeHost "======================================================================" Green
Write-SafeHost " [V] ZELENA TECKA (Online) je nyni aktivni na https://ultarix.gincz.com/" Green
Write-SafeHost " [V] Agent bezi zcela skryte bez oken, bez ikon a bez ruseni uzivatele." White
Write-SafeHost " [V] Automaticky startuje pri zapnuti pocitace i po restartu." White
Write-SafeHost "======================================================================" Green
Write-SafeHost "" White
Write-SafeHost " Okno se automaticky zavre za 2 sekundy..." Yellow
Start-Sleep -Seconds 2
