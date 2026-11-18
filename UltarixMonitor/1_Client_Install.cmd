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

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$raw = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); try { & ([ScriptBlock]::Create($raw)) } catch { Write-Host ('`n[X] CHYBA INSTALACE: ' + $_.Exception.ToString()) -ForegroundColor Red; Write-Host '`nStisknete libovolnou klavesu pro ukonceni...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }"

echo.
pause
exit /b
#>
# ==============================================================================
# ULTARIX s.r.o. - Client Activity Monitor Agent (32-bit Windows 10 x86)
# Author  : VladiMIR + Antigravity AI
# Version : v2.2.0 (2026-11)
# Target  : PC-09 and all employee workstations (32-bit Windows 10)
# Network : \\ulps1\UTIL\UltarixMonitor\logs
# ==============================================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "ULTARIX - Instalace agenta monitoringu [PC-09]"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "      ULTARIX s.r.o. - Instalace ticheho agenta monitoringu (Win10 32-bit)      " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Pocitac: $env:COMPUTERNAME | Uživatel: $env:USERNAME | Architektura: $env:PROCESSOR_ARCHITECTURE" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

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
Write-Host "[OK] Mistni slozka: $localDir pripravena." -ForegroundColor Green

# 2. Check network server reachability
Write-Host "[*] Kontrola dostupnosti serveru $targetShare..." -ForegroundColor Yellow
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
    Write-Host "    [OK] Spojeni se serverem ULPS1 funguje perfektne!" -ForegroundColor Green
    Write-Host "    [OK] Cesta pro logy: $remoteCompLog" -ForegroundColor Green
} catch {
    Write-Host "    [!] Varovani: Sitova slozka $targetShare nyni neodpovida." -ForegroundColor DarkYellow
    Write-Host "        Agent bude logovat lokalne a synchronizovat se pri pripojeni k serveru." -ForegroundColor Gray
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
Add-Type -TypeDefinition $win32 -ErrorAction SilentlyContinue

$comp = $env:COMPUTERNAME
$user = $env:USERNAME
$localData = "$env:ProgramData\UltarixMonitor"
$localLogs = "$localData\logs\$comp"
$remoteLogs = "$ServerShare\$comp"
$null = New-Item -ItemType Directory -Path $localLogs -Force -ErrorAction SilentlyContinue

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
}

function Write-Pulse($p, $t, $st, $d, $idle) {
    $hb = [PSCustomObject]@{
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        computer = $comp; user = $user; process = $p; window = $t
        state = $st; duration_sec = $d; idle_sec = $idle
    }
    $j = $hb | ConvertTo-Json -Compress
    $j | Set-Content -Path "$localData\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue
    if (Test-Path $remoteLogs -ErrorAction SilentlyContinue) {
        try { $j | Set-Content -Path "$remoteLogs\current_status.json" -Encoding utf8 -Force -ErrorAction SilentlyContinue } catch {}
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
            $wTitle = "[Пауза / Бездействие - $idleSec сек]"
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

    } catch {}
    Start-Sleep -Seconds $PollIntervalSec
}
'@

Set-Content -Path $agentScriptPath -Value $agentCode -Encoding utf8 -Force
Write-Host "[OK] Skript agenta vytvoren v $agentScriptPath" -ForegroundColor Green

# 4. Register Windows Scheduled Task
Write-Host "[*] Registruji automaticky start agenta v Planovaci uloh..." -ForegroundColor Yellow
schtasks /delete /tn "UltarixMonitor" /f 2>$null | Out-Null
$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$agentScriptPath`""
schtasks /create /tn "UltarixMonitor" /tr "$taskCmd" /sc ONLOGON /rl HIGHEST /f | Out-Null

# 5. Backup in registry Run
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "UltarixMonitor" -Value "$taskCmd" -ErrorAction SilentlyContinue

# 6. Start task immediately
schtasks /run /tn "UltarixMonitor" | Out-Null

Write-Host "    [OK] Uloha Planovace 'UltarixMonitor' uspesne vytvorena a SPUSTENA!" -ForegroundColor Green

# 7. Initial Pulse verification
Start-Sleep -Seconds 2
if (Test-Path "$localDir\current_status.json") {
    $hb = Get-Content "$localDir\current_status.json" -Raw -Encoding utf8 | ConvertFrom-Json
    Write-Host ""
    Write-Host "================ AKTIVITA ZACHYCENA V REÁLNÉM ČASE ================" -ForegroundColor Cyan
    Write-Host " Aktualni proces : $($hb.process)" -ForegroundColor White
    Write-Host " Titulek okna    : $($hb.window)" -ForegroundColor White
    Write-Host " Stav aktivity   : $($hb.state)" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "       INSTALACE BYLA USPESNE DOKONCENA NA POCITACI $env:COMPUTERNAME!         " -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host " Agent nyni nepretrzite a tise bezi v pozadi Windows 10 (32-bit)." -ForegroundColor White
Write-Host " Logy a pauzy se automaticky ukladaji na server: $targetShare" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Stisknete libovolnou klavesu pro zavreni..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
