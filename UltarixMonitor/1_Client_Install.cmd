<# :
@echo off
setlocal DisableDelayedExpansion
title ULTARIX - Client Monitor Setup (Win10 32-bit) [VladiMIR + Antigravity]

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
# ULTARIX s.r.o. - Client Activity Monitor Agent (32-bit Windows 10 x86)
# Author  : VladiMIR + Antigravity AI
# Version : v2.4.4 (2026-11)
# Target  : All employee workstations (32-bit Windows 10 Pro)
# Network : \\ulps1\UTIL\UltarixMonitor\logs
# ==============================================================================

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
try { $Host.UI.RawUI.WindowTitle = "ULTARIX - Instalace agenta monitoringu [$env:COMPUTERNAME]" } catch {}

Write-SafeHost "======================================================================" Cyan
Write-SafeHost "   ULTARIX s.r.o. - Instalace ticheho agenta monitoringu (Win10 x86)  " Green
Write-SafeHost "======================================================================" Cyan
Write-SafeHost " Pocitac: $env:COMPUTERNAME | Uzivatel: $env:USERNAME | Arch: $env:PROCESSOR_ARCHITECTURE" White
Write-SafeHost "======================================================================" Cyan
Write-SafeHost "" White

$targetShare = "\\ulps1\UTIL\UltarixMonitor\logs"
$localDir = "$env:ProgramData\UltarixMonitor"
$localLogDir = "$localDir\logs\$env:COMPUTERNAME"

# 1. Check local directory
if (-not (Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir -Force | Out-Null
}
if (-not (Test-Path $localLogDir)) {
    New-Item -ItemType Directory -Path $localLogDir -Force | Out-Null
}
Write-SafeHost "[OK] Mistni slozka: $localDir pripravena." Green

# 2. Check network server reachability
Write-SafeHost "[*] Kontrola dostupnosti serveru $targetShare..." Yellow
$remoteCompLog = "$targetShare\$env:COMPUTERNAME"
$serverOk = $false
try {
    if (-not (Test-Path $targetShare)) {
        New-Item -ItemType Directory -Path $targetShare -Force -ErrorAction Stop | Out-Null
    }
    if (-not (Test-Path $remoteCompLog)) {
        New-Item -ItemType Directory -Path $remoteCompLog -Force -ErrorAction Stop | Out-Null
    }
    # Test write
    $testFile = "$remoteCompLog\check_connection.tmp"
    Set-Content -Path $testFile -Value "OK" -Force -ErrorAction Stop
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    $serverOk = $true
    Write-SafeHost "    [OK] Spojeni se serverem ULPS1 funguje perfektne!" Green
    Write-SafeHost "    [OK] Cesta pro logy: $remoteCompLog" Green
    # Auto-register this computer in network active_hosts index
    try {
        $hf = "$targetShare\active_hosts.txt"
        $ex = if (Test-Path $hf) { Get-Content $hf -ErrorAction SilentlyContinue } else { @() }
        if ($ex -notcontains $env:COMPUTERNAME) {
            $env:COMPUTERNAME | Out-File -FilePath $hf -Encoding utf8 -Append
        }
    } catch {}
} catch {
    Write-SafeHost "    [!] Varovani: Sitova slozka $targetShare nyni neodpovida." DarkYellow
    Write-SafeHost "        Agent bude logovat lokalne a synchronizovat se pri pripojeni." Gray
}

# 3. Create background agent script
$agentScriptPath = "$localDir\agent.ps1"

$agentCode = @'
# Ultarix Background Activity Collector Agent (x86 32-bit Win10)
param(
    [int]$PollIntervalSec = 5,
    [int]$IdleThresholdSec = 60,
    [string]$ServerShare = "\\ulps1\UTIL\UltarixMonitor\logs"
)

# Terminate duplicate agent instances to guarantee strictly 1 active process
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*agent.ps1*" -and $_.ProcessId -ne $PID
} | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}

# Ensure clean single process execution
# (Process check above already terminated previous instances safely)

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
if (-not ([System.Management.Automation.PSTypeName]'Win32x86').Type) {
    Add-Type -TypeDefinition $win32 -ErrorAction SilentlyContinue
}

$comp = $env:COMPUTERNAME
$user = $env:USERNAME
$localData = "$env:ProgramData\UltarixMonitor"
$localLogs = "$localData\logs\$comp"
$remoteLogs = "$ServerShare\$comp"
$null = New-Item -ItemType Directory -Path $localLogs -Force -ErrorAction SilentlyContinue

# Auto-register this computer in network hosts index
if (Test-Path $ServerShare -ErrorAction SilentlyContinue) {
    try {
        $hf = "$ServerShare\active_hosts.txt"
        $ex = if (Test-Path $hf) { Get-Content $hf -ErrorAction SilentlyContinue } else { @() }
        if ($ex -notcontains $comp) {
            $comp | Out-File -FilePath $hf -Encoding utf8 -Append
        }
    } catch {}
}


function Update-DayJs($date) {
    try {
        $csv = "$localLogs\activity_$date.csv"
        if (-not (Test-Path $csv)) { return }
        $lines = Get-Content $csv -Encoding utf8 -ErrorAction SilentlyContinue
        if ($null -eq $lines -or $lines.Count -le 1) { return }

        $appMap = @{}
        $totSec = 0
        $idleSec = 0

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
                $win = ($winParts -join ",") -replace '^"|"$', '' -replace '""', '"'
                $st = $parts[$parts.Count - 1].Trim()
            } else {
                $win = $parts[6].Trim() -replace '^"|"$', '' -replace '""', '"'
                $st = "ACTIVE"
            }

            $totSec += $dur
            if ($st -eq "IDLE" -or $proc -eq "IDLE_PAUSE") {
                $idleSec += $dur
            }

            if (-not $appMap.ContainsKey($proc)) {
                $icon = "📱"; $color = "blue"; $disp = $proc
                $pLower = $proc.ToLower()
                if ($pLower -like "*stereo*") { $icon = "🦔"; $color = "orange"; $disp = "$proc (STEREO — Ježek)" }
                elseif ($pLower -like "*ekonom*") { $icon = "💼"; $color = "blue"; $disp = "$proc (Ekonom.win)" }
                elseif ($pLower -like "*chrome*") { $icon = "🌐"; $color = "purple"; $disp = "$proc (Google Chrome)" }
                elseif ($pLower -like "*firefox*") { $icon = "🦊"; $color = "orange"; $disp = "$proc (Mozilla Firefox)" }
                elseif ($pLower -like "*edge*") { $icon = "🌀"; $color = "blue"; $disp = "$proc (Microsoft Edge)" }
                elseif ($pLower -like "*excel*") { $icon = "📊"; $color = "green"; $disp = "$proc (Microsoft Excel)" }
                elseif ($pLower -like "*word*") { $icon = "📝"; $color = "blue"; $disp = "$proc (Microsoft Word)" }
                elseif ($pLower -like "*idle*") { $icon = "⏸"; $color = "yellow"; $disp = "IDLE_PAUSE (Паузы / AFK)" }

                $appMap[$proc] = @{
                    name = $disp
                    icon = $icon
                    color = $color
                    durationSec = 0
                    pages = @{}
                }
            }

            $appMap[$proc].durationSec += $dur
            $wKey = if ($win) { $win } else { "Hlavní okno programu" }
            if (-not $appMap[$proc].pages.ContainsKey($wKey)) {
                $appMap[$proc].pages[$wKey] = 0
            }
            $appMap[$proc].pages[$wKey] += $dur
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
        $js | Set-Content -Path "$localLogs\activity_$date.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue

        if (Test-Path $remoteLogs -ErrorAction SilentlyContinue) {
            $js | Set-Content -Path "$remoteLogs\today.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
            $js | Set-Content -Path "$remoteLogs\activity_$date.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        }
    } catch {}
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

    if (Test-Path $remoteLogs -ErrorAction SilentlyContinue) {
        try {
            $rem = "$remoteLogs\$csv"
            if (-not (Test-Path $rem)) {
                "StartTime,EndTime,DurationSec,ComputerName,UserName,ProcessName,WindowTitle,State" | Out-File -FilePath $rem -Encoding utf8
            }
            $line | Out-File -FilePath $rem -Encoding utf8 -Append
        } catch {}
    }

    Update-DayJs $date
}

function Write-Pulse($p, $t, $st, $d, $idle) {
    $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $hb = [PSCustomObject]@{
        timestamp = $now
        computer = $comp; user = $user; process = $p; window = $t
        state = $st; duration_sec = $d; idle_sec = $idle
    }
    $j = $hb | ConvertTo-Json -Compress
    $js = "window.updateHostStatus && window.updateHostStatus('$comp', $j);"

    # Write both JSON and JS locally
    $j | Set-Content -Path "$localData\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
    $js | Set-Content -Path "$localData\current_status.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue

    # Write both JSON and JS to remote server share (for browser file:// CORS bypass)
    if (Test-Path $remoteLogs -ErrorAction SilentlyContinue) {
        try {
            $j | Set-Content -Path "$remoteLogs\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
            $js | Set-Content -Path "$remoteLogs\current_status.js" -Encoding utf8 -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

$lastP = ""; $lastT = ""; $lastSt = "ACTIVE"
$startT = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); $dur = 0

while ($true) {
    try {
        if (-not (Test-Path $remoteLogs -ErrorAction SilentlyContinue)) {
            $null = New-Item -ItemType Directory -Path $remoteLogs -Force -ErrorAction SilentlyContinue
        }
        $idleSec = [math]::Floor([Win32x86]::GetIdleMillis() / 1000)
        $curSt = if ($idleSec -ge $IdleThresholdSec) { "IDLE" } else { "ACTIVE" }

        $hWnd = [Win32x86]::GetForegroundWindow()
        $pName = "Unknown"; $wTitle = ""

        if ($hWnd -ne [IntPtr]::Zero) {
            $sb = New-Object System.Text.StringBuilder 512
            [void][Win32x86]::GetWindowText($hWnd, $sb, $sb.Capacity)
            $wTitle = $sb.ToString().Trim()

            $pid = 0
            [void][Win32x86]::GetWindowThreadProcessId($hWnd, [ref]$pid)
            if ($pid -gt 0) {
                $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($p) { $pName = $p.ProcessName }
            }
        }

        if ($curSt -eq "IDLE") {
            $wTitle = "[Pauza / Neaktivita - $idleSec sec]"
            $pName = "IDLE_PAUSE"
        }

        if (($pName -ne $lastP) -or ($wTitle -ne $lastT) -or ($curSt -ne $lastSt)) {
            if ($lastP -ne "") {
                $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Append-Log $startT $now $dur $lastP $lastT $lastSt
                $startT = $now; $dur = 0
            }
        }

        $lastP = $pName; $lastT = $wTitle; $lastSt = $curSt; $dur += $PollIntervalSec
        Write-Pulse $pName $wTitle $curSt $dur $idleSec

        if ($dur % 15 -eq 0) {
            $curDate = (Get-Date).ToString("yyyy-MM-dd")
            Update-DayJs $curDate
        }

    } catch {}
    Start-Sleep -Seconds $PollIntervalSec
}
'@

Set-Content -Path $agentScriptPath -Value $agentCode -Encoding utf8 -Force
Write-SafeHost "[OK] Skript agenta vytvoren v $agentScriptPath" Green

# 4. Terminate previous instances and Register Windows Scheduled Task
Write-SafeHost "[*] Ukoncuji pripadne predchozi instance agenta..." Yellow
schtasks /end /tn "UltarixMonitor" 2>$null | Out-Null
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*agent.ps1*" -and $_.ProcessId -ne $PID
} | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}
Start-Sleep -Milliseconds 500

Write-SafeHost "[*] Registruji automaticky start agenta v Planovaci uloh..." Yellow
schtasks /delete /tn "UltarixMonitor" /f 2>$null | Out-Null
$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScriptPath`""
schtasks /create /tn "UltarixMonitor" /tr "$taskCmd" /sc ONLOGON /rl HIGHEST /f | Out-Null

# 5. Backup in registry Run
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "UltarixMonitor" -Value "$taskCmd" -ErrorAction SilentlyContinue

# 6. Start task immediately
schtasks /run /tn "UltarixMonitor" | Out-Null

Write-SafeHost "    [OK] Uloha Planovace 'UltarixMonitor' uspesne vytvorena a SPUSTENA!" Green

# 7. Initial Pulse verification
Start-Sleep -Seconds 2
if (Test-Path "$localDir\current_status.json") {
    $hb = Get-Content "$localDir\current_status.json" -Raw -Encoding utf8 | ConvertFrom-Json
    Write-SafeHost "" White
    Write-SafeHost "=============== AKTIVITA ZACHYCENA V REALNEM CASE ===============" Cyan
    Write-SafeHost " Aktualni proces : $($hb.process)" White
    Write-SafeHost " Titulek okna    : $($hb.window)" White
    Write-SafeHost " Stav aktivity   : $($hb.state)" Green
    Write-SafeHost "==================================================================" Cyan
}

Write-SafeHost "" White
Write-SafeHost "======================================================================" Green
Write-SafeHost "     INSTALACE BYLA USPESNE DOKONCENA NA POCITACI $env:COMPUTERNAME!  " Green
Write-SafeHost "======================================================================" Green
Write-SafeHost " Agent nyni nepretrzite a tise bezi v pozadi Windows 10 (32-bit)." White
Write-SafeHost " Logy a pauzy se automaticky ukladaji na server: $targetShare" White
Write-SafeHost "======================================================================" Green
Write-SafeHost "" White
Write-SafeHost " Agent bezi zcela skryte bez oken, bez ikon a bez ruseni uzivatele." White
Write-SafeHost " Automaticky startuje pri zapnuti pocitace i po restartu." White
Write-SafeHost "======================================================================" Green
Write-SafeHost "" White
Write-SafeHost " Okno se automaticky zavre za 2 sekundy..." Yellow
Start-Sleep -Seconds 2
